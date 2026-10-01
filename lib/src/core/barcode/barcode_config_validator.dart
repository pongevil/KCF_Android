import 'package:bs_mobile/src/core/barcode/barcode_format_model.dart';

class BarcodeConfigValidationResult {
  const BarcodeConfigValidationResult._({
    required this.isValid,
    this.errorCode,
    this.message,
  });

  const BarcodeConfigValidationResult.ok() : this._(isValid: true);

  const BarcodeConfigValidationResult.invalid({
    required String errorCode,
    required String message,
  }) : this._(isValid: false, errorCode: errorCode, message: message);

  final bool isValid;
  final String? errorCode;
  final String? message;
}

/// Validates barcode format config before cache/use.
///
/// Compares `tag_name` after [String.trim] only — no alias / case rewrite.
abstract final class BarcodeConfigValidator {
  static const supportedDateFormats = {
    'dd/MM/yyyy',
    'dd-MM-yyyy',
    'yyyy-MM-dd',
    'ddMMyyyy',
    'yyyyMMdd',
  };

  static BarcodeConfigValidationResult validate(BarcodeFormatConfig config) {
    final tagFunction = config.tagFunction.trim();
    if (tagFunction.isEmpty) {
      return const BarcodeConfigValidationResult.invalid(
        errorCode: 'empty_tag_function',
        message: 'tag_function is empty',
      );
    }

    final separator = config.separator.trim();
    if (separator.isEmpty) {
      return const BarcodeConfigValidationResult.invalid(
        errorCode: 'empty_separator',
        message: 'separator is empty',
      );
    }

    if (config.fields.isEmpty) {
      return const BarcodeConfigValidationResult.invalid(
        errorCode: 'empty_fields',
        message: 'fields is empty',
      );
    }

    final sequences = <int>{};
    final names = <String>{};

    for (final field in config.fields) {
      if (field.tagSequence < 1) {
        return BarcodeConfigValidationResult.invalid(
          errorCode: 'invalid_tag_sequence',
          message: 'tag_sequence must be >= 1 (got ${field.tagSequence})',
        );
      }

      if (!sequences.add(field.tagSequence)) {
        return BarcodeConfigValidationResult.invalid(
          errorCode: 'duplicate_tag_sequence',
          message: 'duplicate tag_sequence ${field.tagSequence}',
        );
      }

      final name = field.tagName.trim();
      if (name.isEmpty) {
        return const BarcodeConfigValidationResult.invalid(
          errorCode: 'empty_tag_name',
          message: 'tag_name is empty',
        );
      }

      if (!names.add(name)) {
        return BarcodeConfigValidationResult.invalid(
          errorCode: 'duplicate_tag_name',
          message: 'duplicate tag_name $name',
        );
      }

      if (field.dataType == null) {
        return BarcodeConfigValidationResult.invalid(
          errorCode: 'unsupported_data_type',
          message:
              'tag_name $name has unsupported data_type ${field.rawDataType}',
        );
      }

      if (field.dataType == BarcodeDataType.date) {
        final format = field.format?.trim() ?? '';
        if (format.isEmpty) {
          return BarcodeConfigValidationResult.invalid(
            errorCode: 'missing_date_format',
            message: 'date field $name requires format',
          );
        }
        if (!supportedDateFormats.contains(format)) {
          return BarcodeConfigValidationResult.invalid(
            errorCode: 'unsupported_date_format',
            message: 'date field $name has unsupported format $format',
          );
        }
      }
    }

    return const BarcodeConfigValidationResult.ok();
  }
}
