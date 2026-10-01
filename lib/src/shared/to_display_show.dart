import 'package:intl/intl.dart';

class ToDisplayShow {
  static const String dateFormat = 'dd/MM/yyyy';
  static String displayValue(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '-' : trimmed;
  }

  static String? firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmedValue = trimOrNull(value);
      if (trimmedValue != null) {
        return trimmedValue;
      }
    }

    return null;
  }

  static String? trimOrNull(String? value) {
    final trimmedValue = value?.trim();
    if (trimmedValue == null || trimmedValue.isEmpty) {
      return null;
    }

    return trimmedValue;
  }

  static String toDisplayDate(DateTime date) {
    return DateFormat(dateFormat).format(date);
  }

  static String formatTimeOrEmpty(DateTime? date) {
    return date != null ? DateFormat('HH:mm').format(date) : '-';
  }

  static String formatDateOrEmpty(DateTime? date) {
    return date != null ? DateFormat(dateFormat).format(date) : '-';
  }

  /// Storage / file-name safe date (`yyyyMMdd`) — not for UI display.
  static String toFileNameDate(DateTime date) {
    return DateFormat('yyyyMMdd').format(date);
  }

  static DateTime parseDate(String date) {
    return DateFormat(dateFormat).parse(date);
  }
}
