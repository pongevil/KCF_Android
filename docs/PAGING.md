# ListView + Paging — ตัวกลาง

คู่มือ `PagedListController` + `PagedListView`  
**logic กลาง / หน้าตาอยู่ที่ feature**

---

## สารบัญ

1. [ภาพรวม](#ภาพรวม)
2. [ขอบเขตทางสถาปัตยกรรม](#ขอบเขตทางสถาปัตยกรรม)
3. [ไฟล์ที่เกี่ยวข้อง](#ไฟล์ที่เกี่ยวข้อง)
4. [สัญญาข้อมูล](#สัญญาข้อมูล)
5. [Controller API](#controller-api)
6. [PagedListView — UI slots](#pagedlistview--ui-slots)
7. [Search — มีแค่ logic ไม่มีช่องค้นหา](#search--มีแค่-logic-ไม่มีช่องค้นหา)
8. [ตัวอย่างเต็ม (list + search + refresh)](#ตัวอย่างเต็ม-list--search--refresh)
9. [map จาก API](#map-จาก-api)
10. [เทียบกับ Dropdown paging](#เทียบกับ-dropdown-paging)
11. [สิ่งที่ไม่ได้อยู่ในตัวกลาง](#สิ่งที่ไม่ได้อยู่ในตัวกลาง)

---

## ภาพรวม

```
Feature (หน้าตา)
  ├── TextField / CustomTextField   ← คุณประกอบเอง (ถ้าต้องการค้นหา)
  ├── RefreshIndicator             ← คุณห่อเอง
  └── PagedListView                ← shell กลาง (scroll → loadMore)
        └── PagedListController    ← logic กลาง (page, hasMore, error)
              └── PagedLoader      ← คุณส่ง (เรียก repo)
```

| ชั้น | ทำอะไร | ไม่ทำอะไร |
| --- | --- | --- |
| `PagedListController` | โหลดหน้า, append, refresh, `searchText`, กัน double-fetch | ไม่รู้ Theme / TextField / Card |
| `PagedListView` | `ListView.builder` + ใกล้ท้าย → `loadMore` + เรียก builders | ไม่ hardcode สี / ข้อความไทย |
| Feature | `itemBuilder`, empty, error, footer, **ช่องค้นหา** | ไม่เขียน `_page++` ซ้ำ |

---

## ขอบเขตทางสถาปัตยกรรม

`PagedListController` เป็น documented exception ของกฎ Command BLoC สำหรับหน้า list/search/refresh ทั่วไปที่ไม่มี business flow ซับซ้อน:

- `PagedLoader` เป็นจุดเดียวที่เรียก repository และ map ผลเป็น `PagedResult<T>`
- controller เป็น owner ของ items/page/loading/error; page ห้ามเก็บ `_items`, `_pageNumber` หรือ flags ชุดเดียวกันซ้ำ
- page รับผิดชอบ lifecycle (`initState` / `dispose`) และ UI builders เท่านั้น
- ถ้า pagination ผูกกับ business validation, permission, multi-step flow หรือ state อื่นของ feature ให้ใช้ Bloc event/state ตาม [BLOC_PATTERN.md](BLOC_PATTERN.md#pagination--load-more)

ห้ามผสมสอง pattern ในหน้าเดียวกัน เช่นให้ Bloc เก็บ list แต่ให้ controller เก็บ page หรือเรียก repository ซ้ำจาก scroll callback

---

## ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | บทบาท |
| --- | --- |
| `lib/src/shared/paging/paged_result.dart` | `PagedResult`, `PagedLoader`, alias `DropdownSearchPage` |
| `lib/src/shared/paging/paged_list_controller.dart` | state + load API |
| `lib/src/shared/ui/paging/paged_list_view.dart` | infinite-scroll shell |
| `test/src/shared/paging/paged_list_controller_test.dart` | unit tests |

Import:

```dart
import 'package:bs_mobile/src/shared/paging/index.dart';
import 'package:bs_mobile/src/shared/ui/paging/index.dart';
// หรือ
import 'package:bs_mobile/src/shared/index.dart';
```

---

## สัญญาข้อมูล

```dart
class PagedResult<T> {
  final List<T> items;
  final int pageNumber;   // 1-based
  final int totalPages;
  final int? totalRecords;
}

typedef PagedLoader<T> = Future<PagedResult<T>> Function({
  required int pageNumber,
  required int pageSize,
  String? searchText,
});
```

`hasMore`:

- ถ้า `totalPages > 0` → `pageNumber < totalPages`
- ถ้า `totalPages <= 0` (ไม่รู้ยอด) → ยังมีต่อเมื่อหน้าล่าสุดได้เต็ม `pageSize`

---

## Controller API

```dart
final controller = PagedListController<Order>(
  loader: myLoader,
  pageSize: 20, // default
);

await controller.loadInitial();           // หน้า 1
await controller.loadMore();              // หน้าถัดไป (ถ้า hasMore)
await controller.refresh();               // reset แล้วโหลดหน้า 1 (คง searchText)
await controller.setSearch('SKU-01');     // ตั้ง search + โหลดหน้า 1 ใหม่
await controller.loadInitial(searchText: 'x'); // ตั้ง search ตอนโหลดครั้งแรก

controller.items;
controller.hasMore;
controller.isInitialLoading;
controller.isLoadingMore;
controller.error;
controller.searchText;
controller.dispose(); // ใน State.dispose
```

---

## PagedListView — UI slots

บังคับ: `controller`, `itemBuilder`  
ที่เหลือเป็น optional — **ไม่ส่ง = `SizedBox.shrink()`** (ไม่มี spinner/ข้อความ default ของโปรเจค)

```dart
PagedListView<Order>(
  controller: controller,
  itemBuilder: (context, order, index) => OrderTile(order: order),
  separatorBuilder: (_, __) => const Divider(height: 1),
  emptyBuilder: (_) => const Center(child: Text('ไม่มีข้อมูล')),
  initialLoadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
  loadMoreFooterBuilder: (_) => const Padding(
    padding: EdgeInsets.all(16),
    child: Center(child: CircularProgressIndicator()),
  ),
  noMoreFooterBuilder: (_) => const Padding(
    padding: EdgeInsets.all(12),
    child: Center(child: Text('ครบแล้ว')),
  ),
  errorBuilder: (context, error, retry) => Center(
    child: TextButton(onPressed: retry, child: const Text('ลองใหม่')),
  ),
  scrollThreshold: 40, // px จากท้ายรายการ
  padding: const EdgeInsets.all(16),
);
```

Pull-to-refresh ห่อด้านนอก:

```dart
RefreshIndicator(
  onRefresh: controller.refresh,
  child: PagedListView<Order>(...),
);
```

---

## Search — มีแค่ logic ไม่มีช่องค้นหา

**ตัวกลางไม่มีช่อง search UI**

มีแค่:

- `PagedLoader` รับ `searchText`
- `controller.setSearch(...)` / `loadInitial(searchText: ...)`
- `controller.searchText`

หน้าตาช่องค้นหา → **feature ประกอบเอง** (เช่น `CustomTextField`, AppBar search, chip filter)

### ทำไมออกแบบแบบนี้

แต่ละโปรเจค / หน้า วาง search ไม่เหมือนกัน (บน AppBar, ใน filter sheet, debounce คนละแบบ)  
เลยไม่ผูก TextField เข้า `PagedListView`

### โครงหน้าที่มี search (คุณจัด layout)

```
┌─────────────────────────────┐
│  [  CustomTextField ...  ]  │  ← feature
├─────────────────────────────┤
│  item                       │
│  item                       │  ← PagedListView
│  …                          │
│  (footer loading)           │  ← loadMoreFooterBuilder
└─────────────────────────────┘
```

### ตัวอย่าง wire search → controller

```dart
// debounce ใน State ของหน้า
Timer? _debounce;
final _searchController = TextEditingController();
final _searchFocusNode = FocusNode();

void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 350), () {
    controller.setSearch(value.trim().isEmpty ? null : value.trim());
  });
}

@override
void dispose() {
  _debounce?.cancel();
  _searchController.dispose();
  _searchFocusNode.dispose();
  controller.dispose();
  super.dispose();
}

// ใน build:
Column(
  children: [
    Padding(
      padding: const EdgeInsets.all(12),
      child: CustomTextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        labelText: 'ค้นหา',
        hintText: 'รหัส / ชื่อ...',
        textInputAction: TextInputAction.search,
        onFieldSubmitted: (_) => _searchFocusNode.unfocus(),
        onChanged: _onSearchChanged,
      ),
    ),
    Expanded(
      child: PagedListView<Order>(
        controller: controller,
        itemBuilder: (context, order, index) => OrderTile(order: order),
        // ... builders อื่น
      ),
    ),
  ],
);
```

Loader ต้องส่ง `searchText` เข้า repo:

```dart
PagedLoader<Order> loader = ({
  required int pageNumber,
  required int pageSize,
  String? searchText,
}) async {
  final res = await orderRepo.list(
    page: pageNumber,
    size: pageSize,
    q: searchText,
  );
  return PagedResult(
    items: res.items,
    pageNumber: res.page,
    totalPages: res.totalPages,
    totalRecords: res.totalRecords,
  );
};
```

ถ้าหน้า **ไม่ต้องค้นหา** — ไม่ต้องมี TextField; loader ละเว้น `searchText` ได้

---

## ตัวอย่างเต็ม (list + search + refresh)

```dart
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final PagedListController<Order> _controller;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = PagedListController<Order>(
      loader: ({required pageNumber, required pageSize, searchText}) {
        return orderRepo.fetchPage(
          page: pageNumber,
          size: pageSize,
          search: searchText,
        ); // คืน PagedResult<Order>
      },
    );
    _controller.loadInitial();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: CustomTextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              labelText: 'ค้นหา',
              textInputAction: TextInputAction.search,
              onFieldSubmitted: (_) => _searchFocusNode.unfocus(),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  _controller.setSearch(v.trim().isEmpty ? null : v.trim());
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _controller.refresh,
              child: PagedListView<Order>(
                controller: _controller,
                itemBuilder: (context, order, index) => ListTile(
                  title: Text(order.code),
                ),
                emptyBuilder: (_) => const Center(child: Text('ว่าง')),
                initialLoadingBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                loadMoreFooterBuilder: (_) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorBuilder: (context, error, retry) => Center(
                  child: TextButton(
                    onPressed: retry,
                    child: const Text('ลองใหม่'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## map จาก API

Repo แปลง JSON → `PagedResult` ที่ขอบ repository (ตัวกลางไม่ parse JSON)

ตัวอย่าง field ที่เจอบ่อย: `total_pages`, `total_records`

```dart
return PagedResult(
  items: list.map(Order.fromJson).toList(),
  pageNumber: page,
  totalPages: Parse.parseInt(json['total_pages']) ?? 0,
  totalRecords: Parse.parseInt(json['total_records']),
);
```

---

## เทียบกับ Dropdown paging

| ใช้เมื่อ | ตัวเลือก |
| --- | --- |
| หน้า list / ตาราง ยาว + infinite scroll | **`PagedListView` + `PagedListController`** |
| เลือกค่าในฟอร์ม + ค้นหาใน dropdown | `CustomDropdownSearch` / `CustomDropdownSearchModal` (`onLoadPage`) |

`DropdownSearchPage` = **typedef alias** ของ `PagedResult` — dropdown เดิมใช้ชื่อเดิมได้

รายละเอียด dropdown: [SHARED_WIDGETS.md § Dropdown](SHARED_WIDGETS.md#dropdown--เลือกแบบไหน)

---

## สิ่งที่ไม่ได้อยู่ในตัวกลาง

- ช่องค้นหา / filter chips / AppBar search
- Pull-to-refresh chrome (ห่อ `RefreshIndicator` เอง)
- Card / ListTile / shimmer เฉพาะแบรนด์
- Parsing JSON paging fields (อยู่ที่ repository)
- Business flow orchestration — simple list ใช้ controller ตรงใน `State`; flow ซับซ้อนใช้ Bloc และไม่สร้าง controller ซ้ำ

---

## Checklist หน้า list ใหม่

- [ ] สร้าง `PagedListController` + `PagedLoader` ที่ map จาก repo
- [ ] ยืนยันว่าเป็น simple list exception; ถ้ามี business/multi-step state ให้ใช้ Bloc แทน
- [ ] `loadInitial()` ใน `initState`, `dispose()` controller
- [ ] ไม่มี `_items` / `_pageNumber` / loading flags ซ้ำใน page
- [ ] `PagedListView` + `itemBuilder` (+ empty / loading / error / footer ตามดีไซน์หน้า)
- [ ] ถ้ามีค้นหา → วาง `CustomTextField` นอก list แล้วเรียก `setSearch` (แนะนำ debounce)
- [ ] ถ้ามี pull-to-refresh → ห่อ `RefreshIndicator(onRefresh: controller.refresh)`
