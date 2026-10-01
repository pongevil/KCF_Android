import 'package:bs_mobile/src/shared/spreadsheet/spreadsheet_mapper.dart';
import 'package:bs_mobile/src/shared/spreadsheet/spreadsheet_table.dart';
import 'package:flutter_test/flutter_test.dart';

class _Item {
  final String code;
  final int qty;
  _Item(this.code, this.qty);
}

void main() {
  group('SpreadsheetMapper', () {
    test('mapRows collects good items and row errors', () {
      const table = SpreadsheetTable(
        headers: ['code', 'qty'],
        rows: [
          ['A', '1'],
          ['B', 'x'], // bad qty
          ['C', '3'],
        ],
      );

      final result = SpreadsheetMapper.mapRows<_Item>(
        table,
        requiredHeaders: const ['code', 'qty'],
        fromRow: (row) {
          final qty = int.tryParse(row['qty'] ?? '');
          if (qty == null) {
            throw const FormatException('qty must be an integer');
          }
          final code = row['code'] ?? '';
          if (code.isEmpty) {
            throw const FormatException('code is required');
          }
          return _Item(code, qty);
        },
      );

      expect(result.items.map((e) => e.code), ['A', 'C']);
      expect(result.errors, hasLength(1));
      expect(result.errors.single.rowIndex, 2);
      expect(result.errors.single.message, contains('qty'));
    });

    test('missing required headers returns error at row 0', () {
      const table = SpreadsheetTable(
        headers: ['code'],
        rows: [
          ['A'],
        ],
      );

      final result = SpreadsheetMapper.mapRows<_Item>(
        table,
        requiredHeaders: const ['code', 'qty'],
        fromRow: (row) => _Item(row['code']!, 0),
      );

      expect(result.items, isEmpty);
      expect(result.errors.single.rowIndex, 0);
      expect(result.errors.single.message, contains('qty'));
    });

    test('toTable builds headers and rows', () {
      final items = [_Item('A', 1), _Item('B', 2)];
      final table = SpreadsheetMapper.toTable<_Item>(
        headers: const ['code', 'qty'],
        items: items,
        toRow: (item) => [item.code, '${item.qty}'],
      );
      expect(table.headers, ['code', 'qty']);
      expect(table.rows, [
        ['A', '1'],
        ['B', '2'],
      ]);
    });
  });
}
