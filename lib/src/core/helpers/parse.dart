import 'package:intl/intl.dart';

/// Shared JSON value parsers for API model `fromJson` factories.
///
/// Use [Parse] instead of copying private `_parseInt` / `_parseDouble` helpers
/// into each model file.
///
/// AI / dev guide: see `README.md` → **Parse — JSON helpers** (Core Modules).
abstract final class Parse {
  Parse._();
  static const _minYear = 1900;
  static const _maxYear = 2100;

  static final _scanFormats = <_ScanDateFormat>[
    _ScanDateFormat(
      pattern: 'dd/MM/yyyy',
      regex: RegExp(r'^\d{2}/\d{2}/\d{4}$'),
    ),
    _ScanDateFormat(
      pattern: 'yyyy-MM-dd',
      regex: RegExp(r'^\d{4}-\d{2}-\d{2}$'),
    ),
    _ScanDateFormat(
      pattern: 'dd-MM-yyyy',
      regex: RegExp(r'^\d{2}-\d{2}-\d{4}$'),
    ),
  ];

  static String toDisplayDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String toDisplayDateOrEmpty(DateTime? date) {
    return date != null ? DateFormat('dd/MM/yyyy').format(date) : ' ';
  }

  static String toStorageDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static DateTime? parseScannedDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    for (final format in _scanFormats) {
      if (!format.regex.hasMatch(trimmed)) {
        continue;
      }

      final parsed = _parseWithPattern(trimmed, format.pattern);
      if (parsed != null) {
        return parsed;
      }
    }

    return _parseCompact8DigitDate(trimmed);
  }

  static DateTime? _parseCompact8DigitDate(String trimmed) {
    if (!RegExp(r'^\d{8}$').hasMatch(trimmed)) {
      return null;
    }

    final yearFirst = int.tryParse(trimmed.substring(0, 4));
    final monthFromYearFirst = int.tryParse(trimmed.substring(4, 6));
    final dayFromYearFirst = int.tryParse(trimmed.substring(6, 8));
    if (yearFirst != null &&
        monthFromYearFirst != null &&
        dayFromYearFirst != null &&
        yearFirst >= _minYear &&
        yearFirst <= _maxYear) {
      final date = DateTime(yearFirst, monthFromYearFirst, dayFromYearFirst);
      if (_isAcceptedDate(date) &&
          date.year == yearFirst &&
          date.month == monthFromYearFirst &&
          date.day == dayFromYearFirst) {
        return DateTime(yearFirst, monthFromYearFirst, dayFromYearFirst);
      }
    }

    final dayFirst = int.tryParse(trimmed.substring(0, 2));
    final monthFromDayFirst = int.tryParse(trimmed.substring(2, 4));
    final yearFromDayFirst = int.tryParse(trimmed.substring(4, 8));
    if (dayFirst != null &&
        monthFromDayFirst != null &&
        yearFromDayFirst != null &&
        yearFromDayFirst >= _minYear &&
        yearFromDayFirst <= _maxYear) {
      final date = DateTime(yearFromDayFirst, monthFromDayFirst, dayFirst);
      if (_isAcceptedDate(date) &&
          date.year == yearFromDayFirst &&
          date.month == monthFromDayFirst &&
          date.day == dayFirst) {
        return DateTime(yearFromDayFirst, monthFromDayFirst, dayFirst);
      }
    }

    return null;
  }

  static DateTime? _parseWithPattern(String trimmed, String pattern) {
    try {
      final parsed = DateFormat(pattern).parseStrict(trimmed);
      final date = DateTime(parsed.year, parsed.month, parsed.day);

      if (!_isAcceptedDate(date)) {
        return null;
      }

      if (DateFormat(pattern).format(date) != trimmed) {
        return null;
      }

      return date;
    } catch (_) {
      return null;
    }
  }

  static bool _isAcceptedDate(DateTime date) {
    if (date.year < _minYear || date.year > _maxYear) {
      return false;
    }

    if (date.month < 1 || date.month > 12) {
      return false;
    }

    if (date.day < 1 || date.day > 31) {
      return false;
    }

    return true;
  }

  /// Parses ISO-8601 date strings from API JSON. Returns `null` when empty or invalid.
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  /// Parses numeric JSON values (`num` or string) to `double?`.
  static double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// Parses numeric JSON values (`int` or string) to `int?`.
  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static String? parseString(dynamic value) {
    if (value == null) return null;
    final trimmed = value.toString().trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// แปลงเป็น [bool]; รองรับ `bool`, `0`/`1`, `"true"`/`"false"`, `"YES"`/`"NO"`
  static bool? parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value == 1 || value == '1') return true;
    if (value == 0 || value == '0') return false;

    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == 'yes') return true;
    if (normalized == 'false' || normalized == 'no') return false;
    return null;
  }

  /// แปลง list เป็น [List<String>] — ข้าม element ที่ว่างหลัง trim
  static List<String> parseStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map(parseString).whereType<String>().toList(growable: false);
  }

  static int parseIntOr(dynamic value, int fallback) =>
      parseInt(value) ?? fallback;

  static double parseDoubleOr(dynamic value, double fallback) =>
      parseDouble(value) ?? fallback;

  static bool parseBoolOr(dynamic value, bool fallback) =>
      parseBool(value) ?? fallback;

  static String parseStringOr(dynamic value, String fallback) =>
      parseString(value) ?? fallback;
}

class _ScanDateFormat {
  const _ScanDateFormat({required this.pattern, required this.regex});

  final String pattern;
  final RegExp regex;
}
