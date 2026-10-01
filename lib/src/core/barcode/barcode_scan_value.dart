import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// Structured scanner result — keeps raw string API via [raw].
class BarcodeScanValue {
  const BarcodeScanValue({
    required this.raw,
    required this.format,
    required this.isTwoDimensional,
  });

  final String raw;
  final BarcodeFormat format;
  final bool isTwoDimensional;

  factory BarcodeScanValue.fromMlKit({
    required String raw,
    required BarcodeFormat format,
  }) {
    return BarcodeScanValue(
      raw: raw,
      format: format,
      isTwoDimensional: isTwoDimensionalFormat(format),
    );
  }

  static bool isTwoDimensionalFormat(BarcodeFormat format) {
    return switch (format) {
      BarcodeFormat.qrCode ||
      BarcodeFormat.aztec ||
      BarcodeFormat.dataMatrix ||
      BarcodeFormat.pdf417 => true,
      _ => false,
    };
  }
}
