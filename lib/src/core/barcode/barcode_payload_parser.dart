import 'package:bs_mobile/src/core/barcode/barcode_format_model.dart';
import 'package:bs_mobile/src/core/barcode/barcode_typed_value.dart';
import 'package:intl/intl.dart';

/// Strict 2D barcode payload parser. Keys are exact `tag_name` after trim.
abstract final class BarcodePayloadParser {
  static BarcodeParseResult parse({
    required String raw,
    required BarcodeFormatConfig config,
  }) {
    final separator = config.separator;
    if (!raw.contains(separator)) {
      return const BarcodeParseFailure(
        errorCode: 'missing_separator',
        message: 'raw payload has no separator for 2D parse',
      );
    }

    final parts = raw.split(separator);
    final fields = config.fields;

    final sequences = <int>{};
    var maxSequence = 0;
    for (final field in fields) {
      if (field.tagSequence < 1) {
        return BarcodeParseFailure(
          errorCode: 'invalid_tag_sequence',
          message: 'tag_sequence must be >= 1',
          tagName: field.tagName,
        );
      }
      if (!sequences.add(field.tagSequence)) {
        return BarcodeParseFailure(
          errorCode: 'duplicate_tag_sequence',
          message: 'duplicate tag_sequence ${field.tagSequence}',
          tagName: field.tagName,
        );
      }
      if (field.tagSequence > maxSequence) {
        maxSequence = field.tagSequence;
      }
    }

    if (maxSequence > parts.length) {
      return BarcodeParseFailure(
        errorCode: 'payload_too_short',
        message:
            'max tag_sequence $maxSequence exceeds parts length ${parts.length}',
      );
    }

    final values = <String, BarcodeTypedValue>{};

    for (final field in fields) {
      final tagName = field.tagName.trim();
      final part = parts[field.tagSequence - 1].trim();

      if (part.isEmpty) {
        if (field.required) {
          return BarcodeParseFailure(
            errorCode: 'required_empty',
            message: 'required field is empty',
            tagName: tagName,
          );
        }
        continue;
      }

      final typed = _parseTyped(field: field, tagName: tagName, raw: part);
      if (typed == null) {
        return BarcodeParseFailure(
          errorCode: 'type_parse_failed',
          message: 'failed to parse $tagName as ${field.dataType?.name}',
          tagName: tagName,
        );
      }
      values[tagName] = typed;
    }

    return BarcodeParseSuccess(values);
  }

  static BarcodeTypedValue? _parseTyped({
    required BarcodeFormatField field,
    required String tagName,
    required String raw,
  }) {
    switch (field.dataType) {
      case BarcodeDataType.string:
        return BarcodeTypedValue.string(tagName: tagName, raw: raw);
      case BarcodeDataType.number:
        final number = num.tryParse(raw);
        if (number == null) return null;
        return BarcodeTypedValue.number(
          tagName: tagName,
          raw: raw,
          numberValue: number,
        );
      case BarcodeDataType.date:
        final format = field.format?.trim();
        if (format == null || format.isEmpty) return null;
        try {
          final date = DateFormat(format).parseStrict(raw);
          return BarcodeTypedValue.date(
            tagName: tagName,
            raw: raw,
            dateValue: DateTime(date.year, date.month, date.day),
          );
        } catch (_) {
          return null;
        }
      case null:
        return null;
    }
  }
}
