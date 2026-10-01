import 'dart:async';
import 'dart:io';

import 'package:bs_mobile/src/core/barcode/barcode_field_key.dart';
import 'package:bs_mobile/src/core/barcode/barcode_format_model.dart';
import 'package:bs_mobile/src/core/barcode/barcode_format_repository.dart';
import 'package:bs_mobile/src/core/barcode/barcode_format_service.dart';
import 'package:bs_mobile/src/shared/camera/barcode_scan_helper.dart';
import 'package:bs_mobile/src/shared/ui/widgets/custom_barcode_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  late TextEditingController batchController;
  late TextEditingController expiryController;
  late FocusNode batchFocus;
  late FocusNode expiryFocus;

  setUp(() async {
    repo = _MockRepo();
    tempDir = await Directory.systemTemp.createTemp('barcode_tf_test_');
    service = BarcodeFormatService(repo)..debugCacheDirectory = tempDir;
    when(() => repo.fetchAll()).thenAnswer((_) async => [_deliveryConfig()]);
    // Warm memory cache so submit path avoids disk IO under fake async.
    await service.prefetchAll();

    batchController = TextEditingController();
    expiryController = TextEditingController();
    batchFocus = FocusNode();
    expiryFocus = FocusNode();
  });

  tearDown(() async {
    batchFocus.dispose();
    expiryFocus.dispose();
    batchController.dispose();
    expiryController.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildApp({
    required Map<String, BarcodeApplyCallback> apply,
    void Function(BarcodeApplyResult)? onApplyResult,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            CustomBarcodeTextField(
              controller: batchController,
              focusNode: batchFocus,
              nextFocusNode: expiryFocus,
              labelText: 'Batch',
              tagFunction: BarcodeTagFunction.deliveryOrder,
              entryField: BarcodeFieldKey.batchNumber,
              apply: apply,
              formatService: service,
              showAlert: false,
              onApplyResult: onApplyResult,
            ),
            TextField(focusNode: expiryFocus, controller: expiryController),
          ],
        ),
      ),
    );
  }

  Future<BarcodeApplyResult> submitAndWait(
    WidgetTester tester,
    String value,
    Completer<BarcodeApplyResult> done,
  ) async {
    // SubmitDebounce uses wall-clock time — advance real time, not fake async.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.enterText(find.byType(TextFormField).first, value);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    // CustomTextField: 100ms delay before callback (fake-async).
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(done.isCompleted, isTrue, reason: 'onApplyResult should have fired');
    return done.future;
  }

  Future<void> detachTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  group('CustomBarcodeTextField', () {
    testWidgets('shows scan icon and wires scan handler', (tester) async {
      await tester.pumpWidget(
        buildApp(apply: {BarcodeFieldKey.batchNumber: (v) {}}),
      );

      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.onPressed, isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('Enter 2D applies multiple fields and moves focus', (
      tester,
    ) async {
      String? lot;
      DateTime? expiry;
      final done = Completer<BarcodeApplyResult>();

      await tester.pumpWidget(
        buildApp(
          apply: {
            BarcodeFieldKey.batchNumber: (v) {
              batchController.text = v.stringValue ?? '';
            },
            BarcodeFieldKey.lot: (v) => lot = v.stringValue,
            BarcodeFieldKey.expiryDate: (v) {
              expiry = v.requireDate();
              expiryController.text = 'ok';
            },
          },
          onApplyResult: done.complete,
        ),
      );

      batchFocus.requestFocus();
      await tester.pump();

      final last = await submitAndWait(
        tester,
        'BATCH-A|IGNORE-X|IGNORE-Y|LOT-A|31/12/2026',
        done,
      );

      expect(last.success, isTrue);
      expect(batchController.text, 'BATCH-A');
      expect(lot, 'LOT-A');
      expect(expiry, DateTime(2026, 12, 31));
      expect(expiryFocus.hasFocus, isTrue);
      await detachTree(tester);
    });

    testWidgets('Enter 1D applies only entry and moves focus', (tester) async {
      DateTime? expiry;
      final done = Completer<BarcodeApplyResult>();

      await tester.pumpWidget(
        buildApp(
          apply: {
            BarcodeFieldKey.batchNumber: (v) {
              batchController.text = v.stringValue ?? '';
            },
            BarcodeFieldKey.expiryDate: (v) => expiry = v.requireDate(),
          },
          onApplyResult: done.complete,
        ),
      );

      batchFocus.requestFocus();
      await tester.pump();
      final last = await submitAndWait(tester, 'LOT123', done);

      expect(last.success, isTrue);
      expect(batchController.text, 'LOT123');
      expect(expiry, isNull);
      expect(expiryFocus.hasFocus, isTrue);
      await detachTree(tester);
    });

    testWidgets('failure keeps focus on entry field', (tester) async {
      final done = Completer<BarcodeApplyResult>();

      await tester.pumpWidget(
        buildApp(
          apply: {
            BarcodeFieldKey.batchNumber: (v) {
              batchController.text = v.stringValue ?? '';
            },
          },
          onApplyResult: done.complete,
        ),
      );

      batchFocus.requestFocus();
      await tester.pump();
      final last = await submitAndWait(tester, '|X|Y|LOT|31/12/2026', done);

      expect(last.success, isFalse);
      expect(batchFocus.hasFocus, isTrue);
      expect(expiryFocus.hasFocus, isFalse);
      await detachTree(tester);
    });
  });
}
