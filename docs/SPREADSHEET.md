# Spreadsheet Import / Export — Excel + CSV (pipe)

คู่มือ `SpreadsheetIO` + codecs  
**logic กลาง / หน้าตาอยู่ที่ feature** (แนวเดียวกับ [PAGING.md](PAGING.md))

---

## สารบัญ

1. [ภาพรวม](#ภาพรวม)
2. [ไฟล์ที่เกี่ยวข้อง](#ไฟล์ที่เกี่ยวข้อง)
3. [SpreadsheetTable](#spreadsheettable)
4. [Import](#import)
5. [Export / Share](#export--share)
6. [Mapper (model ↔ rows)](#mapper-model--rows)
7. [CSV delimiter `|`](#csv-delimiter-)
8. [สิ่งที่ไม่ได้อยู่ในตัวกลาง](#สิ่งที่ไม่ได้อยู่ในตัวกลาง)
9. [Platform notes](#platform-notes)
10. [Checklist](#checklist)

---

## ภาพรวม

```
Feature
  ├── ปุ่ม Import / Export          ← คุณจัด UI
  ├── OrderSheetMapper              ← คุณแปลง model
  └── SpreadsheetIO                 ← pick / encode / share
        ├── ExcelCodec  (.xlsx)
        └── CsvCodec    (| CSV)
              └── SpreadsheetTable
```

| ชั้น | ทำอะไร | ไม่ทำ |
| --- | --- | --- |
| Codec | bytes/text ↔ `SpreadsheetTable` | ไม่รู้ domain model |
| `SpreadsheetIO` | เลือกไฟล์, เขียน temp, แชร์ | ไม่ validate business |
| Feature mapper | `List<T>` ↔ rows + รวบ error รายแถว | ไม่เรียก `excel`/`csv` โดยตรง |

---

## ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | บทบาท |
| --- | --- |
| `lib/src/shared/spreadsheet/spreadsheet_table.dart` | headers + rows |
| `lib/src/shared/spreadsheet/spreadsheet_format.dart` | `CsvFormat`, `SpreadsheetKind` |
| `lib/src/shared/spreadsheet/excel_codec.dart` | `.xlsx` |
| `lib/src/shared/spreadsheet/csv_codec.dart` | CSV (default `\|`) |
| `lib/src/shared/spreadsheet/spreadsheet_io.dart` | pick / export / share |
| `lib/src/shared/spreadsheet/spreadsheet_mapper.dart` | `mapRows` / `toTable` |

```dart
import 'package:bs_mobile/src/shared/spreadsheet/index.dart';
// หรือ
import 'package:bs_mobile/src/shared/index.dart';
```

Dependencies: `excel`, `csv`, `file_picker` (git / v12 beta — รองรับ `win32` ^6), `share_plus`  
> `file_picker` 11.x บน pub.dev ยังผูก `win32` ^5 ทำให้ conflict กับ `device_info_plus` / `package_info_plus` / `share_plus` (win32 ^6) และพังตอน compile Windows — โปรเจกต์จึงชี้ git commit ชั่วคราวจนกว่า v12 จะขึ้น pub.dev

---

## SpreadsheetTable

```dart
class SpreadsheetTable {
  final List<String> headers;
  final List<List<String>> rows;
  List<Map<String, String>> get asMaps; // header → cell
}
```

ทุก cell เป็น `String` — แปลง type ที่ mapper ของ feature

---

## Import

```dart
final table = await SpreadsheetIO.instance.pickAndDecode();
if (table == null) return; // user cancel

final result = SpreadsheetMapper.mapRows<Order>(
  table,
  requiredHeaders: const ['code', 'qty'],
  fromRow: (row) {
    final qty = int.tryParse(row['qty'] ?? '');
    if (qty == null) throw const FormatException('qty must be int');
    return Order(code: row['code']!, qty: qty);
  },
);

// result.items  = แถวที่ผ่าน
// result.errors = แถวที่พัง (rowIndex 1-based ของ data; 0 = หัวตาราง/คอลัมน์)
```

Decode ตรง ๆ (ไม่ผ่าน picker):

```dart
final table = CsvCodec.decode(fileText);
final table = ExcelCodec.decode(bytes);
```

---

## Export / Share

```dart
final table = SpreadsheetMapper.toTable<Order>(
  headers: const ['code', 'qty'],
  items: orders,
  toRow: (o) => [o.code, '${o.qty}'],
);

// Excel (.xlsx) + share sheet
await SpreadsheetIO.instance.exportAndShare(
  table,
  fileNameWithoutExt: 'orders',
  kind: SpreadsheetKind.excel,
);

// Pipe CSV + share
await SpreadsheetIO.instance.exportAndShare(
  table,
  fileNameWithoutExt: 'orders',
  kind: SpreadsheetKind.pipeCsv,
);

// เขียน temp อย่างเดียว (ไม่แชร์)
final file = await SpreadsheetIO.instance.exportToTemp(
  table,
  fileNameWithoutExt: 'orders',
  kind: SpreadsheetKind.pipeCsv,
);
```

---

## Mapper (model ↔ rows)

- `SpreadsheetMapper.mapRows` — ไม่ throw ทั้งไฟล์; รวบ `SpreadsheetRowError`
- `SpreadsheetMapper.toTable` — ประกอบ headers + rows จาก list โมเดล

แนะนำให้ feature มี class เล็ก ๆ เช่น `OrderSheetMapper` ที่ห่อ headers / fromRow / toRow ไว้ที่เดียว

---

## CSV delimiter `|`

Default:

```dart
const CsvFormat(delimiter: '|'); // SpreadsheetFormats.pipeCsv
```

ตัวอย่างไฟล์:

```text
code|name|qty
A1|Apple|10
B2|Banana|5
```

ถ้า cell มี `|` ข้างใน — encoder จะ quote อัตโนมัติ (`QuoteMode.necessary`)

บังคับ quote ทุกช่อง:

```dart
CsvCodec.encode(table, format: const CsvFormat(shouldQuote: true));
```

เปลี่ยน delimiter:

```dart
CsvCodec.encode(table, format: const CsvFormat(delimiter: ','));
```

---

## สิ่งที่ไม่ได้อยู่ในตัวกลาง

- หน้า preview / column-mapping wizard
- `.xls` เก่า — รองรับแค่ `.xlsx`
- Google Sheets / cloud sync
- Theme / ปุ่ม Import-Export UI

---

## Platform notes

- **Android:** `file_picker` ใช้ SAF — โดยทั่วไปไม่ต้องขอ storage กว้างสำหรับ pick
- **iOS:** เปิดเอกสารผ่าน picker ได้; export ผ่าน share sheet
- **Export path:** เขียนใต้ `getTemporaryDirectory()` แล้ว `SharePlus.share`
- อย่า commit ไฟล์ทดสอบที่มีข้อมูลจริงลง git

---

## Checklist

- [ ] Import: `pickAndDecode` → `mapRows` → โชว์ `errors` ให้ user
- [ ] Export: `toTable` → `exportAndShare` (เลือก excel หรือ pipeCsv)
- [ ] ตรวจ required columns ใน mapper
- [ ] อย่า parse JSON/business ใน codec
