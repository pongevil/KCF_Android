import 'dart:io';

import 'package:bs_mobile/src/core/barcode/barcode_scan_value.dart';
import 'package:bs_mobile/src/shared/camera/camera_image_utils.dart';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// หน้าสแกน QR/Barcode (UI) — เรียกผ่าน [CameraService] เท่านั้น
class BarcodeScannerPage extends StatefulWidget {
  final String title;
  final String? hint;
  final bool showCodeType;

  const BarcodeScannerPage({
    super.key,
    this.title = 'สแกนโค้ด',
    this.hint,
    this.showCodeType = false,
  });

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  CameraController? _controller;
  final BarcodeScanner _scanner = BarcodeScanner(formats: BarcodeFormat.values);

  bool _isFlashOn = false;
  bool _isProcessing = false;
  bool _isScanned = false;
  String? _lastCode;
  DateTime _lastFrameAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.startImageStream(_onCameraImage);
      setState(() => _controller = controller);
    } catch (e) {
      debugPrint('BarcodeScanner init error: $e');
    }
  }

  Future<void> _onCameraImage(CameraImage image) async {
    if (_isProcessing || _isScanned || _controller == null) return;

    final now = DateTime.now();
    if (now.difference(_lastFrameAt).inMilliseconds < 280) return;
    _lastFrameAt = now;

    _isProcessing = true;
    try {
      final input = cameraImageToInputImage(image, _controller!.description);
      if (input == null) return;

      final barcodes = await _scanner.processImage(input);
      if (barcodes.isEmpty) return;

      final code = barcodes.first.rawValue;
      if (code == null || code.isEmpty || code == _lastCode) return;

      _lastCode = code;
      _isScanned = true;
      await _controller?.stopImageStream();

      if (!mounted) return;
      if (widget.showCodeType) {
        _showScanSuccess(code, barcodes.first.format);
      }
      await Future.delayed(
        Duration(milliseconds: widget.showCodeType ? 400 : 0),
      );
      if (mounted) {
        Navigator.of(context).pop(
          BarcodeScanValue.fromMlKit(raw: code, format: barcodes.first.format),
        );
      }
    } catch (e) {
      debugPrint('Barcode scan error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void _showScanSuccess(String code, BarcodeFormat format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: AppText(
                'สแกนสำเร็จ: ${_formatType(format)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 400),
      ),
    );
  }

  String _formatType(BarcodeFormat format) {
    return switch (format) {
      BarcodeFormat.qrCode => 'QR Code',
      BarcodeFormat.code128 => 'Code 128',
      BarcodeFormat.code39 => 'Code 39',
      BarcodeFormat.ean13 => 'EAN-13',
      BarcodeFormat.ean8 => 'EAN-8',
      _ => 'Barcode',
    };
  }

  @override
  void dispose() {
    _scanner.close();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    try {
      await c.setFlashMode(_isFlashOn ? FlashMode.off : FlashMode.torch);
      setState(() => _isFlashOn = !_isFlashOn);
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: AppText(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: _isFlashOn ? Colors.amber : Colors.white,
            ),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: controller == null || !controller.value.isInitialized
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller),
                CustomPaint(
                  painter: const ScannerFrameOverlay(),
                  child: const SizedBox.expand(),
                ),
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppText(
                      widget.hint ?? 'วางโค้ดให้อยู่ในกรอบ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const AppText('ยกเลิก'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// กรอบสแกนรอบกล้อง
class ScannerFrameOverlay extends CustomPainter {
  const ScannerFrameOverlay();

  @override
  void paint(Canvas canvas, Size size) {
    final cutOut = size.width * 0.72;
    final left = (size.width - cutOut) / 2;
    final top = (size.height - cutOut) / 2;
    const radius = 16.0;
    const borderLength = 40.0;
    const borderWidth = 6.0;

    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, cutOut, cutOut),
            const Radius.circular(radius),
          ),
        )
        ..fillType = PathFillType.evenOdd,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    final borderPaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void corner(double x1, double y1, double x2, double y2) {
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), borderPaint);
    }

    corner(left, top + radius, left, top + borderLength);
    corner(left + radius, top, left + borderLength, top);
    corner(left + cutOut - borderLength, top, left + cutOut - radius, top);
    corner(left + cutOut, top + radius, left + cutOut, top + borderLength);
    corner(left, top + cutOut - borderLength, left, top + cutOut - radius);
    corner(left + radius, top + cutOut, left + borderLength, top + cutOut);
    corner(
      left + cutOut - borderLength,
      top + cutOut,
      left + cutOut - radius,
      top + cutOut,
    );
    corner(
      left + cutOut,
      top + cutOut - borderLength,
      left + cutOut,
      top + cutOut - radius,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
