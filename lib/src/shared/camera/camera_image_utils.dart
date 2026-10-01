import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// แปลง [CameraImage] จาก image stream เป็น [InputImage] สำหรับ ML Kit
InputImage? cameraImageToInputImage(
  CameraImage image,
  CameraDescription camera,
) {
  final rotation = _rotationFromCamera(camera);
  if (rotation == null) return null;

  if (Platform.isAndroid && image.format.group == ImageFormatGroup.yuv420) {
    final bytes = _yuv420ToNv21(image);
    if (bytes == null) return null;
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.width,
      ),
    );
  }

  if (image.format.group == ImageFormatGroup.bgra8888) {
    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.bgra8888,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  return null;
}

InputImageRotation? _rotationFromCamera(CameraDescription camera) {
  if (Platform.isIOS) {
    return InputImageRotationValue.fromRawValue(camera.sensorOrientation);
  }
  if (Platform.isAndroid) {
    return InputImageRotationValue.fromRawValue(camera.sensorOrientation);
  }
  return null;
}

Uint8List? _yuv420ToNv21(CameraImage image) {
  if (image.planes.length < 2) return null;

  final yPlane = image.planes[0];
  final uvPlane = image.planes[1];
  final ySize = yPlane.bytes.length;
  final uvSize = uvPlane.bytes.length;
  final nv21 = Uint8List(ySize + uvSize);

  nv21.setRange(0, ySize, yPlane.bytes);
  nv21.setRange(ySize, ySize + uvSize, uvPlane.bytes);
  return nv21;
}
