# BS-Mobile — Flutter Template

โปรเจคกลางสำหรับ **Flutter Template** พัฒนาด้วย **Flutter** — ใช้เป็นต้นฉบับด้าน architecture, shared widgets และ core modules เพื่อให้ผู้พัฒนา **Duplicate/Clone** ไปเริ่มโปรเจคของตัวเองได้เร็วขึ้น

- **Package name:** `bs_mobile`
- **Version:** ดูจาก [`pubspec.yaml`](pubspec.yaml) (ปัจจุบัน `1.0.0+1`)
- เป็น **central template / boilerplate** ที่ไม่ผูกกับ domain หรือระบบธุรกิจใดระบบหนึ่ง
- เมื่อต้องทำระบบจริง ให้ Duplicate/Clone repository นี้เป็นโปรเจคใหม่ แล้วค่อยเปลี่ยนชื่อ package, branding, config และเพิ่ม domain features ในโปรเจคนั้น
- สถาปัตยกรรม: **pragmatic feature-first** (ไม่มี domain/use-case layer; BLoC เรียก repository ได้โดยตรง)

รองรับ **Android และ iOS** เท่านั้นในปัจจุบัน (web / desktop ยังไม่รองรับ)
งาน AI / agent → อ่าน **[AGENTS.md](AGENTS.md)** ก่อน (English, short)
Agent skills → `.agents/skills/` ([Flutter Agent Skills](https://docs.flutter.dev/ai/agent-skills))
งาน UI → อ่าน docs/SHARED_WIDGETS.md
งาน list + paging → อ่าน docs/PAGING.md
งาน import/export Excel·CSV → อ่าน docs/SPREADSHEET.md
งาน BLoC → อ่าน docs/BLOC_PATTERN.md
งาน feature ใหม่ → อ่าน docs/ARCHITECTURE.md
README → กฎรวม + setup (ภาษาไทยสำหรับทีม)

---

## บทบาทของ Repository นี้

`BS-Mobile` คือ **Flutter Template / Central Architecture Repository** ที่เป็นกลางทาง domain และไม่ใช่ระบบธุรกิจปลายทางใด ๆ

แนวทางใช้งาน:

1. Duplicate/Clone repository นี้เป็น repository ของโปรเจคใหม่
2. เปลี่ยน `name`, package identifier, app identity, theme และ environment ให้ตรงกับโปรเจคปลายทาง
3. เพิ่ม feature และ business logic เฉพาะระบบใน repository ที่ Duplicate แล้ว

ขณะพัฒนา template นี้ ให้แก้ไขภายใน workspace ปัจจุบัน และไม่สร้าง Flutter project หรือโฟลเดอร์โปรเจคใหม่ซ้อนขึ้นมาเอง

## วิธีใช้งานกับ AI / Agent

เมื่อสั่งงาน AI หรือ Agent ใน repository นี้ ให้เริ่มจากอ่าน [`AGENTS.md`](AGENTS.md) และส่วน project identity / repository role ของ README นี้ก่อนเสมอ จากนั้นอ่านเอกสารใน `docs/` และ skill ใน `.agents/skills/` ที่ตรงกับงานนั้น

ลำดับบริบทคือ:

```text
AGENTS.md       → กฎบังคับของ repository
README.md       → ภาพรวมและวิธีใช้งาน template
docs/           → รายละเอียดของระบบ
.agents/skills/ → ขั้นตอนทำงานเฉพาะประเภท
```

สำหรับงานทั่วไปไม่จำเป็นต้องโหลด README ทั้งเล่ม ให้เลือกอ่านเฉพาะ section ที่เกี่ยวข้องตาม routing ใน `AGENTS.md`

---

## สารบัญ

- [Tech Stack](#tech-stack)
- [สถาปัตยกรรม](#สถาปัตยกรรม) · [Architecture](docs/ARCHITECTURE.md) · [BLoC Pattern](docs/BLOC_PATTERN.md) · [Shared Widgets](docs/SHARED_WIDGETS.md) · [Paging](docs/PAGING.md) · [Spreadsheet](docs/SPREADSHEET.md)
- [โครงสร้างโปรเจกต์](#โครงสร้างโปรเจกต์)
- [Dependency Injection](#dependency-injection)
- [Routing & Navigation](#routing--navigation)
- [Network Layer](#network-layer)
- [Theme System](#theme-system)
- [Shared Widgets](#shared-widgets) · [รายละเอียดเต็ม](docs/SHARED_WIDGETS.md)
- [Core Modules](#core-modules)
- [AI Assistant](#ai-assistant)
- [Push Notifications (FCM)](#push-notifications-fcm)
- [Local Database (SQLite)](#local-database-sqlite)
- [Features](#features)
- [Testing](#testing)
- [SonarQube](#sonarqube)
- [Conventions](#conventions)
- [AI Developer Guide](#ai-developer-guide)
- [Getting Started](#getting-started)
- [Build](#build)
- [Android Release Signing](#android-release-signing)

---

## Tech Stack

| หมวด             | เทคโนโลยี                                                            | หมายเหตุ                                                             |
| ---------------- | -------------------------------------------------------------------- | -------------------------------------------------------------------- |
| Framework        | Flutter >= 3.38.4 (CI pin: 3.44.9) · Dart >= 3.10.3 < 4.0.0          | ใช้ toolchain ที่ pin ใน CI เพื่อผลลัพธ์ reproducible                 |
| State Management | **flutter_bloc** ^9.1.1 · **equatable** ^2.0.7                       | BLoC event/state ใช้ Equatable (ดู BLOC_PATTERN.md)                  |
| DI               | **get_it** ^9.2.1                                                    | ลงทะเบียนใน `app/di/injection.dart`                                  |
| Routing          | **go_router** ^17.3.0                                                | auth guard + menu-driven navigation                                  |
| HTTP             | **dio** ^5.7.0                                                       | ผ่าน `ApiClient` + interceptors                                      |
| Local DB         | **sqflite** ^2.4.2                                                   | SQLite layer กลาง (`lib/src/database/`)                              |
| Secure Storage   | **flutter_secure_storage**                                           | access/refresh token                                                 |
| Preferences      | **shared_preferences**                                               | theme, API URL, locale cache keys                                    |
| QR / Camera      | `camera`, `google_mlkit_barcode_scanning`                            | ผ่าน `CameraService`                                                 |
| Toast / Alert    | **bot_toast**                                                        | `CustomShowAlert`                                                    |
| Loading UI       | **CustomLoading** (Overlay + Lottie mascot)                          | shared loading component                                             |
| Connectivity     | **connectivity_plus**                                                | `NetworkBloc`                                                        |
| APK Update       | `Dio.download`, `open_file`, `permission_handler`                     | `VersionBloc` + `VersionRepository`                                  |
| Push / FCM       | `firebase_core`, `firebase_messaging`, `flutter_local_notifications` | `core/push_notification/` — เปิดด้วย `--dart-define=ENABLE_FCM=true` |
| Font             | Noto Sans + Noto Sans Thai                                           | `assets/fonts/`                                                      |

**Dependencies ที่เอาออกแล้วหากไม่มีการใช้:** `get`, `signalr_netcore`, `drift*` — อย่าเพิ่มกลับโดยไม่มี consumer

---

## สถาปัตยกรรม

โปรเจกต์ใช้ **hybrid architecture** — มี feature folders แต่ยังมี global layers ขนานกันใน `global/`, `database/` และ `core/`

> กฎสถาปัตยกรรมฉบับเต็ม: **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**

```
┌─────────────────────────────────────────────────────────┐
│  app/          bootstrap, MaterialApp.router, DI        │
├─────────────────────────────────────────────────────────┤
│  features/     หน้าจอ + BLoC + repository ตามโดเมน      │
├─────────────────────────────────────────────────────────┤
│  global/       app-shell BLoC, AppStorage, mock, models  │
├─────────────────────────────────────────────────────────┤
│  database/     SQLite (sqflite), DAO, migrations        │
├─────────────────────────────────────────────────────────┤
│  core/         network, theme, routing, RFID, AI, FCM, i18n  │
├─────────────────────────────────────────────────────────┤
│  shared/       reusable UI, camera, formatters          │
└─────────────────────────────────────────────────────────┘
```

### Dependency flow (เป้าหมาย)

```
Presentation (features)  →  Repository (features/* หรือ global/blocs/<name>/repository/)
Repository               →  Core (ApiClient) / Global (AppStorage) / Database (DAO)
Presentation             →  Shared (widgets)
Core                     →  ห้าม import shared/ui (UI อยู่ที่ AppBlocListeners)
Database                 →  ห้าม import features / shared/ui
```

### Layer หลัก

| Layer       | บทบาท                                                                     | ห้าม                          |
| ----------- | ------------------------------------------------------------------------- | ----------------------------- |
| `app/`      | composition root, bootstrap, DI, global BLoC listeners                    | business logic                |
| `features/` | business feature (pages, bloc, `models/`, `repository/`)                  | global singleton ที่ไม่จำเป็น |
| `global/`   | `AppStorage`, app-shell BLoC, shared models, mock JSON                    | showDialog, CustomShowAlert   |
| `database/` | SQLite กลาง — `AppDatabase`, schema, migration, DAO (`lib/src/database/`) | UI, เรียก API โดยตรง          |
| `core/`     | infra: network, theme, routing, localization, RFID, helpers               | import UI widgets โดยตรง      |
| `shared/`   | reusable widgets / camera                                                 | เรียก API โดยตรง              |

> **แยก persistence 2 ที่:** `global/local/app_storage.dart` = key-value + secure token · `database/` = SQLite relational

### BLoC ไม่เรียก UI โดยตรง

Side-effect ด้าน UI (alert, dialog, loading overlay) อยู่ที่:

- **`AppBlocListeners`** — version update dialog, download progress, session alerts
- **`BlocListener` ในแต่ละ page** — เช่น login success → navigate

---

## โครงสร้างโปรเจกต์

```
lib/
├── main.dart                          # → bootstrap()
└── src/
    ├── app/
    │   ├── app.dart                   # MultiBlocProvider + MaterialApp.router
    │   ├── bootstrap.dart             # init platform, DB, DI, runApp
    │   └── di/
    │       ├── injection.dart         # get_it registration
    │       └── app_bloc_listeners.dart # global BLoC → UI side-effects
    │
    ├── core/
    │   ├── ai/                        # AI models, config, action executor
    │   ├── push_notification/         # FCM service, local notifications, handler
    │   ├── app_config/                # app-wide quantity/config — docs/APP_CONFIG.md
    │   ├── barcode/                   # GetBarcodeFormat parse/apply — docs/BARCODE_FORMAT.md
    │   ├── app_identity.dart          # platform + applicationLicense
    │   ├── helpers/                   # Parse, network, debug colors, …
    │   ├── localization/              # runtime i18n (API → cache → LocaleService)
    │   ├── navigation/                # appNavigation.navigatorKey
    │   ├── network/
    │   │   ├── api_client.dart        # thin Dio wrapper
    │   │   ├── api_error_mapper.dart
    │   │   ├── api_error_notifier.dart
    │   │   ├── app_exception.dart
    │   │   ├── device_info_provider.dart
    │   │   ├── session_expired_handler.dart
    │   │   ├── interceptors/
    │   │   │   └── auth_interceptor.dart
    │   │   └── config/                # DevHttpOverrides
    │   ├── rfid/             # cipherlab, urovo, zebra
    │   ├── routing/
    │   │   ├── app_router.dart        # GoRouter + auth redirect
    │   │   ├── route_registry.dart    # menu_path → navigation
    │   │   └── routes.dart            # path constants
    │   └── theme/                     # palette, ThemeConfig, extensions
    │
    ├── database/                      # SQLite (sqflite) — ใช้งานจริงจาก bootstrap
    │   ├── core/                      # AppDatabase, BaseTableDao, registry
    │   ├── migrations/
    │   └── tables/                    # sample_item, locale_resource, …
    │
    ├── global/
    │   ├── blocs/                     # theme, network, locale, version, …
    │   │   └── version/
    │   │       └── repository/        # VersionRepository
    │   ├── local/
    │   │   └── app_storage.dart       # SharedPreferences + secure tokens
    │   ├── mockdata/                  # menu.json, locale mock, app_config mock
    │   └── models/                    # shared DTOs สำหรับโปรเจคที่นำ template ไปใช้
    │
    ├── features/
    │   ├── auth/                      # login — template หลัก (models + repository)
    │   ├── ai/                        # AI chat UI + repository
    │   ├── config_url/                # ตั้งค่า API URL + repository
    │   ├── config_rfid/               # RFID power config (presentation)
    │   ├── home/                      # models + repository + presentation
    │   ├── settings/                  # hub ไป config URL / RFID
    │   └── splash/                    # splash + token check
    │
    └── shared/
        ├── camera/                    # CameraService, barcode, photo capture
        ├── ui/
        │   ├── notification/          # CustomShowAlert
        │   ├── pages/                 # NotFoundPage, ComingSoonPage
        │   └── widgets/               # CustomButton, CustomLoading, …
        └── to_display_show.dart       # format วันที่ / ค่าว่าง สำหรับ UI
```

### Feature template (มาตรฐาน)

Architecture เป็น **feature-first แบบ pragmatic** — รายละเอียดกฎ, exception และ checklist อยู่ที่ **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**

โฟลเดอร์ใน `features/` ที่ติดมากับ repository นี้เป็น baseline/examples สำหรับสาธิตโครงสร้างเท่านั้น ไม่ใช่รายการฟีเจอร์ของระบบใดระบบหนึ่ง หลัง Duplicate สามารถเปลี่ยนชื่อ ลบ หรือแทนที่ด้วย domain features ของโปรเจคปลายทางได้

อ้างอิงหลัก: `features/auth/` · `features/home/`

```
features/<feature_name>/
├── models/                        # request/response DTOs (optional)
├── repository/<feature>_repository.dart   # concrete class เดียว
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/                   # optional — widget เฉพาะ feature นี้เท่านั้น
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

`VersionRepository` ผูกกับ `VersionBloc` อยู่ที่ **`global/blocs/version/repository/`** ไม่ใช่ใน `features/`

---

## Dependency Injection

ใช้ **get_it** — ลงทะเบียนทั้งหมดใน [`lib/src/app/di/injection.dart`](lib/src/app/di/injection.dart)

```dart
// bootstrap.dart
await configureDependencies();
wireAppNotifiers(
  sessionExpiredHandler: getIt<SessionExpiredHandler>(),
  errorNotifier: getIt<ApiErrorNotifier>(),
);
```

| ประเภท    | ตัวอย่าง                                                       | Lifetime                                |
| --------- | -------------------------------------------------------------- | --------------------------------------- |
| Singleton | `ApiClient`, `GoRouter`, `AuthRepository`, `VersionRepository` | lazy singleton                          |
| Factory   | `AuthBloc`, `MenuBloc`, `NetworkBloc`, …                       | ใหม่ทุกครั้งที่ `getIt<>()` ใน provider |

**เพิ่ม BLoC ใหม่:**

1. สร้าง BLoC + inject repository ผ่าน constructor
2. `getIt.registerFactory<MyBloc>(() => MyBloc(getIt()))`
3. เพิ่ม `BlocProvider` ใน `app.dart`

---

## Routing & Navigation

ใช้ **go_router** — config อยู่ที่ [`lib/src/core/routing/app_router.dart`](lib/src/core/routing/app_router.dart)

### Auth guard

Route **public** (ไม่ต้องมี token): `/splash`, `/login`, `/configurl`

Route อื่น → redirect ไป `/login` ถ้าไม่มี token ใน secure storage

### Routes ที่ลงทะเบียนแล้ว

| Path                                 | หน้า           | สถานะ                 |
| ------------------------------------ | -------------- | --------------------- |
| `/splash`                            | SplashPage     | ใช้งาน                |
| `/login`                             | LoginPage      | ใช้งาน                |
| `/configurl`                         | ConfigUrlPage  | ใช้งาน                |
| `/home`                              | HomePage       | ใช้งาน                |
| `/settings`                          | SettingsPage   | ใช้งาน (จาก menu API) |
| `/config_rfid`                       | ConfigRfidPage | ใช้งาน                |
| `/outbound_main`, `/outbound_create` | ComingSoonPage | sample placeholder (เปลี่ยนหรือลบเมื่อ Duplicate) |
| `/inbound_main`, `/inbound_create`   | ComingSoonPage | sample placeholder (เปลี่ยนหรือลบเมื่อ Duplicate) |
| `/transaction`                       | ComingSoonPage | sample placeholder (เปลี่ยนหรือลบเมื่อ Duplicate) |
| อื่น ๆ                               | NotFoundPage   | ผ่าน `errorBuilder`   |

### Menu-driven navigation

API/mock menu ส่ง `menu_path` (เช่น `/home`, `/settings`) — ใช้ [`RouteRegistry`](lib/src/core/routing/route_registry.dart):

```dart
// home_page.dart
RouteRegistry.navigateFromMenu(context, menuPath);
```

### การ navigate ในโค้ด

```dart
import 'package:go_router/go_router.dart';
import 'package:bs_mobile/src/core/routing/routes.dart';

context.go(Routes.home);           // แทนที่ stack (หลัง login)
context.push(Routes.settings);     // เปิดหน้าย่อย
context.pop();                       // กลับ
```

**เพิ่ม route ใหม่:**

1. เพิ่ม constant ใน `routes.dart`
2. เพิ่ม `GoRoute` ใน `app_router.dart`
3. เพิ่ม path ใน `RouteRegistry.registeredPaths` (ถ้า menu API ใช้)

---

## Network Layer

[`ApiClient`](lib/src/core/network/api_client.dart) แยก concern แล้ว:

| ไฟล์                           | บทบาท                               |
| ------------------------------ | ----------------------------------- |
| `auth_interceptor.dart`        | refresh token บน 401, retry request |
| `session_expired_handler.dart` | clear cache + redirect login        |
| `api_error_notifier.dart`      | แจ้ง error UI (wire ใน bootstrap)   |
| `api_error_mapper.dart`        | map DioException → ข้อความ user     |
| `device_info_provider.dart`    | IP / device model สำหรับ headers    |

```dart
// เรียก API
final client = getIt<ApiClient>();
final response = await client.get('/Mobile/...');

// JWT decode (login flow)
client.decodeJwt(accessToken);
```

---

## Theme System

ไฟล์อยู่ที่ `lib/src/core/theme/`

| ไฟล์                       | บทบาท                                            |
| -------------------------- | ------------------------------------------------ |
| `app_color_palette.dart`   | freshGreen, oceanBlue, royalPurple, sunsetOrange |
| `theme_config.dart`        | สร้าง `ThemeData`                                |
| `app_theme_extension.dart` | semantic colors, gradients, ปุ่ม                 |
| `theme_extensions.dart`    | `context.colorScheme`, `context.appTheme`        |

### กฎการใช้สี

1. Widget **ห้าม** import `ThemeConfig` เพื่ออ่านสี
2. ใช้ `context.colorScheme` + `context.appTheme` เท่านั้น
3. ปุ่มใช้ `CustomButton` + `CustomButtonVariant`
4. ยกเว้น: UI กล้อง / QR overlay

> **Visual spec สำหรับ designer:** [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) — ใช้ตอนออกแบบ mockup / gen UI  
> **Dev & AI implement:** อ่าน **mockup จากทีม UX** + ส่วนนี้ — **ไม่ต้องเปิด DESIGN_SYSTEM.md** ถ้ามี mockup แล้ว

### Mockup กับ Theme หลาย palette

แอพรองรับ **4 palette + dark mode** (ผู้ใช้เปลี่ยนใน Drawer) — สี brand ใน UI **เปลี่ยนตาม palette ที่เลือก** โดยตั้งใจ

| Mockup จาก SA/UX            | Implement ในโค้ด                                            |
| --------------------------- | ----------------------------------------------------------- |
| **Layout, flow, component** | ตรง mockup (source of truth)                                |
| **บทบาทสี (semantic role)** | map เป็น `colorScheme` / `appTheme`                         |
| **Hex ใน mockup**           | อ้างอิง snapshot เท่านั้น — มักเป็น **Fresh Green + Light** |

**"ตรง design"** = โครงสร้าง + role เดียวกัน — **ไม่ใช่** hex เดิมทุกครั้งเมื่อ user เปลี่ยน theme

### Map สีจาก mockup (ทำก่อนเพิ่ม token ใหม่)

| ใน mockup                     | ใช้ในโค้ด                                               |
| ----------------------------- | ------------------------------------------------------- |
| ปุ่มหลัก / link               | `CustomButtonVariant.primary` · `colorScheme.primary`   |
| พื้นการ์ด / ฟอร์ม             | `colorScheme.surface` + `outlineVariant`                |
| ข้อความหลัก / รอง             | `colorScheme.onSurface` · `onSurfaceVariant`            |
| สำเร็จ / เตือน / error / info | `appTheme.success` · `warning` · `error` · `info`       |
| Header / gradient brand       | `appTheme.primaryGradient` · `headerGradient`           |
| Hero inbound / outbound       | `appTheme.inboundMenuGradient` · `outboundMenuGradient` |

### เมื่อไหร่ถึงเพิ่มสีใน theme

1. **Map กับ token ด้านบนก่อน** — ถ้าได้ ไม่ต้องเพิ่ม
2. **เพิ่มเฉพาะ semantic role ใหม่** ที่ยังไม่มี (เช่น สีแถบสถานะของ domain เฉพาะ) → field ใน `AppThemeExtension`
3. **เพิ่มใน `PaletteTokens`** เมื่อเป็นส่วนของ brand ที่ต้องต่างกันทุก palette
4. **ห้าม** copy hex ลง feature · **ห้าม** เพิ่มสีเพราะ mockup ไม่ตรง hex ขณะ palette อื่น (เช่น Ocean Blue ใช้ `primary` ของมัน)

```text
สีจาก mockup → map semantic ที่มีก่อน → เพิ่ม token ใหม่เฉพาะ role ที่ไม่มีใน theme
```

### สีจาก UX ไม่ตรง token ในระบบ

ห้าม hardcode `Color(0x...)` ใน `features/` — เพิ่มสีผ่าน **ชั้น theme กลาง** แล้ว widget อ่านผ่าน `context.appTheme`:

| ขั้นตอน                                  | ไฟล์                                                          |
| ---------------------------------------- | ------------------------------------------------------------- |
| 1. เพิ่ม/แก้ brand token                 | `lib/src/core/theme/app_color_palette.dart` (`PaletteTokens`) |
| 2. map เป็น semantic (gradient, ปุ่ม, …) | `lib/src/core/theme/app_theme_extension.dart`                 |
| 3. ผูกกับ `ThemeData`                    | `lib/src/core/theme/theme_config.dart`                        |
| 4. ใช้ใน feature                         | `context.appTheme.<token>` หรือ `context.colorScheme`         |

ถ้า mockup ต้องการ **role สีใหม่** ที่ยังไม่มี token — **เพิ่ม field ใน `AppThemeExtension` ก่อน** ไม่ใส่ hex ใน page

### Dark / Light + palette

- **ThemeBloc** — `ThemeToggled`, `ThemePaletteChanged`
- เลือกใน Drawer (`drawer_menu.dart`)
- Persist: `AppStorage` keys `dark_mode`, `color_palette`

---

## Shared Widgets

Widget กลางอยู่ที่ `lib/src/shared/` — **รายละเอียดเต็ม:** **[docs/SHARED_WIDGETS.md](docs/SHARED_WIDGETS.md)**

| หมวด             | Widget หลัก                                                                                   |
| ---------------- | --------------------------------------------------------------------------------------------- |
| ฟอร์ม            | `CustomButton`, `CustomTextField`, `CustomBarcodeTextField`, `CustomQtyStepper`, `PickDateWidget` |
| Dropdown (3 แบบ) | `Customdropdown`, `CustomDropdownSearch`, `CustomDropdownSearchModal` |
| List + paging    | `PagedListController` + `PagedListView` — [docs/PAGING.md](docs/PAGING.md) (search UI ประกอบเอง) |
| Spreadsheet IO   | `SpreadsheetIO` + Excel/CSV(`\|`) — [docs/SPREADSHEET.md](docs/SPREADSHEET.md) |
| การ์ด            | `CustomCard`, `CustomInfoBox`, `CustomGradientAppBar`                                         |
| Feedback         | `CustomLoading`, `CustomShowAlert`                                                            |
| กล้อง            | `CameraService` + `BarcodeScanHelper` / `CustomBarcodeTextField` — [BARCODE_FORMAT.md](docs/BARCODE_FORMAT.md) |

### กฎการใช้และปรับ Shared Widget

**ลำดับที่ต้องทำ — ห้ามข้ามขั้น:**

```
1. มี shared widget ที่ใกล้เคียงไหม?
       ├── มี → parameter ที่มีอยู่รองรับได้ไหม?
       │         ├── ได้  → ใช้เลย (เสร็จ)
       │         └── ไม่ได้ → เพิ่ม parameter ใหม่ใน shared widget (+ default value)
       │                       ห้ามสร้าง widget ซ้ำใน features/
       └── ไม่มีเลย → สร้างใน shared/ui/widgets/
                       (ยกเว้น widget เฉพาะ domain จริง ๆ → features/<name>/presentation/widgets/)
```

**Parameter ที่ปรับได้บน widget หลัก:**

| Widget                 | Parameter ที่ปรับได้                                                                                                                                          |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `CustomTextField`      | `controller`, `labelText`, `hintText`, `prefixIcon`, `suffixIcon`, `keyboardType`, `validator`, `maxLines`, `readOnly`, `isPassword`, `enableDatePicker`, `onDateSelected` |
| `CustomBarcodeTextField` | `controller`, `focusNode`, `nextFocusNode`, `tagFunction`, `entryField`, `apply` (Enter/HID + กล้อง)                                                        |
| `CustomQtyStepper`     | `controller`, `onDecrement`, `onIncrement`, `label`, `useQuantityConfig` (default `true`), `inputFormatters`                                                  |
| `CustomButton`         | `variant` (`primary`/`success`/`danger`/`warning`/`disabled`), `text`, `icon`, `onPressed`, `backgroundColor`, `textColor`, `width`, `height`                 |
| `Customdropdown`       | `items`, `label`, `hint`, `validator`, `value`, `onChanged`, `itemToString`, `focusNode`, `enabled`                                                           |
| `CustomDropdownSearch` | `items`, `label`, `hint`, `itemToString`, `onChanged`, `searchHint`, `focusNode`, `nextFocusNode`, `pageSize`, `onLoadPage`                                  |
| `CustomDropdownSearchModal` | `items`, `label`, `hint`, `itemToString`, `onChanged`, `searchHint`, `focusNode`, `nextFocusNode`, `pageSize`, `onLoadPage`                              |
| `CustomCard`           | `title`, `subtitle`, `subtitleTrailing`, `icon`, `headerTrailing`, `child`, `padding`                                                                         |
| `CustomInfoBox`        | `label`, `value`, `color` (semantic)                                                                                                                          |

> **ถ้า parameter ที่ต้องการยังไม่มี → เพิ่ม parameter ใน shared widget พร้อม default value** อย่าสร้างซ้ำใน `features/`

กฎสั้น ๆ:

1. ใช้ shared widget ก่อนสร้างใหม่ใน feature
2. Dropdown — เลือกตามตารางใน [SHARED_WIDGETS.md § Dropdown](docs/SHARED_WIDGETS.md#dropdown--เลือกแบบไหน)
3. Alert / Loading — ใน page / `BlocListener` เท่านั้น

---

## Core Modules

| Module                      | Path                                                      | หน้าที่                      |
| --------------------------- | --------------------------------------------------------- | ---------------------------- |
| **GoRouter**                | `core/routing/app_router.dart`                            | routing + auth guard         |
| **RouteRegistry**           | `core/routing/route_registry.dart`                        | menu path validation         |
| **ApiClient**               | `core/network/`                                           | HTTP + auth refresh          |
| **AppStorage**              | `global/local/app_storage.dart`                           | settings + **secure tokens** |
| **AppDatabase**             | `database/`                                               | SQLite กลาง                  |
| **LocaleRepository**        | `core/localization/`                                      | i18n จาก API + file cache    |
| **AppConfigRepository**     | `core/app_config/` — [APP_CONFIG.md](docs/APP_CONFIG.md)  | digit/quantity config        |
| **BarcodeFormat**           | `core/barcode/` — [BARCODE_FORMAT.md](docs/BARCODE_FORMAT.md) | 2D scan parse + apply        |
| **AppIdentity**             | `core/app_identity.dart`                                  | platform + license           |
| **ThemeBloc**               | `global/blocs/theme/`                                     | dark mode + palette          |
| **NetworkBloc**             | `global/blocs/network/`                                   | connectivity                 |
| **VersionBloc**             | `global/blocs/version/`                                   | check/download APK           |
| **VersionRepository**       | `global/blocs/version/repository/version_repository.dart` | download logic แยกจาก bloc   |
| **AiChatBloc**              | `features/ai/`                                            | AI assistant                 |
| **PushNotificationBloc**    | `global/blocs/push_notification/`                         | FCM init state + token       |
| **PushNotificationService** | `core/push_notification/`                                 | FCM orchestration (no UI)    |
| **RFID**                    | `core/rfid/`                                     | urovo, zebra, cipherlab      |
| **Parse**                   | `core/helpers/parse.dart`                        | จาก JSON ที่ type ไม่ตรง     |

### Parse — JSON helpers

ใช้ใน `fromJson` / `fromDynamic` เมื่อ API อาจส่ง type ไม่ตรง (เช่น `"1"` แทน `1`, `0`/`1` แทน `bool`)

```dart
import 'package:bs_mobile/src/core/helpers/parse.dart';

factory MenuData.fromJson(Map<String, dynamic> json) => MenuData(
  menuId: Parse.parseInt(json['menu_id']),
  isView: Parse.parseBool(json['is_view']),
  menuName: Parse.parseString(json['menu_name']),
);
```

| เมธอด | คืนค่า | รองรับ |
| ----- | ------ | ------ |
| `Parse.parseInt(v)` | `int?` | `int`, `num`, string |
| `Parse.parseDouble(v)` | `double?` | `num`, string |
| `Parse.parseBool(v)` | `bool?` | `bool`, `0`/`1`, `"true"`/`"false"` |
| `Parse.parseString(v)` | `String?` | trim, ว่าง → `null` |
| `Parse.parseDateTime(v)` | `DateTime?` | ISO-8601 string |
| `Parse.parseStringList(v)` | `List<String>` | list ของ string |
| `Parse.parseIntOr(v, fallback)` | `int` | ค่า default เมื่อ parse ไม่ได้ |
| `Parse.parseBoolOr(v, fallback)` | `bool` | ค่า default เมื่อ parse ไม่ได้ |

> **แยกหน้าที่:** `Parse` = อ่านจาก JSON · `ToDisplayShow` = แสดงบนหน้าจอ — ดู [SHARED_WIDGETS § Formatters](docs/SHARED_WIDGETS.md#formatters-ui)

ตัวอย่างในโปรเจกต์: `menu_response_model.dart`, `api_base_response.dart`, `ai_suggestions_response.dart`

### Global BLoC ใน `app.dart`

`NetworkBloc`, `LocaleBloc`, `AppConfigBloc`, `ThemeBloc`, `VersionBloc`, `AuthBloc`, `MenuBloc`, `AiChatBloc`, `PushNotificationBloc`, `BluetoothBloc`, `TestConnectionBloc`

---

## AI Assistant

โมดูล AI: `lib/src/core/ai/` + UI ที่ `features/ai/`

- เรียก `POST api/v1/chat/completions` ผ่าน gateway (JWT เดียวกับ login)
- เปิดจาก **FAB บน Home**
- UI: `AiChatSheet` (bottom sheet)
- Navigation จาก AI: `AiActionCoordinator` → `RouteRegistry.navigateFromMenu`

รายละเอียด backend: **[docs/AI_INTEGRATION.md](docs/AI_INTEGRATION.md)**

```dart
showAiChatSheet(context, process: '/mobile/home');
```

---

## Push Notifications (FCM)

โมดูล push: `lib/src/core/push_notification/` + state ที่ `PushNotificationBloc`

- ใช้ **Firebase Cloud Messaging** + แสดง foreground ผ่าน `flutter_local_notifications`
- ค่าเริ่มต้น **ปิด** — เปิดด้วย `--dart-define=ENABLE_FCM=true` หลัง setup native config
- Token เก็บใน `AppStorage` (`fcm_token`)
- แตะ notification → `RouteRegistry.navigateFromMenu` ถ้า payload มี `menu_path`

รายละเอียด setup Android/iOS + backend token: **[docs/FCM_INTEGRATION.md](docs/FCM_INTEGRATION.md)**

```bash
flutter run --dart-define=ENABLE_FCM=true
```

---

## Local Database (SQLite)

SQLite layer: **`lib/src/database/`** (เปิดใน `bootstrap()` ผ่าน `AppDatabase.instance.open()`)

```
database/
├── core/           # AppDatabase, SqlTypes, BaseTableDao, registry
├── migrations/     # onCreate / onUpgrade
└── tables/         # โฟลเดอร์ต่อ table
    ├── sample_item/      # template
    └── sample_item/  # template only
```

### เพิ่ม table ใหม่

1. สร้าง `tables/<name>/` — `*_schema.dart`, `*_entity.dart`, `*_dao.dart`
2. `schema` implements `TableSchema`
3. `dao` extends `BaseTableDao<Entity>`
4. ลงทะเบียนใน `core/database_registry.dart`
5. bump version → `migrations/migration_vN.dart`

> **canonical path คือ `lib/src/database/`** (ที่ bootstrap import) — อย่าใส่ SQLite ใต้ `global/`

---

## Features

| Feature       | Path                    | Route          | สถานะ                          |
| ------------- | ----------------------- | -------------- | ------------------------------ |
| Splash        | `features/splash/`      | `/splash`      | ใช้งาน                         |
| Auth / Login  | `features/auth/`        | `/login`       | standard template + bloc tests |
| Home + Drawer | `features/home/`        | `/home`        | dynamic menu จาก API/mock      |
| Settings      | `features/settings/`    | `/settings`    | hub ไป config                  |
| Config URL    | `features/config_url/`  | `/configurl`   | ตั้งค่า API                    |
| Config RFID   | `features/config_rfid/` | `/config_rfid` | Urovo power config             |
| AI Chat       | `features/ai/`          | —              | FAB บน home                    |
| Outbound      | —                       | `/outbound_*`  | Coming soon                    |
| Inbound       | —                       | `/inbound_*`   | Coming soon                    |
| Transaction   | —                       | `/transaction` | Coming soon                    |

---

## Testing

```bash
flutter test
```

| โฟลเดอร์                                   | ครอบคลุม                                                  |
| ------------------------------------------ | --------------------------------------------------------- |
| `test/src/features/auth/`                  | auth model, bloc (บาง test ยังอ้าง path เก่า domain/data) |
| `test/src/features/config_url/`            | test connection                                           |
| `test/src/features/config_rfid/`           | config RFID page                                          |
| `test/src/core/network/`                   | ApiErrorMapper                                            |
| `test/src/core/routing/`                   | RouteRegistry                                             |
| `test/src/data/blocs/version/`           | VersionBloc                                               |
| `test/src/core/push_notification/`         | push payload parsing                                      |
| `test/src/data/blocs/push_notification/` | PushNotificationBloc                                      |

ใช้ **bloc_test** + **mocktail** สำหรับ unit/bloc tests

Integration tests (เมื่อเพิ่ม) ให้อยู่ใน `integration_test/` และรันด้วย
`flutter test integration_test -d <device-id>` โดยไม่เปิด Flutter Driver ใน production entrypoint

---

## SonarQube

วิเคราะห์คุณภาพโค้ด Dart ใน `lib/` ผ่าน SonarQube server ภายในทีม

คู่มือฉบับเต็ม: **[docs/SONARQUBE.md](docs/SONARQUBE.md)**

**Windows (รันที่ root โปรเจกต์):**

```powershell
sonar-scanner.bat -D"sonar.projectKey=BS-Mobile" -D"sonar.sources=lib" -D"sonar.host.url=http://10.10.60.67/sonarqube" -D"sonar.token=<YOUR_TOKEN>" -D"sonar.exclusions=android/**,ios/**,build/**,.dart_tool/**,**/*.g.dart,**/*.freezed.dart"
```

- scan เฉพาะ `lib/` — ไม่รวม `android/`, `ios/`, generated files
- **ห้าม commit** `sonar.token` — ใช้ `<YOUR_TOKEN>` หรือ environment variable (ดูใน doc)

---

## Conventions

### เพิ่ม feature ใหม่

1. สร้าง `lib/src/features/<name>/` — `models/`, `repository/`, `presentation/`
2. BLoC — **[docs/BLOC_PATTERN.md](docs/BLOC_PATTERN.md)** (default: command pattern แบบ `features/auth/`)
3. UI — **[docs/SHARED_WIDGETS.md](docs/SHARED_WIDGETS.md)** — ใช้หรือ**ขยาย** shared widget ก่อนสร้างใหม่ (ดูกฎด้านล่าง)
4. สี — `context.colorScheme` + `context.appTheme`
5. Alert — `CustomShowAlert` ใน **presentation layer** (ไม่ใส่ใน BLoC)
6. Loading — `CustomLoading` ใน listener / page
7. Route — เพิ่มใน `app_router.dart` + `RouteRegistry`
8. DI — register ใน `injection.dart`
9. BLoC แอพ-wide — `BlocProvider` ใน `app.dart`

### กฎ widget — ปรับก่อนสร้างใหม่

เมื่อ UI ต้องการ widget ที่ยัง**ไม่ตรง**ความต้องการ:

| สถานการณ์                              | ทำ                                                           |
| -------------------------------------- | ------------------------------------------------------------ |
| มี shared widget แต่ขาด parameter      | **เพิ่ม parameter** ใน shared widget พร้อม default value     |
| ต้องการ variant ใหม่ (สี, ขนาด, style) | เพิ่ม enum value หรือ named parameter ใน shared widget       |
| Widget เฉพาะ domain feature นี้จริง ๆ  | สร้างใน `features/<name>/presentation/widgets/`              |
| ยังไม่มี shared widget เลย             | สร้างใน `shared/ui/widgets/` เพื่อให้ feature อื่น reuse ได้ |

> **ห้ามสร้าง** `CustomTextField`, `Dropdown`, `Button` ซ้ำใน `features/` ไม่ว่ากรณีใด

### เพิ่ม API endpoint

1. สร้าง/ขยาย repository หรือ datasource
2. inject `ApiClient` จาก get_it
3. map error ผ่าน `ApiErrorMapper` / ให้ bloc emit failure state

---

## AI Developer Guide

ใช้เมื่อ AI / dev เขียนโค้ด — **dev แนบไฟล์ mockup จาก UX** (รูป, PDF, Figma export ฯลฯ) ให้ AI อ่าน layout และสีจากนั้น

### แหล่งอ้างอิง (ลำดับความสำคัญ)

1. **[AGENTS.md](AGENTS.md)** — agent entry (English, short): hard rules + task routing
2. **Mockup / spec จากทีม UX/SA** — source of truth เรื่อง **layout, flow, component**
3. **README** (§ Theme System / Getting Started / Build) + เอกสารตามงาน:
   - UI → **[docs/SHARED_WIDGETS.md](docs/SHARED_WIDGETS.md)**
   - BLoC → **[docs/BLOC_PATTERN.md](docs/BLOC_PATTERN.md)**
   - Feature structure → **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**
   - Quantity / app config → **[docs/APP_CONFIG.md](docs/APP_CONFIG.md)**
   - 2D barcode format → **[docs/BARCODE_FORMAT.md](docs/BARCODE_FORMAT.md)**
   - HTTP / ApiClient → **[docs/API_CLIENT.md](docs/API_CLIENT.md)**
4. โค้ดตัวอย่างใน repo — โดยเฉพาะ `features/auth/`, `features/home/`

**ไม่ต้องอ่าน [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)** เมื่อ implement โค้ด (ไฟล์นั้นสำหรับ designer / สร้าง mockup)

### UI จาก mockup

- Mockup มักอ้างอิง **Fresh Green + Light** — โค้ดใช้ **semantic token** ไม่ copy hex
- ผู้ใช้เปลี่ยน palette ในแอพ → สี brand เปลี่ยนตาม theme (ไม่ถือว่า bug)
- ฟอร์ม / รายการ / config → `CustomCard` แบบ **neutral** (`surface` + `outlineVariant`)
- Header / hero / CTA หลัก → **brand** (`CustomGradientAppBar`, `CustomHeroMenuCard`, `context.appTheme`)
- สี inbound / outbound → เฉพาะจุด brand (AppBar, hero) — ไม่ทา gradient ทั้งหน้าฟอร์ม
- สีใน mockup → [map ตามตาราง § Theme System](#map-สีจาก-mockup-ทำก่อนเพิ่ม-token-ใหม่) ก่อน · เพิ่ม token ใหม่เฉพาะ role ที่ไม่มี

### Widget — ปรับก่อนสร้างใหม่เสมอ

```
ต้องการ widget ใหม่?
    │
    ▼
มี shared widget ใกล้เคียงใน docs/SHARED_WIDGETS.md?
    ├── มี → parameter ที่มีอยู่รองรับได้ไหม?
    │         ├── ได้  → ใช้เลย ✓
    │         └── ไม่ได้ → เพิ่ม parameter ใหม่ใน shared widget (+ default value) ✓
    │                       ห้ามสร้าง widget ซ้ำใน features/ ✗
    └── ไม่มีเลย → สร้างใน shared/ui/widgets/ ✓
                   (widget เฉพาะ domain → features/<name>/presentation/widgets/ ✓)
```

ตัวอย่าง — `CustomTextField` ยังไม่มี `maxLength`:

```dart
// ✗ ห้าม — สร้าง TextField ใหม่ใน feature
TextField(maxLength: 10, decoration: InputDecoration(...))

// ✓ ถูก — เพิ่ม parameter ใน CustomTextField แล้วใช้
CustomTextField(
  controller: _skuController,
  labelText: context.tr('product.sku', fallback: 'รหัสสินค้า'),
  maxLength: 10,           // parameter ที่เพิ่มใหม่ใน shared widget
  validator: ...,
)
```

### Shared helpers, Models และข้อความ UI

- ก่อนสร้าง widget, helper/formatter หรือ Model ให้ค้นหา implementation เดิมใน `shared/`, `core/helpers/`, `global/models/` และ feature ที่เกี่ยวข้องก่อน
- ใช้หรือขยายของเดิมก่อนสร้าง class ใหม่ — หลักคือ **Search → Reuse → Extend → Create only when justified**
- ฟังก์ชัน parse, rounding และ format ตัวเลข/วันที่ที่ใช้ซ้ำต้องอยู่ใน helper/formatter กลาง ไม่เขียนซ้ำใน page, BLoC, repository หรือ model
- ใช้ Model เดิมภายใน API contract เดียวกัน; แยก `Request` และ `Response` ได้เมื่อเป็นคนละ contract
- `List<T>` ใช้ Model รายการเดิมได้ และสร้าง list wrapper เมื่อมี pagination/metadata ของตัวเองเท่านั้น
- UI model แยกได้เมื่อมี state/data เฉพาะ UI และต้องตั้งชื่อให้สื่อหน้าที่
- ข้อความ UI แบบ static ใช้ `context.tr('<page-or-feature>.<semantic_name>', fallback: '<ข้อความจริง>')` ก่อนส่งเข้า `AppText`, `Text`, label, hint, button, dialog, snackbar หรือ validation
- ไม่ต้องแปล route/API key, enum/code, asset path, log, test key หรือข้อความ dynamic จาก server โดยตรง

ตัวอย่าง:

```dart
AppText(
  context.tr(
    'login.submit',
    fallback: 'เข้าสู่ระบบ',
  ),
)
```

รายละเอียดเพิ่มเติม: [docs/LOCALE.md](docs/LOCALE.md) และ [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

### BLoC

- อ่าน **[docs/BLOC_PATTERN.md](docs/BLOC_PATTERN.md)** ก่อนสร้าง bloc
- Feature ใหม่ใช้ **command bloc** (`features/auth/`) — Equatable บน event/state · `Initial | Loading | Success | Failure`
- **UI state อยู่ page** (`TextEditingController`, tab, dialog, animation) — ห้ามยัดเข้า bloc
- **Session bloc** (`copyWith`, หลาย field) เฉพาะ flow ซับซ้อนแบบ `features/ai/` — ต้องระบุใน PR

```text
Repository: BS-Mobile (package: bs_mobile) — Flutter Template / Central Architecture

บทบาท: ต้นฉบับสำหรับ Duplicate/Clone ไปเริ่มโปรเจคอื่น ไม่ใช่ระบบธุรกิจปลายทาง

กฎบังคับ:
1. อ่าน mockup UX ที่ dev แนบ — layout/flow/component ตรง mockup
2. Shared widgets — อ่าน docs/SHARED_WIDGETS.md (dropdown เลือกตามตาราง)
3. Widget ขาด parameter → เพิ่มใน shared widget (+ default value) ไม่สร้างซ้ำใน features/
4. สี: context.colorScheme + context.appTheme — ห้าม Color(0x...) ใน features/
5. สีจาก mockup: map semantic ที่มีก่อน → เพิ่มใน core/theme/ เฉพาะ role ใหม่ที่ไม่มี
6. ปุ่ม: CustomButtonVariant.primary | success | danger | warning
7. Alert: CustomShowAlert ใน BlocListener/page — ห้ามใน BLoC/core
8. Loading: CustomLoading ใน presentation — ห้ามใน repository
9. Navigate: go_router — context.go / context.push + Routes.*
10. Menu path: RouteRegistry.navigateFromMenu()
11. DI: getIt<T>() — register ใน injection.dart
12. BLoC: docs/BLOC_PATTERN.md — command pattern + Equatable บน event/state
13. Feature ใหม่: models/ + repository/ + presentation/bloc
14. Route ใหม่: app_router.dart + routes.dart + route_registry.dart
15. Push/FCM: PushNotificationService / PushNotificationHandler — ห้าม import firebase_messaging จาก feature
16. Reuse-first: ค้นหาและใช้/ขยาย widget, helper, formatter, model และ repository เดิมก่อนสร้างใหม่
17. Model: Request/Response แยกได้เมื่อเป็นคนละ contract; contract เดียวใช้ canonical model เดียว และ `List<T>` ใช้ Model เดิม
18. Localization: ข้อความ UI static ใช้ `context.tr('<page-or-feature>.<semantic_name>', fallback: '<ข้อความจริง>')` ก่อนส่งเข้า AppText หรือ UI property
```

### Checklist ก่อน PR

- [ ] UI ตรง mockup — layout/component (สีผ่าน token ไม่ copy hex)
- [ ] สี map เป็น semantic token ก่อน — token ใหม่อยู่ใน `lib/src/core/theme/` เท่านั้น
- [ ] BLoC ตาม [docs/BLOC_PATTERN.md](docs/BLOC_PATTERN.md) — command pattern · ไม่มี UI state ใน bloc
- [ ] ไม่มีสี hardcode ใน feature (ยกเว้น camera overlay)
- [ ] BLoC ไม่ import `CustomShowAlert` / `CustomLoading`
- [ ] Route ลงทะเบียนใน GoRouter แล้ว
- [ ] Import path: `package:bs_mobile/src/...`
- [ ] **ไม่มี TextField / Dropdown / Button สร้างซ้ำใน features/** — ใช้หรือขยาย shared widget
- [ ] ค้นหาและ reuse Model/helper/widget เดิมก่อนสร้างใหม่
- [ ] ข้อความ UI static ใช้ `context.tr` พร้อม namespaced key และ fallback
- [ ] `flutter analyze` + `flutter test` ผ่าน

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) >= 3.38.4 (โปรเจกต์/CI pin ที่ 3.44.9; Dart SDK >= 3.10.3 < 4.0.0)
- Android Studio / VS Code
- Xcode 15.3+ บน macOS (เฉพาะเมื่อต้อง build iOS)

### Installation

```bash
git clone https://github.com/PattrawutKhammaAot/BS-Mobile.git
cd BS-Mobile
flutter pub get
flutter run
```

### Flow เริ่มต้น

1. **Splash** — ตรวจ API URL + token
2. ไม่มี API URL → **Login** → กด Settings → **Config URL**
3. Login สำเร็จ → โหลด locale + app config → **Home**
4. Home แสดงเมนูจาก API (หรือ mock `menu.json` ถ้าเปิด mock ใน repository)

### ทดสอบ Theme

1. Login → เปิด Drawer
2. สลับ Dark Mode + Theme Color (4 palette)
3. ปิดเปิดแอพ — ค่าจำจาก `AppStorage`

---

## Build

### เวอร์ชันแอพ

```yaml
# pubspec.yaml
version: 1.0.0+1
#        │ │ │  └── buildNumber (Android versionCode / iOS CFBundleVersion)
#        └─┴─┴──── versionName (แสดงให้ user)
```

### คำสั่ง build

```bash
flutter build apk --release
flutter build appbundle --release   # Play Store
flutter build ios --release         # macOS + Xcode 15.3+ เท่านั้น
```

> Web และ desktop ยังไม่ใช่แพลตฟอร์มที่รองรับ จึงไม่มีคำสั่ง release build สำหรับแพลตฟอร์มเหล่านั้น

### Build release APK (Windows script)

สคริปต์ [`scripts/build_release_apk.bat`](scripts/build_release_apk.bat) รัน `flutter build apk --release` แล้ว rename APK อัตโนมัติใน `build/app/outputs/flutter-apk/`:

| แหล่ง                                    | ใช้สำหรับ                 |
| ---------------------------------------- | ------------------------- |
| `android:label` ใน `AndroidManifest.xml` | ชื่อไฟล์ (ช่องว่าง → `_`) |
| `version:` ใน `pubspec.yaml`             | เวอร์ชันในชื่อไฟล์        |

**รูปแบบชื่อไฟล์:**

- `version: 1.0.0+1` → `Bs_Mobile_App_V1.0.0+1.apk`
- `version: 1.0.0` (ไม่มี build number) → `Bs_Mobile_App_V1.0.0.apk`

```bat
scripts\build_release_apk.bat
scripts\build_release_apk.bat --fcm
```

`--fcm` ส่ง `--dart-define=ENABLE_FCM=true` ไปกับ build (ดู [FCM Integration](docs/FCM_INTEGRATION.md))

ตั้งชื่อคงที่แทน manifest ได้โดยแก้ `APP_NAME_OVERRIDE` ด้านบนไฟล์ `.bat`

---

## Android Release Signing

Release build ใช้ keystore กลางของทีม — **ไฟล์จริงและรหัสผ่านไม่ commit ใน git**

โปรเจกต์ **ตั้ง Gradle ไว้แล้ว** ใน `android/app/build.gradle` — อ่าน `android/key.properties` อัตโนมัติ  
สิ่งที่ repo มีให้: `android/key.properties.example` (template) · สิ่งที่ **ไม่มีใน git**: `key.properties`, `*.keystore`

> คู่มือฉบับเต็ม: **[docs/ANDROID_RELEASE_SIGNING.md](docs/ANDROID_RELEASE_SIGNING.md)**

### กรณีที่ 1 — ทีมมี keystore อยู่แล้ว (dev คนใหม่)

1. รับ `bs-mobile-release.keystore` + รหัสผ่านจาก vault / ผู้ดูแล keystore
2. วางที่ `android/bs-mobile-release.keystore`
3. Copy template → config จริง:

```powershell
# Windows
Copy-Item android\key.properties.example android\key.properties
```

```bash
# macOS / Linux
cp android/key.properties.example android/key.properties
```

4. แก้ `android/key.properties` ใส่รหัสจริง (alias ต้องเป็น `bs-mobile-release`)
5. ทดสอบ:

```bash
flutter build apk --release
```

### กรณีที่ 2 — โปรเจกต์ยังไม่มี keystore เลย (ครั้งแรกของทีม)

ใช้ได้เฉพาะเมื่อ **ยังไม่เคยส่งแอปขึ้น Play Store** ด้วย key อื่น — ถ้าขึ้น store แล้วห้ามสร้างใหม่แทน

**1. สร้าง keystore** (Windows PowerShell — ใช้ keytool จาก Android Studio JBR):

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v `
  -keystore android\bs-mobile-release.keystore `
  -alias bs-mobile-release `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -storepass "รหัสที่ตั้งเอง" `
  -keypass "รหัสที่ตั้งเอง" `
  -dname "CN=BS-Mobile, OU=Mobile, O=OGA-Business-solution, L=Bangkok, ST=Bangkok, C=TH"
```

**2. สร้าง `key.properties`** จาก example แล้วใส่ค่าให้ตรง:

```properties
storePassword=รหัสที่ตั้งเอง
keyPassword=รหัสที่ตั้งเอง
keyAlias=bs-mobile-release
storeFile=../bs-mobile-release.keystore
```

**3. Backup ทันที** — เก็บ `bs-mobile-release.keystore` + รหัสใน vault (ถ้าไฟล์หาย จะอัปเดตแอปบน Play Store ไม่ได้)

**4. Build ทดสอบ:**

```bash
flutter build apk --release
```

**5. แจกทีม** — ส่ง keystore + รหัสให้คนที่ build release ผ่านช่องทางปลอดภัย (ไม่ commit git)

### ถ้าไม่ setup อะไรเลย

ไม่มี `android/key.properties` → release build **fallback ไป debug signing**  
ติดตั้งทดสอบได้ แต่ **ไม่ใช่ production** และอัปเดททับแอปที่เซ็นด้วย release key ไม่ได้

### เวอร์ชันก่อน build

```yaml
# pubspec.yaml
version: 1.0.0+1
#              └── buildNumber (+1 ทุกครั้งก่อนส่ง store)
```

### หมายเหตุสำคัญ

- backup keystore + รหัสใน vault
- ห้าม commit `key.properties`, `*.keystore`
- เปลี่ยน release key แล้ว — ถอนแอปเก่าบนเครื่องก่อนติดตั้ง build ใหม่ (key ไม่ตรงกัน)
- ตรวจ alias: `keytool -list -v -keystore android\bs-mobile-release.keystore`

---

## Requirements

- Flutter: `>=3.38.4` (CI pin: `3.44.9`)
- Dart: `>=3.10.3 <4.0.0`
- Android: API Level 26+ (`minSdk = 26`)
- iOS: 15.5+ (Xcode 15.3+)

---

## License

This repository is maintained as a central Flutter template. Developers may Duplicate/Clone it as the starting point for their own project repositories; product-specific code should live in those duplicated repositories.
