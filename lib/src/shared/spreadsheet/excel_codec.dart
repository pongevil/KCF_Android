import 'dart:typed_data';

import 'package:excel/excel.dart';

import 'spreadsheet_format.dart';
import 'spreadsheet_table.dart';

/// Encode / decode `.xlsx` workbooks.
abstract final class ExcelCodec {
  static SpreadsheetTable decode(
    Uint8List bytes, {
    ExcelFormat format = SpreadsheetFormats.excelXlsx,
    bool firstRowIsHeader = true,
  }) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = _resolveSheet(excel, format.sheetName);
    final matrix = <List<String>>[];

    for (final row in sheet.rows) {
      final cells = <String>[
        for (final cell in row) _cellToString(cell?.value),
      ];
      // Skip completely empty trailing-style rows
      if (cells.every((c) => c.trim().isEmpty)) continue;
      matrix.add(cells);
    }

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

  static Uint8List encode(
    SpreadsheetTable table, {
    String sheetName = 'Sheet1',
  }) {
    final excel = Excel.createExcel();
    final defaultName = excel.getDefaultSheet();
    if (defaultName != null && defaultName != sheetName) {
      excel.rename(defaultName, sheetName);
    }

    final sheet = excel[sheetName];
    // Clear any starter content from the template sheet.
    if (sheet.maxRows > 0) {
      sheet.removeRow(0);
    }

    for (final row in table.toMatrix(includeHeaders: true)) {
      sheet.appendRow([for (final cell in row) TextCellValue(cell)]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Failed to encode Excel workbook');
    }
    return Uint8List.fromList(bytes);
  }

  static Sheet _resolveSheet(Excel excel, String? sheetName) {
    if (sheetName != null && sheetName.isNotEmpty) {
      if (!excel.tables.containsKey(sheetName)) {
        throw ArgumentError.value(
          sheetName,
          'sheetName',
          'Sheet not found. Available: ${excel.tables.keys.join(', ')}',
        );
      }
      return excel[sheetName];
    }
    final first = excel.tables.keys.firstOrNull;
    if (first == null) {
      throw StateError('Workbook has no sheets');
    }
    return excel[first];
  }

  static String _cellToString(CellValue? value) {
    if (value == null) return '';
    return value.toString();
  }
}
