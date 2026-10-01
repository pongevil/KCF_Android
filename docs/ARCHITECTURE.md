# BS-Mobile Architecture (Pragmatic)

คู่มือสถาปัตยกรรมฉบับ **pragmatic feature-first** ของ central Flutter Template — อ้างอิงจากโค้ดจริง
มาตรฐาน feature: [`features/auth/`](../lib/src/features/auth/) · [`features/home/`](../lib/src/features/home/)

ฟีเจอร์ที่มีใน repository นี้เป็น baseline/examples สำหรับสาธิต architecture เท่านั้น หลัง Duplicate ให้ปรับหรือลบตาม domain ของโปรเจคปลายทาง

---

## สารบัญ

1. [ภาพรวม](#ภาพรวม)
2. [โครงสร้าง Layer](#โครงสร้าง-layer)
3. [Feature Template (บังคับ)](#feature-template-บังคับ)
4. [Model / DTO และ shared code](#model--dto-และ-shared-code)
5. [กฎ Import / ห้ามทำ](#กฎ-import--ห้ามทำ)
6. [Widget vs Bloc: อะไรอยู่ตรงไหน](#widget-vs-bloc-อะไรอยู่ตรงไหน)
7. [Anti-pattern ที่ห้ามทำ (ตัวอย่างจริง)](#anti-pattern-ที่ห้ามทำ-ตัวอย่างจริง)
8. [สัญญาณเตือน Fat Widget](#สัญญาณเตือน-fat-widget)
9. [Exception ที่อนุญาต](#exception-ที่อนุญาต)
10. [BLoC และ Repository วางที่ไหน](#bloc-และ-repository-วางที่ไหน)
11. [Checklist เพิ่ม Feature ใหม่](#checklist-เพิ่ม-feature-ใหม่)
12. [Dependency Flow](#dependency-flow)

---

## ภาพรวม

โปรเจกต์ใช้ **hybrid architecture**:

- มี `features/` ตามโดเมน
- มี global layers ขนานกัน: `core/`, `global/`, `database/`, `shared/`

ไม่ใช้ Clean Architecture เต็มรูปแบบ (ไม่มี `domain/` + interface repository + use cases)  
Repository เป็น **class เดียว** inject `ApiClient` แล้วเรียก API + persist ที่จำเป็น

```mermaid
flowchart TB
  subgraph features [features]
    pres[presentation bloc pages]
    repo[repository concrete]
    models[models DTO]
  end

  subgraph global [global layers]
    core[core infra]
    global[global blocs storage models]
    db[database]
    shared[shared UI camera]
  end

  pres --> repo
  pres --> shared
  repo --> core
  repo --> global
  repo --> db
```

---

## โครงสร้าง Layer

| Layer                             | วางอะไร                                                     | ห้าม                          |
| --------------------------------- | ----------------------------------------------------------- | ----------------------------- |
| `app/`                            | bootstrap, DI, `MaterialApp`, global BLoC listeners         | business logic                |
| `core/`                           | network, routing, theme, localization, RFID, AI config, FCM | import `shared/ui`            |
| `global/blocs/`                   | BLoC แอพ-wide (theme, locale, version, network, …)          | `CustomShowAlert` ใน BLoC     |
| `global/blocs/<name>/repository/` | repository ผูกกับ BLoC เดียว (เช่น `VersionRepository`)     | UI                            |
| `global/local/`                   | `AppStorage` key-value + secure token                       | —                             |
| `global/models/`                  | shared DTOs (order, api response, …)                        | —                             |
| `global/mockdata/`                | JSON mock สำหรับ dev                                        | —                             |
| `database/`                       | SQLite กลาง, DAO, migrations                                | UI, เรียก API โดยตรง          |
| `features/<name>/`                | business feature ตาม template                               | global singleton ที่ไม่จำเป็น |
| `shared/`                         | reusable widgets, camera                                    | เรียก API โดยตรง              |

> **Persistence 2 ที่:** `AppStorage` = key-value + token · `database/` = relational SQLite

---

## Feature Template (บังคับ)

ใช้กับ **feature ใหม่ทั้งหมด** และ feature ที่ refactor แล้ว

```
features/<feature_name>/
├── models/                              # optional — request/response DTOs
│   └── <feature>_model.dart
├── repository/                          # concrete class เดียว
│   └── <feature>_repository.dart
└── presentation/
    ├── bloc/                            # optional — ถ้ามี state management
    ├── pages/
    └── widgets/                         # optional
```

**ตัวอย่าง (`auth`):**

```
features/auth/
├── models/auth_model.dart
├── repository/auth_repository.dart
└── presentation/
    ├── bloc/auth_bloc.dart
    └── pages/login_page.dart
```

**ลงทะเบียน DI** ([`injection.dart`](../lib/src/app/di/injection.dart)):

```dart
getIt.registerLazySingleton<AuthRepository>(
  () => AuthRepository(getIt<ApiClient>()),
);
getIt.registerFactory<AuthBloc>(
  () => AuthBloc(authRepository: getIt<AuthRepository>()),
);
```

---

## Model / DTO และ shared code

ก่อนสร้าง Model, helper หรือ formatter ให้ค้นหา implementation เดิมใน
`lib/src/shared/`, `lib/src/core/helpers/`, `lib/src/global/models/` และ feature ที่เกี่ยวข้องก่อน
หลักคือ **Search → Reuse → Extend → Create only when justified**

### Model แยกตาม API contract

- `Request model` ใช้สำหรับข้อมูลที่ส่งไป API เช่น `CreateUserRequest`
- `Response model` ใช้สำหรับข้อมูลที่ API ส่งกลับ เช่น `UserResponse`
- ถ้า request และ response มีโครงสร้างหรือหน้าที่ต่างกัน ให้แยก Model ได้ทันที
- ถ้าเป็น contract เดียวกัน ให้มี Model หลักเพียงตัวเดียว ห้ามสร้าง `ResponseModel`,
  `DataModel` หรือ `ItemModel` หลายตัวที่มีความหมายและ field ซ้ำกันโดยไม่มีเหตุผล
- รายการสามารถ compose จาก Model เดิมได้ เช่น `List<UserResponse>` ใน list widget
- สร้าง wrapper เช่น `UserListResponse` ได้เมื่อ API envelope มี pagination หรือ metadata ของตัวเอง
- UI model แยกได้เฉพาะเมื่อมี state/data ที่เป็นของ UI จริง ๆ และต้องตั้งชื่อให้สื่อหน้าที่

ตัวอย่าง:

```dart
class UserListView extends StatelessWidget {
  final List<UserResponse> items;
}
```

`UserListView` เป็น widget ส่วน `UserResponse` เป็น response Model จึงไม่ใช่การสร้าง Model ซ้ำ

### Shared helpers และข้อความ UI

- การ parse, rounding และ format ตัวเลข/วันที่ที่ใช้ซ้ำ ให้อยู่ใน helper/formatter กลาง
- Feature ใช้ helper เดิมหรือเพิ่มความสามารถให้ helper เดิม ไม่เขียนฟังก์ชันซ้ำใน page/BLoC/repository
- ข้อความ UI แบบ static ใช้ `context.tr('<feature-or-page>.<semantic_key>', fallback: '<ข้อความจริง>')`
  ก่อนส่งเข้า `AppText` หรือ property อื่นของ UI
- route/API key/enum code/asset path/log/test key และข้อมูลจาก server โดยตรงไม่ต้องแปล

---

## กฎ Import / ห้ามทำ

| กฎ                                                                              | รายละเอียด                                                                                                       |
| ------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| ห้าม `domain/`                                                                  | ไม่สร้าง abstract repository / use case layer                                                                    |
| ห้าม `data/datasources/`                                                        | ใช้ `repository/` แทน                                                                                            |
| ห้าม `*_repository_impl`                                                        | repository เป็น concrete class เดียว                                                                             |
| Feature ห้าม import Dio / `firebase_messaging` โดยตรง                           | ผ่าน repository + `ApiClient` / core push module                                                                 |
| BLoC ห้าม import UI                                                             | ไม่ใช้ `CustomShowAlert`, `CustomLoading`, `showDialog` ใน BLoC                                                  |
| Core ห้าม import `shared/ui`                                                    | UI side-effects อยู่ `AppBlocListeners` / page listeners                                                         |
| Widget ห้าม hardcode สี                                                         | ใช้ `context.colorScheme` + `context.appTheme`                                                                   |
| Repository เรียก `AppStorage` / DAO ได้                                         | pragmatic — ไม่บังคับแยก data source layer                                                                       |
| ต้องค้นหาของเดิมก่อนสร้าง                                                        | reuse shared widget/helper/model หรือขยายของเดิมก่อนสร้าง class ใหม่                                              |
| Model ต้องแยกตาม contract                                                       | Request/Response แยกได้เมื่อเป็นคนละ contract; ห้าม duplicate model ใน contract เดียวกัน                         |
| ข้อความ UI แบบ static                                                          | ใช้ `context.tr(key, fallback: text)`; ไม่ hardcode ข้อความใหม่ใน presentation                                  |
| **Widget/Page ห้ามเรียก Repository ตรงแบบ ad hoc**                              | ใช้ Bloc event เป็น default; ข้อยกเว้นมีเฉพาะ `PagedLoader` ของ `PagedListController` ตาม [PAGING.md](PAGING.md) |
| **Widget ห้ามเก็บ pagination / list state ซ้ำเอง**                              | ห้ามมี `_locationList`, `_pageNumber`, `_totalPages`; ให้ Bloc State หรือ `PagedListController` เป็น owner เพียงตัวเดียว |
| **Widget ห้ามมี business validation ที่มีผลต่อการยิง API หรือผลลัพธ์ทางธุรกิจ** | เช่น validate ก่อน submit, คำนวณจำนวนคงเหลือ/limit ต้องอยู่ใน Bloc หรือ Validator/Use Case แยก                   |
| **ห้ามใช้ manual pending-flag แทน Bloc State**                                  | เช่น `bool _pendingXxx` เพื่อจำ flow async — ให้สร้างเป็น sealed State class ของ Bloc แทน                        |

---

## Widget vs Bloc: อะไรอยู่ตรงไหน

เส้นแบ่งที่ dev มักสับสนที่สุดคือ "อันนี้เป็น UI logic หรือ business logic" ตารางนี้ใช้ตัดสินแบบเร็ว:

| ประเภท Logic                                                                               | อยู่ที่                       | เหตุผล                                                                  |
| ------------------------------------------------------------------------------------------ | ----------------------------- | ----------------------------------------------------------------------- |
| เรียก API / Repository                                                                     | Bloc (default) หรือ `PagedLoader` exception | ทดสอบได้โดยไม่ต้อง pump widget และมี boundary ที่ชัดเจน                 |
| Pagination state (page, totalPages, list ที่โหลดมาแล้ว)                                    | Bloc State (default) หรือ `PagedListController` (simple-list exception) | ต้องมี owner เดียว; page ห้ามเก็บ list/page ซ้ำ                         |
| Business validation ก่อน submit (required field, เงื่อนไข lot/serial/expiry, limit จำนวน)  | Bloc หรือ Validator class แยก | เป็น business rule ที่ต้อง test ได้อิสระจาก UI                          |
| Flag บอกสถานะ async (`isLoading`, `isValidating`, `isSaving`)                              | Bloc State (sealed class)     | ห้ามใช้ `bool` ลอยๆ ใน widget เพราะ sync พลาดง่ายเมื่อ flow ซับซ้อนขึ้น |
| คำนวณค่าที่มีผลต่อ business (เช่น quantity คงเหลือ, เงื่อนไขเปิด/ปิดปุ่มตาม business rule) | Bloc / Use Case               | ต้อง test ได้แยกจาก widget tree                                         |
| Focus node, scroll, animation, expand/collapse UI                                          | Widget                        | เป็น UI-only ล้วนๆ ไม่กระทบ business rule                               |
| Format ตัวเลข/วันที่เพื่อแสดงผล                                                            | Widget หรือ shared helper     | display-only ไม่กระทบ logic                                             |

**หลักตัดสินสั้นๆ:** ถ้าลบ logic นั้นออกแล้ว "ผลลัพธ์ทางธุรกิจ" เปลี่ยน (เช่น ยิง API ผิด, บันทึกข้อมูลผิด, validate หลุด) → logic นั้นต้องอยู่ใน Bloc ถ้าลบแล้วกระทบแค่ "หน้าตา/ประสบการณ์การพิมพ์" → อยู่ใน widget ได้

> **Pagination exception:** หน้า list/search/refresh ที่ไม่มี business flow ซับซ้อนใช้ `PagedListController` ได้ โดย page มีหน้าที่สร้างและ dispose controller เท่านั้น; `PagedLoader` เป็นจุดเดียวที่เรียก repository และ controller เป็น owner ของ items/page/loading/error ทั้งหมด หาก pagination ผูกกับ business validation, permission, multi-step flow หรือ state อื่นของ feature ให้ใช้ Bloc ตาม default ดูรายละเอียดใน [PAGING.md](PAGING.md)

---

## Anti-pattern ที่ห้ามทำ (ตัวอย่างจริง)

```dart
// ❌ ห้าม: Widget เรียก repository ตรงผ่าน bloc (ข้าม Bloc layer)
final response = await context
    .read<XxxBloc>()
    .xxxRepository
    .fetchXxx(request);
setState(() { _list = response.data; }); // state จัดการเองใน widget
```

```dart
// ✅ ถูก: ยิง Event แล้วให้ Bloc จัดการ State ทั้งหมด
context.read<XxxBloc>().add(FetchXxxEvent(request));
// widget แค่ฟัง state ผ่าน BlocBuilder/BlocListener
```

```dart
// ❌ ห้าม: เก็บ pending flag เองใน widget เพื่อจำ flow async
bool _pendingItemValidation = false;
bool _pendingPickSave = false;
```

```dart
// ✅ ถูก: ให้ Bloc ยิง state เฉพาะของแต่ละ flow
sealed class OutboundState {}
class OutboundItemValidating extends OutboundState {}
class OutboundItemValidated extends OutboundState { final Item item; }
class OutboundItemValidationFailed extends OutboundState { final String message; }
class OutboundPickSaving extends OutboundState {}
class OutboundPickSaved extends OutboundState { final SaveResponse response; }
```

```dart
// ❌ ห้าม: business validation ยาวๆ อยู่ใน State<StatefulWidget>
bool _validatePickFields({bool showError = true}) {
  if (_selectedLocation == null) { ... return false; }
  if (_availableQuantity <= 0) { ... return false; }
  // ... เงื่อนไข lot/expiry/serial อีกหลายสิบบรรทัด
}
```

```dart
// ✅ ถูก: แยกเป็น Validator/Use Case ที่ test ได้อิสระจาก widget
class PickValidator {
  static ValidationResult validate(PickFormData data) { ... }
}
// Bloc เรียก PickValidator ก่อนยิง Event บันทึก แล้ว emit state ผลลัพธ์
```

---

## สัญญาณเตือน Fat Widget

ใช้เป็น self-check ก่อนส่ง PR หรือใส่ใน [SONARQUBE.md](SONARQUBE.md) เป็นกฎ review:

- `State<StatefulWidget>` มี field ที่ไม่ใช่ `Controller`/`FocusNode`/ค่า UI-only (เช่น `isExpanded`) เกิน **10-15 ตัว** → สัญญาณว่า business/data state รั่วเข้ามาแล้ว ให้ทบทวนย้ายเข้า Bloc State
- มี method ที่ไม่ได้ return `Widget` เกิน **5-6 ตัว** ใน State class และแต่ละตัวมี logic เกิน 3-4 บรรทัด → ต้อง review ว่าเป็น business logic หรือ UI-only จริง
- มี `BlocListener` ที่ตัวมันเองมีเงื่อนไข `if/else` ซ้อนกันเกิน 3 ชั้น หรือยาวเกิน ~40 บรรทัด → เป็นสัญญาณว่า Bloc ควรประมวลผลจบและยิง State ที่ "บอกผลลัพธ์" มาให้เลย ไม่ใช่ให้ widget ตัดสินใจต่อ
- มี `setState` ที่ตามด้วยการเรียก repository หรือคำนวณ business rule ภายใน callback เดียวกัน → ต้องแยกออกเป็น Event ไปให้ Bloc

---

## Exception ที่อนุญาต

### Shell features (ไม่มี repository)

| Feature    | เหตุผล                |
| ---------- | --------------------- |
| `splash`   | หน้า bootstrap สั้น ๆ |
| `settings` | hub นำทางไปหน้าย่อย   |

โครงสร้าง: `features/<name>/presentation/` อย่างเดียว

### Hardware UI (ชั่วคราว)

| Feature       | หมายเหตุ                                                                               |
| ------------- | -------------------------------------------------------------------------------------- |
| `config_rfid` | เรียก `Urovo` SDK โดยตรงจาก page — refactor เป็น repository ได้เมื่อมี persistence/API |

### Global cross-feature

| ที่วาง                             | ตัวอย่าง                                                         |
| ---------------------------------- | ---------------------------------------------------------------- |
| `global/blocs/`                    | `ThemeBloc`, `LocaleBloc`, `VersionBloc`, `PushNotificationBloc` |
| `global/blocs/version/repository/` | `VersionRepository`                                              |
| `core/`                            | AI models/config, network, FCM service                           |

---

## BLoC และ Repository วางที่ไหน

| ประเภท                          | วางที่                               | ตัวอย่าง                           |
| ------------------------------- | ------------------------------------ | ---------------------------------- |
| BLoC แอพ-wide                   | `global/blocs/`                      | `ThemeBloc`, `NetworkBloc`         |
| BLoC เฉพาะ feature              | `features/<name>/presentation/bloc/` | `AuthBloc`, `MenuBloc`             |
| Repository เฉพาะ feature        | `features/<name>/repository/`        | `AuthRepository`, `HomeRepository` |
| Repository ผูกกับ BLoC แอพ-wide | `global/blocs/<name>/repository/`    | `VersionRepository`                |

รูปแบบการเขียน BLoC (command vs session, UI state อยู่ที่ไหน): **[BLOC_PATTERN.md](BLOC_PATTERN.md)**

---

## Checklist เพิ่ม Feature ใหม่

1. สร้าง `lib/src/features/<name>/` ตาม [Feature Template](#feature-template-บังคับ)
2. ค้นหาและ reuse Model/helper/widget เดิมก่อนสร้างใหม่ (ดู [Model / DTO และ shared code](#model--dto-และ-shared-code))
3. UI — ใช้ widget จาก `shared/ui/widgets/` ก่อน (ดู [SHARED_WIDGETS.md](SHARED_WIDGETS.md))
4. ข้อความ UI — ใช้ `context.tr` พร้อม namespaced key และ fallback
5. สี — `context.colorScheme` + `context.appTheme`
6. Alert / Loading — ใน `BlocListener` / page เท่านั้น
7. Register repository + BLoC ใน [`injection.dart`](../lib/src/app/di/injection.dart)
8. BLoC แอพ-wide → `BlocProvider` ใน [`app.dart`](../lib/src/app/app.dart)
9. Route → [`app_router.dart`](../lib/src/core/routing/app_router.dart) + [`route_registry.dart`](../lib/src/core/routing/route_registry.dart) + [`routes.dart`](../lib/src/core/routing/routes.dart)
10. **ตรวจสอบว่า `State<StatefulWidget>` ไม่มี business logic / เรียก repository ตรงแบบ ad hoc / validation รั่วอยู่** — ยกเว้น `PagedLoader` ของ simple-list ตาม [PAGING.md](PAGING.md); เทียบกับ [Widget vs Bloc](#widget-vs-bloc-อะไรอยู่ตรงไหน) และ [สัญญาณเตือน Fat Widget](#สัญญาณเตือน-fat-widget) ก่อน merge
11. `flutter analyze` + `flutter test` ผ่าน

---

## Dependency Flow

```
Presentation (features)  →  Repository (features/* หรือ global/blocs/<name>/repository/)
Repository               →  Core (ApiClient) / Global (AppStorage) / Database (DAO)
Presentation             →  Shared (widgets)
Core                     →  ห้าม import shared/ui
Database                 →  ห้าม import features / shared/ui
```

Side-effect UI (alert, dialog, loading, version update, push tap navigate) อยู่ที่:

- [`AppBlocListeners`](../lib/src/app/di/app_bloc_listeners.dart)
- `BlocListener` ในแต่ละ page

---

## เอกสารที่เกี่ยวข้อง

- [README.md](../README.md) — overview, tech stack, theme
- [SHARED_WIDGETS.md](SHARED_WIDGETS.md) — widget catalog
- [README § Core Modules](../README.md#core-modules) — รายการ core modules
- [AI_INTEGRATION.md](AI_INTEGRATION.md) — AI module
- [FCM_INTEGRATION.md](FCM_INTEGRATION.md) — push notifications
- [BLOC_PATTERN.md](BLOC_PATTERN.md) — วิธีเขียน feature BLoC
- [SHARED_WIDGETS.md](SHARED_WIDGETS.md) — widget กลาง
- [SONARQUBE.md](SONARQUBE.md) — code quality scan

---

## Persistence ownership

| Data | Write owner | Notes |
|------|-------------|-------|
| Config URL | ConfigUrlRepository (via `ConfigUrlBloc`) | Presentation must not call `AppStorage.setApi` |
| Network flag | `NetworkBloc` | Persists on `NetworkNotify` |
| Auth tokens / user profile | `AuthRepository` / `AuthInterceptor` | Splash/router may **read** token as documented exception |
| App version string | `bootstrap` ? `AppStorage.setVersion` | Not from login page |
| Theme | `ThemeBloc` | |
| App quantity config | `AppConfigRepository` cache + `AppConfigBloc` apply | |
| Locale strings | JSON disk via `LocaleRepository`; apply in `LocaleBloc` | No SQLite locale table |

## Routing composition exception

`AppRouter` in `core/routing` imports feature pages directly — pragmatic exception; do not move unless there is clear benefit.

## RFID adapters

Live path: Urovo via `RfidDeviceService` / `ConfigRfidBloc`. Cipherlab/Zebra remain under `core/rfid/` as unused vendor stubs (no UI side effects).
