import 'dart:io';

import 'package:bs_mobile/src/core/barcode/barcode_field_key.dart';
import 'package:bs_mobile/src/core/barcode/barcode_format_model.dart';
import 'package:bs_mobile/src/core/barcode/barcode_format_repository.dart';
import 'package:bs_mobile/src/core/barcode/barcode_format_service.dart';
import 'package:bs_mobile/src/core/barcode/barcode_scan_value.dart';
import 'package:bs_mobile/src/shared/camera/barcode_scan_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements BarcodeFormatRepository {}

BarcodeFormatConfig _deliveryConfig() {
  return BarcodeFormatConfig(
    separator: '|',
    tagFunction: BarcodeTagFunction.deliveryOrder,
    fetchedAt: DateTime.now(),
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
}

void main() {
  late _MockRepo repo;
  late Directory tempDir;
  late BarcodeFormatService service;

  setUp(() async {
    repo = _MockRepo();
    tempDir = await Directory.systemTemp.createTemp('barcode_helper_test_');
    service = BarcodeFormatService(repo)..debugCacheDirectory = tempDir;
    when(() => repo.fetchAll()).thenAnswer((_) async => [_deliveryConfig()]);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BarcodeScanHelper.applyRaw', () {
    test('1D raw applies only entryField', () async {
      String? batch;
      DateTime? expiry;

      final result = await BarcodeScanHelper.applyRaw(
        raw: 'LOT123',
        tagFunction: BarcodeTagFunction.deliveryOrder,
        entryField: BarcodeFieldKey.batchNumber,
        apply: {
          BarcodeFieldKey.batchNumber: (v) => batch = v.stringValue,
          BarcodeFieldKey.expiryDate: (v) => expiry = v.requireDate(),
        },
        showAlert: false,
        formatService: service,
      );

      expect(result.success, isTrue);
      expect(batch, 'LOT123');
      expect(expiry, isNull);
    });

    test('2D delimiter raw applies multiple fields', () async {
      String? batch;
      String? lot;
      DateTime? expiry;

      final result = await BarcodeScanHelper.applyRaw(
        raw: 'BATCH-A|IGNORE-X|IGNORE-Y|LOT-A|31/12/2026',
        tagFunction: BarcodeTagFunction.deliveryOrder,
        entryField: BarcodeFieldKey.batchNumber,
        apply: {
          BarcodeFieldKey.batchNumber: (v) => batch = v.stringValue,
          BarcodeFieldKey.lot: (v) => lot = v.stringValue,
          BarcodeFieldKey.expiryDate: (v) => expiry = v.requireDate(),
        },
        showAlert: false,
        formatService: service,
      );

      expect(result.success, isTrue);
      expect(batch, 'BATCH-A');
      expect(lot, 'LOT-A');
      expect(expiry, DateTime(2026, 12, 31));
    });

    test('invalid 2D payload fails closed', () async {
      String? batch;
      final result = await BarcodeScanHelper.applyRaw(
        raw: '|X|Y|LOT-A|31/12/2026',
        tagFunction: BarcodeTagFunction.deliveryOrder,
        entryField: BarcodeFieldKey.batchNumber,
        apply: {BarcodeFieldKey.batchNumber: (v) => batch = v.stringValue},
        showAlert: false,
        formatService: service,
      );

      expect(result.success, isFalse);
      expect(result.errorCode, 'required_empty');
      expect(batch, isNull);
    });

    test('unknown tagFunction fails closed for delimiter raw', () async {
      when(() => repo.fetchAll()).thenAnswer((_) async => [_deliveryConfig()]);
      String? batch;

      final result = await BarcodeScanHelper.applyRaw(
        raw: 'A|B|C|D|31/12/2026',
        tagFunction: 'unknown_menu',
        entryField: BarcodeFieldKey.batchNumber,
        apply: {BarcodeFieldKey.batchNumber: (v) => batch = v.stringValue},
        showAlert: false,
        formatService: service,
      );

      expect(result.success, isFalse);
      expect(result.errorCode, 'no_config');
      expect(batch, isNull);
    });
  });

  group('BarcodeScanHelper.resolveAndApply', () {
    test('throws when entryField not in apply', () async {
      await expectLater(
        BarcodeScanHelper.resolveAndApply(
          scan: const BarcodeScanValue(
            raw: 'LOT123',
            format: BarcodeFormat.code128,
            isTwoDimensional: false,
          ),
          tagFunction: BarcodeTagFunction.deliveryOrder,
          entryField: BarcodeFieldKey.batchNumber,
          apply: {BarcodeFieldKey.lot: (_) {}},
          formatService: service,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('1D applies only entryField', () async {
      String? batch;
      DateTime? expiry;

      final result = await BarcodeScanHelper.resolveAndApply(
        scan: const BarcodeScanValue(
          raw: 'LOT123',
          format: BarcodeFormat.code128,
          isTwoDimensional: false,
        ),
        tagFunction: BarcodeTagFunction.deliveryOrder,
        entryField: BarcodeFieldKey.batchNumber,
        apply: {
          BarcodeFieldKey.batchNumber: (v) => batch = v.stringValue,
          BarcodeFieldKey.expiryDate: (v) => expiry = v.requireDate(),
        },
        formatService: service,
      );

      expect(result.success, isTrue);
      expect(batch, 'LOT123');
      expect(expiry, isNull);
    });
  });
}
