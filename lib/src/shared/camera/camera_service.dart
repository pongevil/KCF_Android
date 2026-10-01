import 'dart:io';

import 'package:bs_mobile/src/core/barcode/barcode_scan_value.dart';
import 'package:bs_mobile/src/shared/camera/barcode_scanner_page.dart';
import 'package:bs_mobile/src/shared/camera/photo_capture_page.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// จุดเข้าเดียวสำหรับกล้องในแอพ
///
/// | ต้องการ | เรียก |
/// |--------|--------|
/// | ถ่ายรูป | [takePicture] → `File?` |
/// | สแกน QR/Barcode (string) | [scanBarcode] → `String?` |
/// | สแกน structured | [scanBarcodeValue] → `BarcodeScanValue?` |
///
/// UI อยู่ที่ [PhotoCapturePage] / [BarcodeScannerPage] — ไม่ต้อง push เอง
class CameraService {
  CameraService._();

  static Future<bool> _ensureCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    status = await Permission.camera.request();
    return status.isGranted;
  }

  /// เปิดกล้องถ่ายรูป
  static Future<File?> takePicture(BuildContext context) async {
    if (!await _ensureCameraPermission()) return null;

    final cameras = await availableCameras();
    if (cameras.isEmpty || !context.mounted) return null;

    return Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (_) => PhotoCapturePage(cameras: cameras)),
    );
  }

  /// เปิดกล้องสแกน QR / Barcode — คืน raw string (API เดิม)
  static Future<String?> scanBarcode(
    BuildContext context, {
    String title = 'สแกนโค้ด',
    String? hint,
    bool showCodeType = false,
  }) async {
    final value = await scanBarcodeValue(
      context,
      title: title,
      hint: hint,
      showCodeType: showCodeType,
    );
    return value?.raw;
  }

  /// Structured scan result for 1D/2D barcode format apply.
  static Future<BarcodeScanValue?> scanBarcodeValue(
    BuildContext context, {
    String title = 'สแกนโค้ด',
    String? hint,
    bool showCodeType = false,
  }) async {
    if (!await _ensureCameraPermission()) return null;
    if (!context.mounted) return null;

    return Navigator.push<BarcodeScanValue>(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeScannerPage(
          title: title,
          hint: hint,
          showCodeType: showCodeType,
        ),
      ),
    );
  }
}
