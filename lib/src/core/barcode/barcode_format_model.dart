import 'package:bs_mobile/src/core/helpers/parse.dart';

enum BarcodeDataType { string, date, number }

BarcodeDataType? barcodeDataTypeFromString(String? raw) {
  final trimmed = raw?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;

  return switch (trimmed) {
    'string' => BarcodeDataType.string,
    'date' => BarcodeDataType.date,
    'number' => BarcodeDataType.number,
    _ => null,
  };
}

/// Field DTO — matches BE field row (`tag_function` is per field).
class BarcodeFormatField {
  const BarcodeFormatField({
    required this.tagSequence,
    required this.tagName,
    required this.dataType,
    required this.required,
    this.format,
    this.rawDataType,
    this.tagFunction,
  });

  final int tagSequence;
  final String tagName;

  /// Null when BE sent an unsupported `data_type`.
  final BarcodeDataType? dataType;
  final bool required;
  final String? format;
  final String? rawDataType;

  /// Present on API rows; optional on slim/runtime fields after grouping.
  final String? tagFunction;

  factory BarcodeFormatField.fromJson(Map<String, dynamic> json) {
    final tagName = (Parse.parseString(json['tag_name']) ?? '').trim();
    final rawDataType = Parse.parseString(json['data_type'])?.trim();

    return BarcodeFormatField(
      tagSequence: Parse.parseInt(json['tag_sequence']) ?? 0,
      tagName: tagName,
      dataType: barcodeDataTypeFromString(rawDataType),
      required: Parse.parseBool(json['required']) ?? false,
      format: Parse.parseString(json['format'])?.trim(),
      rawDataType: rawDataType,
      tagFunction: Parse.parseString(json['tag_function'])?.trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'tag_sequence': tagSequence,
    'tag_name': tagName,
    'data_type': rawDataType ?? dataType?.name ?? 'string',
    'required': required ? 'YES' : 'NO',
    'format': format,
    if (tagFunction != null && tagFunction!.isNotEmpty)
      'tag_function': tagFunction,
  };
}

/// API envelope — real GetBarcodeFormat payload (flat `fields`, shared `separator`).
class BarcodeFormatResponse {
  const BarcodeFormatResponse({
    required this.messageCode,
    required this.isSuccess,
    required this.separator,
    required this.fields,
    this.message,
    this.totalPages,
    this.totalRecords,
  });

  final String messageCode;
  final bool isSuccess;
  final String? message;
  final String separator;
  final List<BarcodeFormatField> fields;
  final int? totalPages;
  final int? totalRecords;

