import 'package:bs_mobile/src/shared/spreadsheet/csv_codec.dart';
import 'package:bs_mobile/src/shared/spreadsheet/spreadsheet_format.dart';
import 'package:bs_mobile/src/shared/spreadsheet/spreadsheet_table.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CsvCodec', () {
    test('round-trip with pipe delimiter and headers', () {
      const table = SpreadsheetTable(
        headers: ['code', 'name', 'qty'],
        rows: [
          ['A1', 'Apple', '10'],
          ['B2', 'Banana', '5'],
        ],
      );

      final text = CsvCodec.encode(table);
      expect(text.split('\n').first, 'code|name|qty');
      expect(text, contains('A1|Apple|10'));

      final decoded = CsvCodec.decode(text);
      expect(decoded.headers, ['code', 'name', 'qty']);
      expect(decoded.rows, [
        ['A1', 'Apple', '10'],
        ['B2', 'Banana', '5'],
      ]);
    });

    test('empty cells stay as empty strings', () {
      const text = 'a|b|c\n1||3\n';
      final decoded = CsvCodec.decode(text);
      expect(decoded.rows.single, ['1', '', '3']);
    });

    test('quotes cell that contains delimiter', () {
      const table = SpreadsheetTable(
        headers: ['a', 'b'],
        rows: [
          ['x|y', 'z'],
        ],
      );

      final text = CsvCodec.encode(table);
      expect(text, contains('"x|y"'));
      final decoded = CsvCodec.decode(text);
      expect(decoded.rows.single, ['x|y', 'z']);
    });

    test('custom delimiter', () {
      const format = CsvFormat(delimiter: ',');
      const table = SpreadsheetTable(
        headers: ['a', 'b'],
        rows: [
          ['1', '2'],
        ],
      );
      final text = CsvCodec.encode(table, format: format);
      expect(text.split('\n').first, 'a,b');
      final decoded = CsvCodec.decode(text, format: format);
      expect(decoded.headers, ['a', 'b']);
    });

    test('asMaps maps headers to cells', () {
      const table = SpreadsheetTable(
        headers: ['code', 'name'],
        rows: [
          ['A', 'Alpha'],
          ['B'], // short row
        ],
      );
      expect(table.asMaps, [
        {'code': 'A', 'name': 'Alpha'},
        {'code': 'B', 'name': ''},
      ]);
    });
  });
}
