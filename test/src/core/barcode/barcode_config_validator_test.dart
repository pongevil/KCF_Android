import 'package:bs_mobile/src/core/barcode/barcode_config_validator.dart';
import 'package:bs_mobile/src/core/barcode/barcode_format_model.dart';
import 'package:flutter_test/flutter_test.dart';

BarcodeFormatConfig _config({
  String separator = '|',
  String tagFunction = 'delivery_order',
  List<BarcodeFormatField>? fields,
}) {
  return BarcodeFormatConfig(
    separator: separator,
    tagFunction: tagFunction,
    fields:
        fields ??
        const [
          BarcodeFormatField(
            tagSequence: 1,
            tagName: 'batch_number',
            dataType: BarcodeDataType.string,
            required: true,
          ),
        ],
  );
}

void main() {
  group('BarcodeConfigValidator', () {
    test('accepts valid config', () {
      final result = BarcodeConfigValidator.validate(_config());
      expect(result.isValid, isTrue);
    });

    test('rejects empty tag_function', () {
      final result = BarcodeConfigValidator.validate(
        _config(tagFunction: '  '),
      );
      expect(result.isValid, isFalse);
      expect(result.errorCode, 'empty_tag_function');
    });

    test('rejects duplicate tag_sequence', () {
      final result = BarcodeConfigValidator.validate(
        _config(
          fields: const [
            BarcodeFormatField(
              tagSequence: 1,
              tagName: 'a',
              dataType: BarcodeDataType.string,
              required: true,
            ),
            BarcodeFormatField(
              tagSequence: 1,
              tagName: 'b',
              dataType: BarcodeDataType.string,
              required: false,
            ),
          ],
        ),
      );
      expect(result.errorCode, 'duplicate_tag_sequence');
    });

    test('rejects duplicate tag_name after trim only', () {
      final result = BarcodeConfigValidator.validate(
        _config(
          fields: const [
            BarcodeFormatField(
              tagSequence: 1,
              tagName: 'batch_number',
              dataType: BarcodeDataType.string,
              required: true,
            ),
            BarcodeFormatField(
              tagSequence: 2,
              tagName: ' batch_number ',
              dataType: BarcodeDataType.string,
              required: false,
            ),
          ],
        ),
      );
      expect(result.errorCode, 'duplicate_tag_name');
    });

    test('rejects date without format', () {
      final result = BarcodeConfigValidator.validate(
        _config(
          fields: const [
            BarcodeFormatField(
              tagSequence: 1,
              tagName: 'expiry_date',
              dataType: BarcodeDataType.date,
              required: false,
            ),
          ],
        ),
      );
      expect(result.errorCode, 'missing_date_format');
    });

    test('rejects unsupported data_type', () {
      final result = BarcodeConfigValidator.validate(
        _config(
          fields: const [
            BarcodeFormatField(
              tagSequence: 1,
              tagName: 'x',
              dataType: null,
              required: false,
              rawDataType: 'boolean',
            ),
          ],
        ),
      );
      expect(result.errorCode, 'unsupported_data_type');
    });
  });
}
