import 'package:csv/csv.dart';

import 'spreadsheet_format.dart';
import 'spreadsheet_table.dart';

/// Encode / decode pipe (or custom) delimited CSV text.
abstract final class CsvCodec {
  static SpreadsheetTable decode(
    String text, {
    CsvFormat format = SpreadsheetFormats.pipeCsv,
    bool firstRowIsHeader = true,
  }) {
    final csv = Csv(
      fieldDelimiter: format.delimiter,
      lineDelimiter: format.eol,
      quoteMode: format.shouldQuote ? QuoteMode.always : QuoteMode.necessary,
      autoDetect: false,
      skipEmptyLines: true,
      dynamicTyping: false,
    );
    final raw = csv.decode(text);
    final matrix = [
      for (final row in raw) [for (final cell in row) _cellToString(cell)],
    ];

    if (matrix.isEmpty) {
      return const SpreadsheetTable(headers: [], rows: []);
    }

    if (!firstRowIsHeader) {
      return SpreadsheetTable(headers: const [], rows: matrix);
    }

    final headers = matrix.first;
    final rows = matrix.length > 1 ? matrix.sublist(1) : <List<String>>[];
    return SpreadsheetTable(headers: headers, rows: rows);
  }

  static String encode(
    SpreadsheetTable table, {
    CsvFormat format = SpreadsheetFormats.pipeCsv,
    bool includeHeaders = true,
  }) {
    final csv = Csv(
      fieldDelimiter: format.delimiter,
      lineDelimiter: format.eol,
      quoteMode: format.shouldQuote ? QuoteMode.always : QuoteMode.necessary,
      autoDetect: false,
      addBom: false,
    );
    return csv.encode(table.toMatrix(includeHeaders: includeHeaders));
  }

  static String _cellToString(Object? cell) {
    if (cell == null) return '';
    return cell.toString();
  }
}
