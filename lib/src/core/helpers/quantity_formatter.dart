import 'package:bs_mobile/src/core/app_config/app_config_service.dart';
import 'package:bs_mobile/src/core/app_config/quantity_config.dart';

/// Central quantity formatting based on [AppConfigService] / API config.
class QuantityFormatter {
  QuantityFormatter._();

  static QuantityConfig get _config => AppConfigService.instance.quantity;

  /// Display on screen — e.g. 12.3 with 2 decimals → "12.30"
  static String formatDisplay(
    num? value, {
    QuantityConfig? config,
    String emptyFallback = '-',
  }) {
    if (value == null) {
      return emptyFallback;
    }

    final cfg = config ?? _config;
    if (cfg.decimalPlaces <= 0) {
      return value.truncate().toString();
    }

    return value.toStringAsFixed(cfg.decimalPlaces);
  }

  /// Value for quantity text field after +/- or programmatic set.
  static String formatInput(num value, {QuantityConfig? config}) {
    final cfg = config ?? _config;
    if (cfg.decimalPlaces <= 0) {
      return value.truncate().toString();
    }

    return value.toStringAsFixed(cfg.decimalPlaces);
  }

  /// Parse text field / API string to double.
  static double parse(String value, {double fallback = 0}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }

    return double.tryParse(trimmed) ?? fallback;
  }

  /// Round before sending to API.
  static double roundForApi(num value, {QuantityConfig? config}) {
    final cfg = config ?? _config;
    return roundHalfUp(value, decimalPlaces: cfg.decimalPlaces);
  }

  /// Round with half-up strategy at the requested decimal places.
  /// Example: 1.335 -> 1.34 when [decimalPlaces] is 2.
  static double roundHalfUp(num value, {required int decimalPlaces}) {
    if (decimalPlaces <= 0) {
      return value.roundToDouble();
    }

    final absText = value.abs().toStringAsFixed(decimalPlaces + 8);
    final parts = absText.split('.');
    final integerPart = parts.first;
    final fractionPart = parts.length > 1 ? parts[1] : '';
    final paddedFraction = fractionPart.padRight(decimalPlaces + 1, '0');
    final keep = paddedFraction.substring(0, decimalPlaces);
    final nextDigit = int.parse(paddedFraction[decimalPlaces]);

    var scaled = BigInt.parse('$integerPart$keep');
    if (nextDigit >= 5) {
      scaled += BigInt.one;
    }

    final factor = _pow10(decimalPlaces);
    final roundedAbs = scaled.toDouble() / factor;
    return value.isNegative ? -roundedAbs : roundedAbs;
  }

  static double _pow10(int places) {
    var result = 1.0;
    for (var i = 0; i < places; i++) {
      result *= 10;
    }
    return result;
  }
}
