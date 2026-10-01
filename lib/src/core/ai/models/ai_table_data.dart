import 'dart:convert';

class AiTableData {
  const AiTableData({required this.headerLabels, required this.rows});

  final List<String> headerLabels;
  final List<List<String>> rows;

  bool get isEmpty => headerLabels.isEmpty || rows.isEmpty;
}

String sanitizeExportText(dynamic value) {
  final text = value?.toString() ?? '';
  return text
      .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
      .replaceAll(RegExp(r'`(.+?)`'), r'$1')
      .replaceAll(RegExp(r'\[(.+?)\]\((.+?)\)'), r'$1')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .trim();
}

String toDisplayCellText(dynamic value) {
  if (value == null) return '';
  if (value is String) return sanitizeExportText(value);
  if (value is Map || value is List) {
    try {
      return value.toString();
    } catch (_) {
      return '';
    }
  }
  return value.toString();
}

dynamic getReportCellValue(Map<String, dynamic> row, String column) {
  if (row.containsKey(column)) return row[column];

  for (final key in row.keys) {
    if (key.toLowerCase() == column.toLowerCase()) {
      return row[key];
    }
  }
  return null;
}

List<dynamic> parseArrayOrEmpty(dynamic value) {
  if (value == null) return const [];
  if (value is List) return value;
  if (value is String) {
    try {
      final parsed = jsonDecode(value);
      return parsed is List ? parsed : const [];
    } catch (_) {
      return const [];
    }
  }
  return const [];
}

Map<String, dynamic> parseObjectOrEmpty(dynamic value) {
  if (value == null) return {};
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

AiTableData? normalizeDataRows(List<Map<String, dynamic>> dataRows) {
  if (dataRows.isEmpty) return null;

  Map<String, dynamic>? firstObjectRow;
  for (final row in dataRows) {
    if (row.isNotEmpty) {
      firstObjectRow = row;
      break;
    }
  }

  if (firstObjectRow == null) return null;

  final columnKeys = firstObjectRow.keys.toList();
  final headerLabels = columnKeys
      .map((key) => sanitizeExportText(key))
      .map((label) => label.isEmpty ? '-' : label)
      .toList();

  if (headerLabels.isEmpty) return null;

  return AiTableData(
    headerLabels: headerLabels,
    rows: dataRows.map((row) {
      return columnKeys
          .map((key) => toDisplayCellText(getReportCellValue(row, key)))
          .toList();
    }).toList(),
  );
}

AiTableData? normalizeReportData(Map<String, dynamic>? reportData) {
  final payload = parseObjectOrEmpty(reportData);
  final rawColumns = payload['columns'] is List
      ? payload['columns'] as List
      : payload['Columns'] is List
      ? payload['Columns'] as List
      : <dynamic>[];
  final rawRows = payload['rows'] is List
      ? payload['rows'] as List
      : payload['Rows'] is List
      ? payload['Rows'] as List
      : <dynamic>[];

  var columns = rawColumns;
  if (columns.isEmpty &&
      rawRows.isNotEmpty &&
      rawRows.first is Map &&
      (rawRows.first as Map).isNotEmpty) {
    columns = (rawRows.first as Map).keys.toList();
  }

  if (columns.isEmpty || rawRows.isEmpty) return null;

  final headerLabels = columns
      .map((column) => sanitizeExportText(column))
      .map((label) => label.isEmpty ? '-' : label)
      .toList();

  final rows = rawRows.map((row) {
    if (row is List) {
      return List.generate(headerLabels.length, (index) {
        return index < row.length ? toDisplayCellText(row[index]) : '';
      });
    }

    if (row is Map) {
      final map = Map<String, dynamic>.from(row);
      return columns
          .map(
            (column) => toDisplayCellText(getReportCellValue(map, '$column')),
          )
          .toList();
    }

    return List.generate(
      headerLabels.length,
      (index) => index == 0 ? toDisplayCellText(row) : '',
    );
  }).toList();

  return AiTableData(headerLabels: headerLabels, rows: rows);
}

AiTableData? normalizePrimaryTableData(
  List<Map<String, dynamic>> dataRows,
  Map<String, dynamic>? reportData,
) {
  return normalizeDataRows(dataRows) ?? normalizeReportData(reportData);
}

List<String>? parseMarkdownTableRow(String line) {
  final trimmed = line.trim();
  if (!trimmed.contains('|')) return null;

  final normalized = trimmed
      .replaceFirst(RegExp(r'^\|'), '')
      .replaceFirst(RegExp(r'\|$'), '');
  final cells = normalized.split('|').map((cell) => cell.trim()).toList();
  if (cells.length < 2) return null;
  return cells;
}

bool isMarkdownSeparatorRow(List<String> cells) {
  return cells.every((cell) => RegExp(r'^:?-{3,}:?$').hasMatch(cell));
}

AiTableData? extractMarkdownTableFromText(String text) {
  final lines = text.split('\n').map((line) => line.trim()).toList();

  for (var i = 0; i < lines.length - 1; i++) {
    final headerCells = parseMarkdownTableRow(lines[i]);
    final separatorCells = parseMarkdownTableRow(lines[i + 1]);

    if (headerCells == null ||
        separatorCells == null ||
        headerCells.length != separatorCells.length ||
        !isMarkdownSeparatorRow(separatorCells)) {
      continue;
    }

    final bodyRows = <List<String>>[];
    var cursor = i + 2;

    while (cursor < lines.length) {
      final rowCells = parseMarkdownTableRow(lines[cursor]);
      if (rowCells == null || rowCells.length != headerCells.length) break;
      bodyRows.add(rowCells);
      cursor++;
    }

    if (bodyRows.isEmpty) continue;

    return AiTableData(
      headerLabels: headerCells.map(sanitizeExportText).toList(),
      rows: bodyRows
          .map((row) => row.map(sanitizeExportText).toList())
          .toList(),
    );
  }

  return null;
}