  factory BarcodeFormatResponse.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    final fields = <BarcodeFormatField>[];
    if (rawFields is List) {
      for (final item in rawFields) {
        if (item is Map) {
          fields.add(
            BarcodeFormatField.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return BarcodeFormatResponse(
      messageCode: Parse.parseString(json['message_code']) ?? '',
      isSuccess: Parse.parseBool(json['is_success']) ?? false,
      message: Parse.parseString(json['message']),
      separator: (Parse.parseString(json['separator']) ?? '').trim(),
      fields: fields,
      totalPages: Parse.parseInt(json['total_pages']),
      totalRecords: Parse.parseInt(json['total_records']),
    );
  }

  Map<String, dynamic> toJson() => {
    'message_code': messageCode,
    'is_success': isSuccess,
    'message': message,
    'separator': separator,
    'fields': fields.map((f) => f.toJson()).toList(),
    'total_pages': totalPages,
    'total_records': totalRecords,
  };

  /// Group flat API `fields` by each row's `tag_function`.
  ///
  /// Shared root [separator] applies to every group.
  List<BarcodeFormatConfig> toConfigs({DateTime? fetchedAt}) {
    final groups = <String, List<BarcodeFormatField>>{};

    for (final field in fields) {
      final key = (field.tagFunction ?? '').trim();
      if (key.isEmpty) continue;
      groups.putIfAbsent(key, () => []).add(field);
    }

    return [
      for (final entry in groups.entries)
        BarcodeFormatConfig(
          separator: separator,
          tagFunction: entry.key,
          fields: entry.value,
          fetchedAt: fetchedAt,
          messageCode: messageCode,
          isSuccess: isSuccess,
          message: message,
          totalPages: totalPages,
          totalRecords: totalRecords,
        ),
    ];
  }
}

/// Runtime config used by parser/cache (one layout per [tagFunction]).
class BarcodeFormatConfig {
  const BarcodeFormatConfig({
    required this.separator,
    required this.tagFunction,
    required this.fields,
    this.fetchedAt,
    this.messageCode,
    this.isSuccess,
    this.message,
    this.totalPages,
    this.totalRecords,
  });

  final String separator;
  final String tagFunction;
  final List<BarcodeFormatField> fields;
  final DateTime? fetchedAt;
  final String? messageCode;
  final bool? isSuccess;
  final String? message;
  final int? totalPages;
  final int? totalRecords;

  factory BarcodeFormatConfig.fromJson(
    Map<String, dynamic> json, {
    DateTime? fetchedAt,
  }) {
    final stamped =
        fetchedAt ??
        DateTime.tryParse(Parse.parseString(json['fetched_at']) ?? '');

    // Slim / disk item: already has tag_function at root.
    final rootTag = (Parse.parseString(json['tag_function']) ?? '').trim();
    if (rootTag.isNotEmpty) {
      final rawFields = json['fields'];
      final fields = <BarcodeFormatField>[];
      if (rawFields is List) {
        for (final item in rawFields) {
          if (item is Map) {
            fields.add(
              BarcodeFormatField.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }

      return BarcodeFormatConfig(
        separator: (Parse.parseString(json['separator']) ?? '').trim(),
        tagFunction: rootTag,
        fields: fields,
        fetchedAt: stamped,
        messageCode: Parse.parseString(json['message_code']),
        isSuccess: Parse.parseBool(json['is_success']),
        message: Parse.parseString(json['message']),
        totalPages: Parse.parseInt(json['total_pages']),
        totalRecords: Parse.parseInt(json['total_records']),
      );
    }

    // Full API envelope without root tag_function — take first group if any.
    final configs = BarcodeFormatResponse.fromJson(
      json,
    ).toConfigs(fetchedAt: stamped);
    if (configs.isEmpty) {
      return BarcodeFormatConfig(
        separator: (Parse.parseString(json['separator']) ?? '').trim(),
        tagFunction: '',
        fields: const [],
        fetchedAt: stamped,
        messageCode: Parse.parseString(json['message_code']),
        isSuccess: Parse.parseBool(json['is_success']),
        message: Parse.parseString(json['message']),
        totalPages: Parse.parseInt(json['total_pages']),
        totalRecords: Parse.parseInt(json['total_records']),
      );
    }
    return configs.first;
  }

  Map<String, dynamic> toJson() => {
    'message_code': messageCode ?? '0',
    'is_success': isSuccess ?? true,
    'message': message,
    'separator': separator,
    'tag_function': tagFunction,
    'fields': fields.map((f) => f.toJson()).toList(),
    'total_pages': totalPages,
    'total_records': totalRecords,
    if (fetchedAt != null) 'fetched_at': fetchedAt!.toIso8601String(),
  };

  BarcodeFormatConfig copyWithFetchedAt(DateTime fetchedAt) {
    return BarcodeFormatConfig(
      separator: separator,
      tagFunction: tagFunction,
      fields: fields,
      fetchedAt: fetchedAt,
      messageCode: messageCode,
      isSuccess: isSuccess,
      message: message,
      totalPages: totalPages,
      totalRecords: totalRecords,
    );
  }
}

/// Disk LKG / internal bundle — list of grouped configs under `items`.
class BarcodeFormatListResponse {
  const BarcodeFormatListResponse({
    required this.messageCode,
    required this.isSuccess,
    required this.items,
    this.message,
    this.totalPages,
    this.totalRecords,
  });

  final String messageCode;
  final bool isSuccess;
  final String? message;
  final List<BarcodeFormatConfig> items;
  final int? totalPages;
  final int? totalRecords;

  factory BarcodeFormatListResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['items'] ?? json['data'] ?? json['formats'];
    final items = <BarcodeFormatConfig>[];

    if (rawList is List) {
      for (final item in rawList) {
        if (item is! Map) continue;
        items.add(
          BarcodeFormatConfig.fromJson(Map<String, dynamic>.from(item)),
        );
      }
    } else if (json.containsKey('fields') && json.containsKey('separator')) {
      // Real API shape (flat fields) → group into configs.
      items.addAll(BarcodeFormatResponse.fromJson(json).toConfigs());
    }

    return BarcodeFormatListResponse(
      messageCode: Parse.parseString(json['message_code']) ?? '',
      isSuccess: Parse.parseBool(json['is_success']) ?? false,
      message: Parse.parseString(json['message']),
      items: items,
      totalPages: Parse.parseInt(json['total_pages']),
      totalRecords: Parse.parseInt(json['total_records']),
    );
  }

  Map<String, dynamic> toJson() => {
    'message_code': messageCode,
    'is_success': isSuccess,
    'message': message,
    'items': items.map((e) => e.toJson()).toList(),
    'total_pages': totalPages,
    'total_records': totalRecords,
  };
}
