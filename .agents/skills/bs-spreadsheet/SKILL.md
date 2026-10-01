---
name: bs-spreadsheet
description: >-
  Imports and exports Excel (.xlsx) and pipe-delimited CSV via SpreadsheetIO,
  codecs, and SpreadsheetMapper. Use when picking spreadsheet files, exporting
  tables, mapping rows to models, or working with | CSV / xlsx workflows.
---

# bs-spreadsheet

## Before coding

1. Read [docs/SPREADSHEET.md](../../../docs/SPREADSHEET.md)
2. Use `lib/src/shared/spreadsheet/` — do not call `excel` / `csv` APIs from features directly

## Checklist

### Import

1. `final table = await SpreadsheetIO.instance.pickAndDecode();`
2. If `null` → user cancelled
3. `SpreadsheetMapper.mapRows` with `requiredHeaders` + `fromRow`
4. Surface `result.items` and per-row `result.errors` in UI

### Export

1. Build table with `SpreadsheetMapper.toTable` (headers + `toRow`)
2. `exportAndShare` with `SpreadsheetKind.excel` or `SpreadsheetKind.pipeCsv`
3. Use `exportToTemp` when share sheet is not needed

## Do not

- Build a full preview / column-mapping wizard in shared code
- Commit real credential-bearing spreadsheets
- Parse business JSON inside codecs

## Validate

- `flutter analyze`
- Codec / mapper tests under `test/src/shared/spreadsheet/` when changing shared IO
