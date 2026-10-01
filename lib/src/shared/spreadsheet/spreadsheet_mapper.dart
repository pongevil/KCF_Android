import 'spreadsheet_table.dart';

/// Error for a single data row during import mapping.
class SpreadsheetRowError {
  /// 1-based index among data rows (header is not counted).
  final int rowIndex;
  final String message;
  final Object? cause;

  const SpreadsheetRowError({
    required this.rowIndex,
    required this.message,
    this.cause,
  });

  @override
  String toString() => 'Row $rowIndex: $message';
}

/// Partial-success import: good [items] plus per-row [errors].
class SpreadsheetImportResult<T> {
  final List<T> items;
  final List<SpreadsheetRowError> errors;

  const SpreadsheetImportResult({required this.items, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
  bool get isEmpty => items.isEmpty;
}

/// Maps [SpreadsheetTable] rows to typed models without failing the whole file.
abstract final class SpreadsheetMapper {
  /// Requires non-empty headers. Calls [fromRow] per data row.
  ///
  /// Throws from [fromRow] are collected into [SpreadsheetImportResult.errors]
  /// (row still skipped). Optional [requiredHeaders] checked once up front —
  /// if missing, returns empty items and a single error at rowIndex `0`.
  static SpreadsheetImportResult<T> mapRows<T>(
    SpreadsheetTable table, {
    required T Function(Map<String, String> row) fromRow,
    List<String> requiredHeaders = const [],
  }) {
    if (table.headers.isEmpty) {
      return SpreadsheetImportResult<T>(
        items: const [],
        errors: [
          const SpreadsheetRowError(rowIndex: 0, message: 'Missing header row'),
        ],
      );
    }

    if (requiredHeaders.isNotEmpty) {
      final missing = requiredHeaders
          .where((h) => !table.headers.contains(h))
          .toList(growable: false);
      if (missing.isNotEmpty) {
        return SpreadsheetImportResult<T>(
          items: const [],
          errors: [
            SpreadsheetRowError(
              rowIndex: 0,
              message: 'Missing required columns: ${missing.join(', ')}',
            ),
          ],
        );
      }
    }

    final items = <T>[];
    final errors = <SpreadsheetRowError>[];
    final maps = table.asMaps;

    for (var i = 0; i < maps.length; i++) {
      final rowNumber = i + 1;
      try {
        items.add(fromRow(maps[i]));
      } catch (e) {
        errors.add(
          SpreadsheetRowError(
            rowIndex: rowNumber,
            message: e is FormatException ? e.message : e.toString(),
            cause: e,
          ),
        );
      }
    }

    return SpreadsheetImportResult<T>(items: items, errors: errors);
  }

  /// Builds a [SpreadsheetTable] from models.
  static SpreadsheetTable toTable<T>({
    required List<String> headers,
    required List<T> items,
    required List<String> Function(T item) toRow,
  }) {
    return SpreadsheetTable(
      headers: headers,
      rows: [for (final item in items) toRow(item)],
    );
  }
}
