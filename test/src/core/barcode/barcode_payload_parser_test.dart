import 'package:bs_mobile/src/core/barcode/barcode_field_key.dart';
import 'package:bs_mobile/src/core/barcode/barcode_format_model.dart';
import 'package:bs_mobile/src/core/barcode/barcode_payload_parser.dart';
import 'package:bs_mobile/src/core/barcode/barcode_typed_value.dart';
import 'package:flutter_test/flutter_test.dart';

final _deliveryConfig = BarcodeFormatConfig(
  separator: '|',
  tagFunction: BarcodeTagFunction.deliveryOrder,
  fields: const [
    BarcodeFormatField(
      tagSequence: 1,
      tagName: BarcodeFieldKey.batchNumber,
      dataType: BarcodeDataType.string,
      required: true,
    ),
    BarcodeFormatField(
      tagSequence: 4,
      tagName: BarcodeFieldKey.lot,
      dataType: BarcodeDataType.string,
      required: false,
    ),
    BarcodeFormatField(
      tagSequence: 5,
      tagName: BarcodeFieldKey.expiryDate,
      dataType: BarcodeDataType.date,
      required: false,
      format: 'dd/MM/yyyy',
    ),
  ],
);

void main() {
  group('BarcodePayloadParser', () {
    test('parses gaps in tag_sequence (1,4,5)', () {
      const raw = 'BATCH-A|IGNORE-X|IGNORE-Y|LOT-A|31/12/2026';
      final result = BarcodePayloadParser.parse(
        raw: raw,
        config: _deliveryConfig,
      );

      expect(result, isA<BarcodeParseSuccess>());
      final values = (result as BarcodeParseSuccess).values;
      expect(values[BarcodeFieldKey.batchNumber]?.stringValue, 'BATCH-A');
      expect(values[BarcodeFieldKey.lot]?.stringValue, 'LOT-A');
      expect(
        values[BarcodeFieldKey.expiryDate]?.dateValue,
        DateTime(2026, 12, 31),
      );
      expect(values.containsKey('IGNORE-X'), isFalse);
    });

    test('uses exact tag_name keys — no alias from batch', () {
      const raw = 'BATCH-A|X|Y|LOT-A|31/12/2026';
      final result =
          BarcodePayloadParser.parse(raw: raw, config: _deliveryConfig)
              as BarcodeParseSuccess;

      expect(result.values.containsKey('batch'), isFalse);
      expect(result.values.containsKey(BarcodeFieldKey.batchNumber), isTrue);
    });

    test('required empty fails whole set', () {
      const raw = '|X|Y|LOT-A|31/12/2026';
      final result = BarcodePayloadParser.parse(
        raw: raw,
        config: _deliveryConfig,
      );

      expect(result, isA<BarcodeParseFailure>());
      final failure = result as BarcodeParseFailure;
      expect(failure.errorCode, 'required_empty');
      expect(failure.tagName, BarcodeFieldKey.batchNumber);
    });

    test('optional empty skips field without failing', () {
      const raw = 'BATCH-A|X|Y||';
      final result = BarcodePayloadParser.parse(
        raw: raw,
        config: _deliveryConfig,
      );

      expect(result, isA<BarcodeParseSuccess>());
      final values = (result as BarcodeParseSuccess).values;
      expect(values[BarcodeFieldKey.batchNumber]?.stringValue, 'BATCH-A');
      expect(values.containsKey(BarcodeFieldKey.lot), isFalse);
      expect(values.containsKey(BarcodeFieldKey.expiryDate), isFalse);
    });

    test('invalid date format fails whole set', () {
      const raw = 'BATCH-A|X|Y|LOT-A|2026-12-31';
      final result = BarcodePayloadParser.parse(
        raw: raw,
        config: _deliveryConfig,
      );

      expect(result, isA<BarcodeParseFailure>());
      final failure = result as BarcodeParseFailure;
      expect(failure.errorCode, 'type_parse_failed');
      expect(failure.tagName, BarcodeFieldKey.expiryDate);
    });

    test('payload shorter than max sequence fails', () {
      const raw = 'BATCH-A|X';
      final result = BarcodePayloadParser.parse(
        raw: raw,
        config: _deliveryConfig,
      );

      expect(result, isA<BarcodeParseFailure>());
      expect((result as BarcodeParseFailure).errorCode, 'payload_too_short');
    });
  });
}
