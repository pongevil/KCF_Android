/// Typed value produced by [BarcodePayloadParser] for a single `tag_name`.
class BarcodeTypedValue {
  const BarcodeTypedValue._({
    required this.tagName,
    required this.raw,
    this.stringValue,
    this.dateValue,
    this.numberValue,
  });

  factory BarcodeTypedValue.string({
    required String tagName,
    required String raw,
  }) {
    return BarcodeTypedValue._(tagName: tagName, raw: raw, stringValue: raw);
  }

  factory BarcodeTypedValue.date({
    required String tagName,
    required String raw,
    required DateTime dateValue,
  }) {
    return BarcodeTypedValue._(
      tagName: tagName,
      raw: raw,
      stringValue: raw,
      dateValue: dateValue,
    );
  }

  factory BarcodeTypedValue.number({
    required String tagName,
    required String raw,
    required num numberValue,
  }) {
    return BarcodeTypedValue._(
      tagName: tagName,
      raw: raw,
      stringValue: raw,
      numberValue: numberValue,
    );
  }

  final String tagName;
  final String raw;
  final String? stringValue;
  final DateTime? dateValue;
  final num? numberValue;

  DateTime requireDate() {
    final value = dateValue;
    if (value == null) {
      throw StateError('BarcodeTypedValue[$tagName] is not a date');
    }
    return value;
  }

  num requireNumber() {
    final value = numberValue;
    if (value == null) {
      throw StateError('BarcodeTypedValue[$tagName] is not a number');
    }
    return value;
  }
}

sealed class BarcodeParseResult {
  const BarcodeParseResult();
}

final class BarcodeParseSuccess extends BarcodeParseResult {
  const BarcodeParseSuccess(this.values);

  /// Keys are exact `tag_name` (trimmed) from BE config.
  final Map<String, BarcodeTypedValue> values;
}

final class BarcodeParseFailure extends BarcodeParseResult {
  const BarcodeParseFailure({
    required this.errorCode,
    required this.message,
    this.tagName,
  });

  final String errorCode;
  final String message;
  final String? tagName;
}
