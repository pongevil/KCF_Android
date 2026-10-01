import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'csv_codec.dart';
import 'excel_codec.dart';
import 'spreadsheet_format.dart';
import 'spreadsheet_table.dart';

/// Pick files and export/share spreadsheets. UI-agnostic.
class SpreadsheetIO {
  SpreadsheetIO._();
  static final SpreadsheetIO instance = SpreadsheetIO._();

  /// Opens the platform file picker and decodes `.xlsx` / `.csv` / `.txt`.
  /// Returns `null` when the user cancels.
  Future<SpreadsheetTable?> pickAndDecode({
    List<SpreadsheetKind> allow = const [
      SpreadsheetKind.excel,
      SpreadsheetKind.pipeCsv,
    ],
    CsvFormat csvFormat = SpreadsheetFormats.pipeCsv,
    ExcelFormat excelFormat = SpreadsheetFormats.excelXlsx,
    bool firstRowIsHeader = true,
  }) async {
    final extensions = <String>{};
    for (final kind in allow) {
      switch (kind) {
        case SpreadsheetKind.excel:
          extensions.add('xlsx');
        case SpreadsheetKind.pipeCsv:
          extensions
            ..add('csv')
            ..add('txt');
      }
    }

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions.toList(growable: false),
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final name = (file.name).toLowerCase();
    final bytes = await _readBytes(file);
    if (bytes == null) {
      throw StateError('Could not read selected file: ${file.name}');
    }

    if (name.endsWith('.xlsx')) {
      return ExcelCodec.decode(
        bytes,
        format: excelFormat,
        firstRowIsHeader: firstRowIsHeader,
      );
    }

    if (name.endsWith('.csv') || name.endsWith('.txt')) {
      return CsvCodec.decode(
        utf8.decode(bytes),
        format: csvFormat,
        firstRowIsHeader: firstRowIsHeader,
      );
    }

    throw UnsupportedError('Unsupported file type: ${file.name}');
  }

  /// Encodes [table], writes under the temp directory, then opens the share sheet.
  Future<File> exportAndShare(
    SpreadsheetTable table, {
    required String fileNameWithoutExt,
    SpreadsheetKind kind = SpreadsheetKind.excel,
    CsvFormat csvFormat = SpreadsheetFormats.pipeCsv,
    String excelSheetName = 'Sheet1',
  }) async {
    final file = await exportToTemp(
      table,
      fileNameWithoutExt: fileNameWithoutExt,
      kind: kind,
      csvFormat: csvFormat,
      excelSheetName: excelSheetName,
    );

    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    return file;
  }

  /// Encodes [table] to a temp file (no share sheet).
  Future<File> exportToTemp(
    SpreadsheetTable table, {
    required String fileNameWithoutExt,
    SpreadsheetKind kind = SpreadsheetKind.excel,
    CsvFormat csvFormat = SpreadsheetFormats.pipeCsv,
    String excelSheetName = 'Sheet1',
  }) async {
    final safeName = fileNameWithoutExt.trim().isEmpty
        ? 'export'
        : fileNameWithoutExt.trim();
    final dir = await getTemporaryDirectory();

    switch (kind) {
      case SpreadsheetKind.excel:
        final bytes = ExcelCodec.encode(table, sheetName: excelSheetName);
        final file = File('${dir.path}${Platform.pathSeparator}$safeName.xlsx');
        await file.writeAsBytes(bytes, flush: true);
        return file;
      case SpreadsheetKind.pipeCsv:
        final text = CsvCodec.encode(table, format: csvFormat);
        final file = File('${dir.path}${Platform.pathSeparator}$safeName.csv');
        await file.writeAsString(text, encoding: utf8, flush: true);
        return file;
    }
  }

  Future<Uint8List?> _readBytes(PlatformFile file) async {
    try {
      return await file.readAsBytes();
    } catch (_) {
      final path = file.path;
      if (path == null) return null;
      return File(path).readAsBytes();
    }
  }
}
