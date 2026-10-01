# Shared Widgets Guide

คู่มือ widget กลางใน `lib/src/shared/` ของ BS-Mobile Flutter Template — สำหรับ dev และ AI ตอนทำ UI

widget และตัวอย่างในเอกสารเป็น reusable baseline สำหรับโปรเจคที่นำ template ไป Duplicate/Clone ต่อ

กฎสี / theme: [README § Theme System](../README.md#theme-system) · กฎ BLoC + alert: [BLOC_PATTERN.md](BLOC_PATTERN.md)

---

## สารบัญ

1. [ภาพรวม](#ภาพรวม)
2. [กฎ — ปรับก่อนสร้างใหม่เสมอ](#กฎ--ปรับก่อนสร้างใหม่เสมอ)
3. [Shared helpers, models และข้อความ UI](#shared-helpers-models-และข้อความ-ui)
4. [Dropdown — เลือกแบบไหน](#dropdown--เลือกแบบไหน)
5. [ListView + Paging](#listview--paging)
6. [Spreadsheet Import / Export](#spreadsheet-import--export)
7. [ฟอร์มและปุ่ม](#ฟอร์มและปุ่ม)
8. [Dialog และ soft keyboard](#dialog-และ-soft-keyboard)
9. [Layout / การ์ด](#layout--การ์ด)
10. [Loading, Alert, Skeleton](#loading-alert-skeleton)
11. [กล้องและสแกน](#กล้องและสแกน)
12. [หน้า shared](#หน้า-shared)
13. [Formatters (UI)](#formatters-ui)

---

## ภาพรวม

Reuse จาก `lib/src/shared/` ก่อนสร้าง widget ใหม่ใน feature

```dart
import 'package:bs_mobile/src/shared/ui/widgets/<file>.dart';
import 'package:bs_mobile/src/shared/ui/notification/custom_show_alert.dart';
import 'package:bs_mobile/src/shared/camera/camera_service.dart';
```

### โครงสร้าง `lib/src/shared/`

```
shared/
├── camera/
│   ├── camera_service.dart       # จุดเข้าเดียว — takePicture / scanBarcode
│   ├── photo_capture_page.dart
│   ├── barcode_scanner_page.dart
│   └── camera_image_utils.dart
├── paging/                       # PagedResult + PagedListController — docs/PAGING.md
├── spreadsheet/                  # Excel + CSV(|) — docs/SPREADSHEET.md
├── ui/
│   ├── notification/
│   │   └── custom_show_alert.dart
│   ├── pages/
│   │   ├── coming_soon_page.dart
│   │   └── not_found_page.dart
│   ├── paging/                   # PagedListView shell
│   └── widgets/
└── to_display_show.dart          # format วันที่ / ค่าว่าง → "-" (แสดง UI)
```

---

## Shared helpers, models และข้อความ UI

ก่อนสร้าง widget, helper/formatter หรือ Model ใหม่ ให้ค้นหาใน `shared/`,
`core/helpers/`, `global/models/` และ feature ที่เกี่ยวข้องก่อนเสมอ

- ใช้หรือขยาย helper กลางสำหรับ parse, rounding และ format ตัวเลข/วันที่
- ใช้ Model เดิมภายใน API contract เดียวกัน แทนการสร้าง `DataModel` หรือ `ItemModel` ซ้ำ
- `Request` และ `Response` แยกกันได้เมื่อเป็นคนละ contract
- `List<T>` ใช้ Model รายการเดิมได้ เช่น `List<UserResponse>`; wrapper แยกได้เมื่อมี pagination/metadata
- UI model แยกได้เฉพาะเมื่อมี state/data ที่เป็นของ UI จริง ๆ

ข้อความ UI แบบ static ต้อง resolve ด้วย `context.tr` ก่อนส่งเข้า `AppText` หรือ property อื่น:

```dart
AppText(
  context.tr(
    'product.quantity',
    fallback: 'จำนวน',
  ),
)
```

ใช้กฎเดียวกันกับ label, hint, button, validation, dialog, snackbar, tooltip,
empty state และ loading copy โดยตั้ง key เป็น `<page-or-feature>.<semantic_name>`
เช่น `login.submit` หรือ `common.cancel` ดูรายละเอียดที่ [LOCALE.md](LOCALE.md)

ไม่ต้องแปล route/API key, enum/code, asset path, log, test key หรือข้อมูล dynamic
จาก server โดยตรง

---

## กฎ — ปรับก่อนสร้างใหม่เสมอ

> **ห้ามสร้าง** `CustomTextField`, Dropdown, `CustomButton` ซ้ำใน `features/` ไม่ว่ากรณีใด

### Decision tree

```
ต้องการ widget ใหม่?
    │
    ▼
มี shared widget ใกล้เคียงในเอกสารนี้?
    ├── มี → parameter ที่มีอยู่รองรับได้ไหม?
    │         ├── ได้  → ใช้เลย ✓
    │         └── ไม่ได้ → เพิ่ม parameter ใหม่ใน shared widget (+ default value) ✓
    │                       ห้ามสร้าง widget ซ้ำใน features/ ✗
    └── ไม่มีเลย → สร้างใน shared/ui/widgets/ ✓
                   (widget เฉพาะ domain จริง ๆ → features/<name>/presentation/widgets/ ✓)
```

### วิธีเพิ่ม parameter ใน shared widget

เมื่อ parameter ที่ต้องการยังไม่มี ให้เพิ่มใน shared widget โดยตรง พร้อม **default value** เพื่อไม่ให้ผู้ใช้เดิมพัง:

```dart
// ตัวอย่าง: เพิ่ม maxLength ใน CustomTextField
class CustomTextField extends StatefulWidget {
  final TextEditingController controller; // ← parameter เดิมที่ required
  final int? maxLength;       // ← เพิ่มใหม่ (nullable = optional, default null)
  final String? labelText;
  // ... parameter เดิม

  const CustomTextField({
    required this.controller,
    this.maxLength,           // ← ไม่ required — ผู้ใช้เดิมไม่ต้องแก้ไข
    this.labelText,
    // ...
  });
}
```

จากนั้นใช้ใน feature ได้เลย:

```dart
// ✓ ถูก
CustomTextField(
  controller: _skuController,
  labelText: context.tr('product.sku', fallback: 'รหัสสินค้า'),
  maxLength: 10,
)

// ✗ ห้าม — อย่าสร้าง TextField ใหม่ใน feature
TextField(maxLength: 10, decoration: InputDecoration(...))
```

### ตาราง parameter ที่ปรับได้บน widget หลัก

| Widget                      | Parameter ที่รองรับอยู่แล้ว                                                                                                                                                                                  |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `CustomTextField`           | `labelText`, `hintText`, `prefixIcon`, `suffixIcon`, `keyboardType`, `validator`, `maxLines`, `readOnly`, `isPassword`, `enableDatePicker`, `onDateSelected`, `controller`, `focusNode`, `onFieldSubmitted` |
| `CustomButton`              | `variant` (`primary`/`success`/`danger`/`warning`/`disabled`), `text`, `icon`, `onPressed`, `backgroundColor`, `textColor`, `width`, `height`                                                               |
| `Customdropdown`            | `items`, `label`, `hint`, `validator`, `value`, `onChanged`, `itemToString`, `focusNode`, `enabled`                                                                                                         |
| `CustomDropdownSearch`      | `items`, `label`, `hint`, `itemToString`, `onChanged`, `searchHint`, `focusNode`, `nextFocusNode`, `value`, `pageSize`, `onLoadPage`                                                                        |
| `CustomDropdownSearchModal` | `items`, `label`, `hint`, `itemToString`, `onChanged`, `searchHint`, `focusNode`, `nextFocusNode`, `value`, `pageSize`, `onLoadPage`                                                                        |
| `CustomCard`                | `title`, `subtitle`, `subtitleTrailing`, `icon`, `headerTrailing`, `child`, `padding`                                                                                                                        |
| `CustomInfoBox`             | `label`, `value`, `color` (semantic token)                                                                                                                                                                   |
| `CustomGradientAppBar`      | `title`, `variant`, `actions`, `leading`                                                                                                                                                                     |
| `CustomQtyStepper`          | `controller`, `onDecrement`, `onIncrement`, `label`, `useQuantityConfig` (default `true`), `inputFormatters`, `allowDecimal` (เมื่อ `useQuantityConfig: false`)                                               |
| `CustomBarcodeTextField`    | `controller`, `focusNode`, `nextFocusNode`, `tagFunction`, `entryField`, `apply`, scan prefix / Enter → `BarcodeScanHelper`                                                                                    |

> parameter ในตารางนี้อาจมีมากกว่าที่ระบุ — ตรวจสอบไฟล์ widget โดยตรงก่อนเพิ่มใหม่

---

## Dropdown — เลือกแบบไหน

| Widget                        | ไฟล์                                | ใช้เมื่อ                              | หมายเหตุ                                                                         |
| ----------------------------- | ----------------------------------- | ------------------------------------- | -------------------------------------------------------------------------------- |
| **Customdropdown**            | `custom_dropdown.dart`              | รายการสั้น (< ~20), ไม่ต้องค้นหา      | `DropdownButtonFormField` + generic `T`                                          |
| **CustomDropdownSearch**      | `custom_dropdown_search.dart`       | รายการกลาง, ค้นหา **inline** ใน field | `itemToString`, `focusNode` / `nextFocusNode`, auto-select เมื่อพิมพ์ตรง barcode |
| **CustomDropdownSearchModal** | `custom_dropdown_search_modal.dart` | รายการยาว, UX มือถือ                  | เปิด **bottom sheet** ค้นหาเต็มจอ + รองรับ `onLoadPage`                         |

**แนวทางเลือก**

```
รายการสั้น fixed     → Customdropdown
ค้นหา + ฟอร์มหลายช่อง → CustomDropdownSearch (keyboard flow)
รายการยาว / master   → CustomDropdownSearchModal
โหลด generic model จาก API / paging → CustomDropdownSearch หรือ CustomDropdownSearchModal + onLoadPage
```

ตัวอย่าง `CustomDropdownSearch` (model):

```dart
CustomDropdownSearch<WarehouseModel>(
  label: context.tr('warehouse.label', fallback: 'คลัง'),
  hint: context.tr('warehouse.select', fallback: 'เลือกคลัง'),
  items: warehouses,
  value: selected,
  itemToString: (w) => w.name,
  onChanged: (w) => setState(() => selected = w),
  searchHint: context.tr('warehouse.search', fallback: 'ค้นหาคลัง...'),
)
```

> ชื่อ class: `Customdropdown` (ตัว **d** เล็กในไฟล์ `custom_dropdown.dart`)

---

## ListView + Paging

หน้า list ยาว + infinite scroll ใช้ **`PagedListController` + `PagedListView`**

- logic กลาง: page / hasMore / loadMore / refresh / `searchText`
- หน้าตา: feature ส่ง `itemBuilder` + empty / error / footer เอง
- **ไม่มีช่องค้นหาในตัวกลาง** — วาง `CustomTextField` นอก list แล้วเรียก `controller.setSearch(...)`

คู่มือเต็ม + ตัวอย่าง search: **[PAGING.md](PAGING.md)**

---

## Spreadsheet Import / Export

Import / export `.xlsx` และ CSV คั่นด้วย `|` ใช้ **`SpreadsheetIO` + codecs**

- pick ไฟล์ → `SpreadsheetTable`
- export + share จาก temp
- map เป็น model ด้วย `SpreadsheetMapper.mapRows` (error รายแถว)

คู่มือเต็ม: **[SPREADSHEET.md](SPREADSHEET.md)**

---

## ฟอร์มและปุ่ม

| Widget                     | ไฟล์                     | ใช้เมื่อ                                                                         |
| -------------------------- | ------------------------ | -------------------------------------------------------------------------------- |
| **CustomButton**           | `custom_button.dart`     | `CustomButtonVariant`: `primary` / `success` / `danger` / `warning` / `disabled` |
| **CustomTextField**        | `custom_text_field.dart` | text, password (`isPassword`), multiline, validator                              |
| **CustomTextField** (date) | เดียวกัน                 | `enableDatePicker: true` + `onDateSelected`                                      |
| **PickDateWidget**         | `pick_date_widget.dart`  | ปุ่มเลือกวันที่ standalone                                                       |
| **CustomQtyStepper**       | `custom_qty_stepper.dart`| ช่อง quantity — minus / text field / plus (อ่าน config จาก AppConfig)            |
| **CustomBarcodeTextField** | `custom_barcode_text_field.dart` | ช่อง barcode — Enter/HID + ปุ่มกล้อง (GetBarcodeFormat)                    |
| **AppText**                | `app_text.dart`          | ข้อความมาตรฐานที่รองรับ style, สี, ขนาด, alignment และ padding                  |

```dart
CustomButton(
  text: context.tr('common.save', fallback: 'บันทึก'),
  variant: CustomButtonVariant.primary,
  icon: Icons.save_rounded,
  onPressed: _onSubmit,
)
```

```dart
// text input ทั่วไป
CustomTextField(
  labelText: context.tr('product.name', fallback: 'ชื่อสินค้า'),
  hintText: context.tr('product.name_hint', fallback: 'กรอกชื่อสินค้า'),
  controller: _nameController,
  validator: (v) => v!.isEmpty
      ? context.tr('product.name_required', fallback: 'กรุณากรอกชื่อ')
      : null,
)

// password
CustomTextField(
  labelText: context.tr('login.password', fallback: 'รหัสผ่าน'),
  controller: _passwordController,
  isPassword: true,
)

// date picker
CustomTextField(
  labelText: context.tr('common.date', fallback: 'วันที่'),
  controller: _dateController,
  enableDatePicker: true,
  onDateSelected: (date) => setState(() => _date = date),
)

// multiline
CustomTextField(
  labelText: context.tr('common.remark', fallback: 'หมายเหตุ'),
  maxLines: 4,
  controller: _remarkController,
)
```

### Focus — คิดทุกครั้งที่มีช่องกรอก

หน้าที่มี `CustomTextField` / `TextField` / dropdown ค้นหา **ต้องออกแบบ focus** ไม่ปล่อย default อย่างเดียว (สำคัญบน PDA + สแกน)

1. สร้าง `FocusNode` ต่อช่องใน `State` → `dispose()` ทุกตัว
2. ส่ง `focusNode:` เข้า `CustomTextField` / `CustomDropdownSearch`
3. หลายช่อง: ใช้ `nextFocusNode` (dropdown search) หรือ `onFieldSubmitted` + `textInputAction: TextInputAction.next` แล้ว `nextFocus.requestFocus()`
4. Soft keyboard กลาง: `SoftKeyboardController` (`lib/src/shared/ui/keyboard/`) — สแกนอาจซ่อน keyboard; ช่องที่ต้องพิมพ์ (เช่น qty) ใช้ force-keyboard ตอน focus ตาม pattern ใน widget
5. อ้างอิง: `features/auth/presentation/pages/login_page.dart` (`_usernameFocus` / `_passwordFocus`)

### CustomQtyStepper — quantity

ช่องกรอกจำนวนใน business feature — default `useQuantityConfig: true` ใช้ `QuantityConfig.inputPattern` จาก `AppConfigService` อัตโนมัติ (ไม่ต้องส่ง `inputFormatters` เอง)

รายละเอียด config: [APP_CONFIG.md](APP_CONFIG.md)

```dart
import 'package:bs_mobile/src/core/helpers/quantity_formatter.dart';
import 'package:bs_mobile/src/shared/ui/widgets/custom_qty_stepper.dart';

CustomQtyStepper(
  label: context.tr('product.quantity', fallback: 'จำนวน'),
  controller: _qtyController,
  onDecrement: () => _setQty(_qty - 1),
  onIncrement: () => _setQty(_qty + 1),
  onChanged: (_) => _syncQtyFromField(),
)
```

Parent รับผิดชอบ logic +/- และ format ค่า:

```dart
void _setQty(num value) {
  final rounded = QuantityFormatter.roundForApi(value);
  _qty = rounded;
  _qtyController.text = QuantityFormatter.formatInput(rounded);
}
```

| Parameter | ค่า default | หมายเหตุ |
| --------- | ----------- | -------- |
| `useQuantityConfig` | `true` | อ่าน `inputPattern` + keyboard จาก AppConfig |
| `allowDecimal` | `false` | ใช้เมื่อ `useQuantityConfig: false` เท่านั้น |
| `inputFormatters` | `null` | override formatter เอง (escape hatch) |

---

## Dialog และ soft keyboard

เปิด bottom sheet ผ่าน **`showCustomModalBottomSheet<T>()`** แทนการเรียก
`showModalBottomSheet` โดยตรง ตัวกลางกำหนด `isScrollControlled`, พื้นหลังโปร่งใส,
`AnimatedPadding` จาก `MediaQuery.viewInsetsOf(context).bottom`,
`SafeArea(top: false)` และปิด keyboard เมื่อแตะพื้นที่ว่างหรือลาก scroll

```dart
final result = await showCustomModalBottomSheet<FormResult>(
  context: context,
  builder: (_) => const EditorSheet(),
);
```

กฎสำหรับ modal หรือ dialog ที่มีช่องกรอก:

1. เนื้อหาต้องเลื่อนได้ด้วย `SingleChildScrollView`, `ListView` หรือ `DraggableScrollableSheet`
2. `DraggableScrollableSheet` ต้องส่ง `scrollController` จาก builder ให้ scrollable ภายใน
3. ห้ามใช้ `Column` ที่สูงตามเนื้อหาอย่างเดียวโดยไม่มี scrollable ครอบ
4. ทุกช่องต้องมี `FocusNode` ที่สร้างและ dispose ใน `State` พร้อมออกแบบ next-field focus
5. ช่องที่ focus และปุ่มบันทึก/ยืนยันต้องเข้าถึงได้เมื่อ keyboard เปิด
6. อย่าเพิ่ม `viewInsets.bottom` ซ้ำใน content เพราะ helper กลางจัดการให้แล้ว
7. ห้ามแก้ด้วยความสูง hardcode สำหรับโทรศัพท์รุ่นใดรุ่นหนึ่ง

สำหรับ `Dialog` / `AlertDialog` กลางหน้าจอที่มีช่องกรอก ให้ใช้หลัก scroll, focus,
keyboard และ viewport เดียวกัน ส่วน dialog ที่ไม่มีช่องกรอกไม่ต้องใช้ keyboard wrapper

ก่อนส่งงานให้ทดสอบ viewport กว้าง 360 px สูง 640–720 px และจำลอง keyboard สูง
ประมาณ 280–320 px โดยตรวจว่าไม่มี overflow, ช่องกรอกไม่ถูกบัง, dialog ยังเลื่อนได้,
ปุ่มยืนยันเข้าถึงได้ และ controller ทุกตัวถูก dispose ครบ

---

## Layout / การ์ด

| Widget                   | ไฟล์                           | ใช้เมื่อ                                          |
| ------------------------ | ------------------------------ | ------------------------------------------------- |
| **CustomCard**           | `custom_card.dart`             | การ์ด neutral — header + เนื้อหา · ฟอร์ม / config |
| **CustomInfoBox**        | `custom_card.dart`             | กล่อง label + value · สี semantic ผ่าน `color`    |
| **CustomLoginCard**      | `custom_login_card.dart`       | wrapper ฟอร์ม login                               |
| **CustomMenuCard**       | `custom_menu_card.dart`        | เมนู grid บน Home                                 |
| **CustomHeroMenuCard**   | `custom_hero_menu_card.dart`   | เมนู hero gradient บน Home                        |
| **InfoRowCustom**        | `custom_info_row.dart`         | แถว icon + 2 บรรทัด (label / value)               |
| **CustomGradientAppBar** | `custom_gradient_app_bar.dart` | AppBar — variant ด้านล่าง                         |

**CustomGradientAppBar** — `CustomGradientAppBarVariant`:

| Variant   | ใช้เมื่อ                                   |
| --------- | ------------------------------------------ |
| `surface` | พื้นเรียบ + เส้นล่าง (default)             |
| `green`   | gradient primary (inbound / ทั่วไป)        |
| `orange`  | gradient outbound                          |
| `pink`    | gradient header (`primaryDark` → `accent`) |

---

## Loading, Alert, Skeleton

| Widget                     | ไฟล์                             | ใช้เมื่อ                                                         |
| -------------------------- | -------------------------------- | ---------------------------------------------------------------- |
| **CustomLoading**          | `custom_loading.dart`            | overlay — `show` / `showProgress` / `setProgress` / `dismiss`    |
| **CustomShowAlert**        | `custom_show_alert.dart`         | toast — `showSuccess` / `showWarning` / `showError` / `showInfo` |
| **VersionUpdateDialog**    | `version_update_dialog.dart`     | dialog อัปเดต APK                                                |
| **CustomShimmerBox**       | `custom_shimmer_box.dart`        | placeholder shimmer                                              |
| **CustomRobotPlaceholder** | `custom_robot_placeholder.dart` | mascot (splash / empty)                                          |

```dart
CustomLoading.showProgress(
  progress: 0,
  text: context.tr(
    'download.progress',
    fallback: 'กำลังดาวน์โหลด {percent}%',
    params: {'percent': '0'},
  ),
);
CustomLoading.setProgress(
  0.5,
  text: context.tr(
    'download.progress',
    fallback: 'กำลังดาวน์โหลด {percent}%',
    params: {'percent': '50'},
  ),
);
CustomLoading.dismiss(
  messageText: context.tr('common.done', fallback: 'เสร็จสิ้น'),
  alertType: CustomAlertType.success,
);

CustomShowAlert.showSuccess(
  context.tr('common.save_success', fallback: 'บันทึกสำเร็จ'),
);
CustomShowAlert.showError(
  context.tr('common.error', fallback: 'เกิดข้อผิดพลาด'),
);
CustomShowAlert.showWarning(
  context.tr('common.check_data', fallback: 'กรุณาตรวจสอบข้อมูล'),
);
CustomShowAlert.showInfo(
  context.tr('common.processing', fallback: 'กำลังประมวลผล'),
);
```

> `CustomLoading` / `CustomShowAlert` เรียกจาก **page / BlocListener** — ห้ามใน BLoC

---

## กล้องและสแกน

เรียกผ่าน **`CameraService`** เท่านั้น — ห้าม push `PhotoCapturePage` / `BarcodeScannerPage` จาก feature

ช่องที่ต้อง parse 2D / รองรับ HID Enter → ใช้ **`CustomBarcodeTextField`** (ดู [BARCODE_FORMAT.md](BARCODE_FORMAT.md))

```dart
final file = await CameraService.takePicture(context);
final code = await CameraService.scanBarcode(
  context,
  title: context.tr('product.scan_sku', fallback: 'สแกน SKU'),
  hint: context.tr('product.scan_hint', fallback: 'วางบาร์โค้ดในกรอบ'),
);

CustomBarcodeTextField(
  controller: _batchController,
  focusNode: _batchFocus,
  nextFocusNode: _expiryFocus,
  labelText: context.tr('product.batch', fallback: 'Batch'),
  tagFunction: BarcodeTagFunction.deliveryOrder,
  entryField: BarcodeFieldKey.batchNumber,
  apply: {
    BarcodeFieldKey.batchNumber: (v) =>
        _batchController.text = v.stringValue ?? '',
    BarcodeFieldKey.expiryDate: (v) {
      _expiryController.text =
          ToDisplayShow.toDisplayDate(v.requireDate());
    },
  },
);
```

---

## หน้า shared

| หน้า               | ไฟล์                    | ใช้เมื่อ              |
| ------------------ | ----------------------- | --------------------- |
| **ComingSoonPage** | `coming_soon_page.dart` | placeholder route สำหรับ feature ที่ยังไม่ implement |
| **NotFoundPage**   | `not_found_page.dart`   | 404 / route ไม่พบ     |

---

## Formatters (UI)

### แสดงผล UI — `to_display_show.dart`

| เมธอด                               | ใช้เมื่อ                    |
| ----------------------------------- | --------------------------- |
| `ToDisplayShow.displayValue(s)`     | `null` / ว่าง → `"-"`       |
| `ToDisplayShow.toDisplayDate(date)` | แสดง `dd/MM/yyyy`           |
| `ToDisplayShow.trimOrNull(s)`       | trim แล้วคืน `null` ถ้าว่าง |

> JSON → int/bool/String: ใช้ `Parse` ที่ `core/helpers/parse.dart` — ดู [README § Parse](../README.md#parse--json-helpers)

---

## เอกสารที่เกี่ยวข้อง

- [README.md](../README.md) — overview, theme, AI Developer Guide
- [BLOC_PATTERN.md](BLOC_PATTERN.md) — bloc + ห้าม UI ใน bloc
- [DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md) — visual spec (designer / mockup)

### Prompt สั้น ๆ สำหรับ AI (งาน UI)

```text
Implement UI ตาม mockup UX
Widgets: docs/SHARED_WIDGETS.md — เลือก dropdown ตามตาราง, ปรับ parameter ก่อนสร้างใหม่
ข้อความ UI: ใช้ context.tr('<page-or-feature>.<semantic_name>', fallback: '<ข้อความจริง>') ก่อนส่งเข้า AppText
สี: README § Theme System — context.appTheme
Bloc: docs/BLOC_PATTERN.md
กฎสำคัญ: widget ขาด parameter → เพิ่มใน shared widget (+ default value) ห้ามสร้างซ้ำใน features/
```
