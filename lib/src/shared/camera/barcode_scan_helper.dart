import 'package:bs_mobile/src/app/di/injection.dart';
import 'package:bs_mobile/src/core/barcode/barcode_format_service.dart';
import 'package:bs_mobile/src/core/barcode/barcode_payload_parser.dart';
import 'package:bs_mobile/src/core/barcode/barcode_scan_value.dart';
import 'package:bs_mobile/src/core/barcode/barcode_typed_value.dart';
import 'package:bs_mobile/src/core/helpers/debug_log_colors.dart';
import 'package:bs_mobile/src/shared/camera/camera_service.dart';
import 'package:bs_mobile/src/shared/ui/notification/custom_show_alert.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

typedef BarcodeApplyCallback = void Function(BarcodeTypedValue value);

class BarcodeApplyResult {
  const BarcodeApplyResult._({
    required this.success,
    this.errorCode,
    this.message,
    this.tagName,
    this.appliedKeys = const {},
  });

  const BarcodeApplyResult.success({required Set<String> appliedKeys})
    : this._(success: true, appliedKeys: appliedKeys);

  const BarcodeApplyResult.failure({
    required String errorCode,
    required String message,
    String? tagName,
  }) : this._(
         success: false,
         errorCode: errorCode,
         message: message,
         tagName: tagName,
       );

  final bool success;
  final String? errorCode;
  final String? message;
  final String? tagName;
  final Set<String> appliedKeys;
}

/// Camera / keyboard entry + format config + strict parse + atomic apply.
///
/// Lives in `shared/` because it uses camera UI and alerts.
abstract final class BarcodeScanHelper {
  /// Opens camera, loads format for [tagFunction], parses, then applies.
  static Future<BarcodeApplyResult> scanAndApply(
    BuildContext context, {
    required String tagFunction,
    required String entryField,
    required Map<String, BarcodeApplyCallback> apply,
    String title = 'สแกนโค้ด',
    String? hint,
    bool showAlert = true,
    BarcodeFormatService? formatService,
  }) async {
    _assertEntryField(entryField: entryField, apply: apply);

    final scan = await CameraService.scanBarcodeValue(
      context,
      title: title,
      hint: hint,
    );
    if (scan == null) {
      return const BarcodeApplyResult.failure(
        errorCode: 'cancelled',
        message: 'Scan cancelled',
      );
    }
    if (!context.mounted) {
      return const BarcodeApplyResult.failure(
        errorCode: 'unmounted',
        message: 'Context unmounted after scan',
      );
    }

    final service = formatService ?? getIt<BarcodeFormatService>();
    final result = await resolveAndApply(
      scan: scan,
      tagFunction: tagFunction,
      entryField: entryField,
      apply: apply,
      formatService: service,
    );

    if (!result.success && showAlert && context.mounted) {
      CustomShowAlert.showWarning(result.message ?? 'Scan failed');
    }

    return result;
  }

  /// Apply typed / HID scanner text (e.g. `onFieldSubmitted`) without camera.
  ///
  /// No delimiter → 1D (entry field only). Has separator from config → 2D parse.
  /// Delimited raw without a format for [tagFunction] → fail closed.
  static Future<BarcodeApplyResult> applyRaw({
    required String raw,
    required String tagFunction,
    required String entryField,
    required Map<String, BarcodeApplyCallback> apply,
    bool showAlert = true,
    BarcodeFormatService? formatService,
  }) async {
    _assertEntryField(entryField: entryField, apply: apply);

    final service = formatService ?? getIt<BarcodeFormatService>();
    final trimmed = raw.trim();
    final config = await service.getFormat(tagFunction);
    final hasDelimiter =
        config != null &&
        config.separator.isNotEmpty &&
        trimmed.contains(config.separator);

    // Pipe-delimited HID payload with no matching tagFunction must not become 1D.
    if (config == null && trimmed.contains('|')) {
      final result = BarcodeApplyResult.failure(
        errorCode: 'no_config',
        message: 'No barcode format for $tagFunction',
      );
      if (showAlert) {
        CustomShowAlert.showWarning(result.message ?? 'Scan failed');
      }
      return result;
    }

    final result = await resolveAndApply(
      scan: BarcodeScanValue(
        raw: trimmed,
        format: BarcodeFormat.unknown,
        isTwoDimensional: hasDelimiter,
      ),
      tagFunction: tagFunction,
      entryField: entryField,
      apply: apply,
      formatService: service,
    );

    if (!result.success &&
        showAlert &&
        result.errorCode != 'cancelled' &&
        result.errorCode != 'empty_raw') {
      CustomShowAlert.showWarning(result.message ?? 'Scan failed');
    }

    return result;
  }

  /// Testable path without camera — validates then applies atomically.
  static Future<BarcodeApplyResult> resolveAndApply({
    required BarcodeScanValue scan,
    required String tagFunction,
    required String entryField,
    required Map<String, BarcodeApplyCallback> apply,
    required BarcodeFormatService formatService,
  }) async {
    _assertEntryField(entryField: entryField, apply: apply);

    final entryKey = entryField.trim();
    final raw = scan.raw.trim();
    if (raw.isEmpty) {
      return const BarcodeApplyResult.failure(
        errorCode: 'empty_raw',
        message: 'Empty barcode',
      );
    }

    final config = await formatService.getFormat(tagFunction);
    final hasDelimiter =
        config != null &&
        config.separator.isNotEmpty &&
        raw.contains(config.separator);

    // Confirmed 1D and no config separator in raw → entry field only.
    if (!scan.isTwoDimensional && !hasDelimiter) {
      final callback = apply[entryKey];
      if (callback == null) {
        return BarcodeApplyResult.failure(
          errorCode: 'entry_not_registered',
          message: 'entryField $entryKey is not in apply',
        );
      }
      callback(BarcodeTypedValue.string(tagName: entryKey, raw: raw));
      return BarcodeApplyResult.success(appliedKeys: {entryKey});
    }

    // 2D or delimiter present → need config (fail closed).
    if (config == null) {
      printDebug(
        'BarcodeScan fail-closed: no config for $tagFunction',
        DebugLogType.error,
      );
      return BarcodeApplyResult.failure(
        errorCode: 'no_config',
        message: 'No barcode format for $tagFunction',
      );
    }

    final parsed = BarcodePayloadParser.parse(raw: raw, config: config);
    if (parsed is BarcodeParseFailure) {
      printDebug(
        'BarcodeScan parse failed for $tagFunction: ${parsed.errorCode}'
        '${parsed.tagName != null ? ' (${parsed.tagName})' : ''}',
        DebugLogType.error,
      );
      return BarcodeApplyResult.failure(
        errorCode: parsed.errorCode,
        message: parsed.message,
        tagName: parsed.tagName,
      );
    }

    final success = parsed as BarcodeParseSuccess;
    final applied = <String>{};

    // Atomic: all callbacks after full validation (parser already atomic).
    for (final entry in success.values.entries) {
      final callback = apply[entry.key];
      if (callback == null) {
        continue; // unregistered tag_name → ignore
      }
      callback(entry.value);
      applied.add(entry.key);
    }

    return BarcodeApplyResult.success(appliedKeys: applied);
  }

  static void _assertEntryField({
    required String entryField,
    required Map<String, BarcodeApplyCallback> apply,
  }) {
    final key = entryField.trim();
    if (!apply.containsKey(key)) {
      throw ArgumentError('entryField "$key" must be registered in apply map');
    }
  }
}
