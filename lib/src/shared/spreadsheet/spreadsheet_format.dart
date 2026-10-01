/// File / codec kind for import & export.
enum SpreadsheetKind { excel, pipeCsv }

/// CSV encode/decode options. Default delimiter is `|`.
class CsvFormat {
  final String delimiter;
  final String eol;

  /// When true, every field is quoted. When false (default), quote only when
  /// the cell contains the delimiter, quotes, or newlines.
  final bool shouldQuote;

  const CsvFormat({
    this.delimiter = '|',
    this.eol = '\n',
    this.shouldQuote = false,
  });
}

/// Excel sheet selection (decode).
class ExcelFormat {
  /// When null, uses the first sheet in the workbook.
  final String? sheetName;

  const ExcelFormat({this.sheetName});
}

/// Shared defaults.
abstract final class SpreadsheetFormats {
  static const pipeCsv = CsvFormat(delimiter: '|');
  static const excelXlsx = ExcelFormat();
}
