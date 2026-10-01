import 'package:bs_mobile/src/shared/spreadsheet/excel_codec.dart';
import 'package:bs_mobile/src/shared/spreadsheet/spreadsheet_format.dart';
import 'package:bs_mobile/src/shared/spreadsheet/spreadsheet_table.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExcelCodec', () {
    test('round-trip headers and rows', () {
      const table = SpreadsheetTable(
        headers: ['sku', 'qty'],
        rows: [
          ['SKU-1', '3'],
          ['SKU-2', '7'],
        ],
      );

      final bytes = ExcelCodec.encode(table, sheetName: 'Orders');
      final decoded = ExcelCodec.decode(bytes);

      expect(decoded.headers, ['sku', 'qty']);
      expect(decoded.rows, [
        ['SKU-1', '3'],
        ['SKU-2', '7'],
      ]);
    });

    test('decode by sheet name', () {
      const table = SpreadsheetTable(
        headers: ['id'],
        rows: [
          ['1'],
        ],
      );
      final bytes = ExcelCodec.encode(table, sheetName: 'Data');
      final decoded = ExcelCodec.decode(
        bytes,
        format: const ExcelFormat(sheetName: 'Data'),
      );
      expect(decoded.rows.single, ['1']);
    });
  });
}
