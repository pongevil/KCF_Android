# Barcode Format (2D / GetBarcodeFormat)

Core สำหรับสแกนบาร์โค้ดที่ BE กำหนดโครงสร้างผ่าน `separator` + `tag_sequence` + `tag_name`

## API

`GET ConfigApp/GetBarcodeFormat`

Response จริง (`BarcodeFormatResponse`) — **flat `fields[]`**, ไม่มี `items[]`:

```json
{
  "separator": "|",
  "fields": [
    {
      "tag_function": "allfunction",
      "tag_name": "item_number",
      "tag_sequence": 1,
      "required": "YES",
      "data_type": "string",
      "format": null
    },
    {
      "tag_function": "allfunction",
      "tag_name": "expirydate",
      "tag_sequence": 2,
      "required": "YES",
      "data_type": "string",
      "format": null
    }
  ],
  "message_code": "0",
  "is_success": true,
  "message": "SUCCESS",
  "total_records": 0,
  "total_pages": 0
}
```

| Field | หมายเหตุ |
| --- | --- |
| `separator` | ระดับราก — ใช้ร่วมทุก `tag_function` |
| `fields[].tag_function` | อยู่บนแต่ละ field (ไม่ใช่ root) |
| `fields[].required` | `"YES"` / `"NO"` (string) |
| `fields[].tag_name` | exact หลัง `trim()` — ไม่มี alias |

แอป **group** `fields` ตาม `tag_function` → `Map<tagFunction, BarcodeFormatConfig>`  
`is_success != true` → ไม่ cache / ไม่ใช้ config  
กลุ่มที่ validate ไม่ผ่าน → ข้าม (ไม่ทับ LKG ทั้งชุดถ้าได้ list ว่าง)

### Cache (ไม่ยิง API ทุกรอบสแกน)

| ชั้น | ที่เก็บ |
| --- | --- |
| Memory | TTL 12 ชม. ใน `BarcodeFormatService` |
| Disk LKG | `barcode_format/all.json` (configs ที่ group แล้ว) |

Login → `prefetchAll()`; offline / API พัง → ใช้ LKG

## วิธีใช้ในหน้า (แนะนำ)

ใช้ **`CustomBarcodeTextField`** — รองรับทั้ง:

- พิมพ์ / ยิง HID scanner แล้ว Enter (`onFieldSubmitted` → `applyRaw`)
- กดไอคอนกล้อง prefix (`scanAndApply`)

```dart
import 'package:bs_mobile/src/core/barcode/barcode_field_key.dart';
import 'package:bs_mobile/src/shared/to_display_show.dart';
import 'package:bs_mobile/src/shared/ui/widgets/custom_barcode_text_field.dart';

CustomBarcodeTextField(
  controller: _batchController,
  focusNode: _batchFocus,
  nextFocusNode: _expiryFocus,
  labelText: 'Batch',
  tagFunction: BarcodeTagFunction.deliveryOrder,
  entryField: BarcodeFieldKey.batchNumber,
  apply: {
    BarcodeFieldKey.batchNumber: (v) {
      _batchController.text = v.stringValue ?? '';
    },
    BarcodeFieldKey.expiryDate: (v) {
      final date = v.requireDate();
      _expiryController.text = ToDisplayShow.toDisplayDate(date);
    },
  },
);
```

Page เป็นเจ้าของ `FocusNode` และ `dispose` เอง

## Helper API (ใช้เมื่อไม่ผ่าน widget)

| Method | ใช้เมื่อ |
| --- | --- |
| `BarcodeScanHelper.applyRaw` | ข้อความจาก TextField / HID Enter |
| `BarcodeScanHelper.scanAndApply` | เปิดกล้อง |
| `BarcodeScanHelper.resolveAndApply` | unit test / path ขั้นต่ำ |

```dart
import 'package:bs_mobile/src/shared/camera/barcode_scan_helper.dart';

await BarcodeScanHelper.applyRaw(
  raw: value,
  tagFunction: BarcodeTagFunction.deliveryOrder,
  entryField: BarcodeFieldKey.batchNumber,
  apply: _barcodeApply,
);
```

## สัญญา tag_name (สำคัญ)

- Key ใน `apply` = `tag_name` จาก BE **exact** หลัง `trim()` เท่านั้น
- **ห้าม** alias map / snake-case rewrite / synonym (`expirydate` ≠ `expiry_date`)
- Constants ใน [`barcode_field_key.dart`](../lib/src/core/barcode/barcode_field_key.dart) = ชื่อ BE จริง

| สแกน | ผล |
| --- | --- |
| 2D สำเร็จ | เติมทุกช่องที่ลงทะเบียนใน `apply` และมีค่า |
| 1D | ใส่เฉพาะ `entryField` — ไม่แตะช่องอื่น |
| 2D แต่ไม่มี config ของ `tagFunction` | fail closed — ห้ามยัด raw ทั้งก้อน |

`entryField` **ต้อง** อยู่ใน `apply` เสมอ (ไม่อยู่ → `ArgumentError`)

## ไฟล์หลัก

| Path | บทบาท |
| --- | --- |
| `lib/src/core/barcode/` | model, validator, repository, service, parser |
| `lib/src/shared/camera/barcode_scan_helper.dart` | `applyRaw` / `scanAndApply` + alert |
| `lib/src/shared/ui/widgets/custom_barcode_text_field.dart` | UI ช่อง barcode |
| `lib/src/global/mockdata/barcode_format_all_mock.json` | mock ตอน `useMockConfig = true` |
