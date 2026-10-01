class QuantityConfig {
  final int decimalPlaces;
  final int maxIntegerDigits;

  const QuantityConfig({
    required this.decimalPlaces,
    required this.maxIntegerDigits,
  });

  static const QuantityConfig defaults = QuantityConfig(
    decimalPlaces: 3,
    maxIntegerDigits: 10,
  );

  factory QuantityConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return defaults;
    }

    return QuantityConfig(
      decimalPlaces:
          _asPositiveInt(json['decimal_places']) ?? defaults.decimalPlaces,
      maxIntegerDigits:
          _asPositiveInt(json['max_integer_digits']) ??
          defaults.maxIntegerDigits,
    );
  }

  RegExp get inputPattern => buildQuantityInputPattern(
    maxIntegerDigits: maxIntegerDigits,
    decimalPlaces: decimalPlaces,
  );

  Map<String, dynamic> toJson() => {
    'decimal_places': decimalPlaces,
    'max_integer_digits': maxIntegerDigits,
  };

  static RegExp buildQuantityInputPattern({
    required int maxIntegerDigits,
    required int decimalPlaces,
  }) {
    if (decimalPlaces <= 0) {
      return RegExp('^\\d{0,$maxIntegerDigits}\$');
    }

    return RegExp('^\\d{0,$maxIntegerDigits}(\\.\\d{0,$decimalPlaces})?\$');
  }

  static int? _asPositiveInt(dynamic value) {
    if (value == null) return null;

    final parsed = value is int ? value : int.tryParse(value.toString());
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }
}
