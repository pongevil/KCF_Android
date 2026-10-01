/// In-memory spreadsheet: header row + data rows (all cells as [String]).
class SpreadsheetTable {
  final List<String> headers;
  final List<List<String>> rows;

  const SpreadsheetTable({required this.headers, required this.rows});

  bool get hasHeaders => headers.isNotEmpty;

  int get columnCount {
    var max = headers.length;
    for (final row in rows) {
      if (row.length > max) max = row.length;
    }
    return max;
  }

  /// Maps each data row to `header → cell`. Missing cells become `''`.
  /// Extra cells beyond [headers] are ignored. Requires non-empty [headers].
  List<Map<String, String>> get asMaps {
    if (headers.isEmpty) {
      return const <Map<String, String>>[];
    }
    return [
      for (final row in rows)
        {
          for (var i = 0; i < headers.length; i++)
            headers[i]: i < row.length ? row[i] : '',
        },
    ];
  }

  /// All rows including header (for encode).
  List<List<String>> toMatrix({bool includeHeaders = true}) {
    if (!includeHeaders || headers.isEmpty) {
      return [for (final row in rows) List<String>.from(row)];
    }
    return [
      List<String>.from(headers),
      for (final row in rows) List<String>.from(row),
    ];
  }
}
