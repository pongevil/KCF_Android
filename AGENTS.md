---
description:
alwaysApply: true
---

# BS-Mobile — Flutter Template Agent Entry

This repository is a central **Flutter Template** (`package: bs_mobile`) — reusable architecture and shared modules for bootstrapping other apps. It is domain-neutral and is not a product-specific business system. Duplicate/clone it into a new project before adding domain-specific code. Pragmatic feature-first: no domain/use-case layer; BLoC calls concrete repositories that use `ApiClient`.

## Hard rules

- Treat this repository as the reusable template source; do not assume a business domain or add product-specific behavior here by default.
- Work inside the current repository root. Do not create a sibling project folder, run `flutter create`, or initialize another repository unless explicitly requested.
- Reuse or extend shared widgets before creating new ones in `features/`
- Before adding any widget, helper/formatter, or model, search the existing shared, core, global, and feature code and reuse or extend the closest implementation.
- Keep reusable number/date parsing and display formatting in the existing `core/helpers/` or `shared/` utilities; do not recreate them inside a page, BLoC, repository, or model.
- Static user-visible strings must be resolved with `context.tr('<feature-or-page>.<semantic_key>', fallback: '<actual display text>')` before passing them to `AppText` or other UI properties.
- For models, keep one canonical model per API contract/resource. Separate request and response models when they represent different contracts; do not create duplicate `ResponseModel`/`DataModel`/`ItemModel` classes for the same contract without a documented reason.
- No UI (`CustomShowAlert`, `CustomLoading`, controllers, dialogs) inside BLoC or repository
- Colors: `context.colorScheme` / `context.appTheme` — no hardcoded `Color(0x...)` in features
- Navigation: `go_router` (`context.go` / `context.push` + `Routes.*`); menu via `RouteRegistry`
- DI: `getIt<T>()` — register in `lib/src/app/di/injection.dart`
- Never commit secrets, `key.properties`, or `*.keystore`
- Prefer `package:bs_mobile/src/...` imports
- Any `CustomTextField` / `TextField` / searchable dropdown: plan `FocusNode` (create + dispose), next-field focus, and soft-keyboard behavior (`SoftKeyboardController`)
- Open bottom sheets through `showCustomModalBottomSheet<T>()`; sheets with input must use scrollable content and own/dispose every `FocusNode`

## Key paths

- DI: `lib/src/app/di/`
- Routing: `lib/src/core/routing/`
- Network: `lib/src/core/network/`
- Shared UI / camera / paging / spreadsheet: `lib/src/shared/`
- Features: `lib/src/features/<name>/` → `models/` + `repository/` + `presentation/`

## Reuse, localization, and model boundaries

- **Reuse-first:** search before creating. A missing parameter is a reason to extend the existing shared widget/helper/model, not to create a page-local copy. A new class is justified only when it has a distinct responsibility that the existing class cannot safely represent.
- **Shared helpers:** generic date/number parsing, rounding, and display formatting belong in the existing helper/formatter modules. Feature code consumes them; it does not reimplement them.
- **UI strings:** labels, titles, form names, button text, hints, validation messages, dialog/snackbar copy, tooltips, and empty/loading text use a stable namespaced key such as `login.submit` or `common.cancel` plus a `fallback`. `AppText` receives the translated result; it does not invent a second localization path.
- **Non-UI strings:** route paths, API/JSON keys, enum codes, asset paths, logs, test keys, and opaque server data are not localized unless the server explicitly returns a localization key.
- **Model contracts:** `CreateUserRequest` and `UserResponse` may be separate even when related. A list widget may use `List<UserResponse>`, and a `UserListResponse` wrapper may contain that list when the API envelope has pagination or metadata. A UI model is allowed only for UI-specific state/data and must be named by that responsibility.

## Agent preflight (required)

Before changing code, docs, configuration, or tests:

1. Read this root `AGENTS.md` and the project identity / repository-role sections of [`README.md`](README.md).
2. Route the task to the relevant document in `docs/` and the matching skill in `.agents/skills/`.
3. Read the full linked document and skill before acting; do not load unrelated skill bodies.
4. If a task spans multiple areas, read each relevant document/skill and resolve conflicts in favour of the explicit user request, then these hard rules.

The README is the human-facing overview. It is part of the required project context, but unrelated tasks should read only its relevant sections rather than dumping the entire file.

## Read by task

- For step-by-step workflows, use skills in `.agents/skills/` (official Flutter/Dart + `bs-*`)
- Do not load every skill body up front — activate only the skill that matches the task
- Architecture / new feature → [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) · skill `bs-new-feature`
- BLoC → [docs/BLOC_PATTERN.md](docs/BLOC_PATTERN.md) · skill `bs-bloc`
- UI / widgets → [docs/SHARED_WIDGETS.md](docs/SHARED_WIDGETS.md) · skill `bs-shared-ui`
- Dialog / bottom sheet / keyboard → [docs/SHARED_WIDGETS.md](docs/SHARED_WIDGETS.md#dialog-และ-soft-keyboard) · skill `bs-shared-ui`
- Localization → [docs/LOCALE.md](docs/LOCALE.md) · skill `flutter-setup-localization`
- HTTP / ApiClient → [docs/API_CLIENT.md](docs/API_CLIENT.md)
- List paging → [docs/PAGING.md](docs/PAGING.md) · skill `bs-paging`
- Excel / CSV → [docs/SPREADSHEET.md](docs/SPREADSHEET.md) · skill `bs-spreadsheet`
- Unit / widget tests → matching test skill (`dart-add-unit-test`, `dart-generate-test-mocks`, or `flutter-add-widget-test`)
- Integration tests → skill `flutter-add-integration-test`; use the existing app entrypoint and `integration_test/` only when requested
- App config / quantity → [docs/APP_CONFIG.md](docs/APP_CONFIG.md)
- 2D barcode format → [docs/BARCODE_FORMAT.md](docs/BARCODE_FORMAT.md)
- FCM → [docs/FCM_INTEGRATION.md](docs/FCM_INTEGRATION.md)
- Setup, build, signing, theme overview → [README.md](README.md) · signing detail → [docs/ANDROID_RELEASE_SIGNING.md](docs/ANDROID_RELEASE_SIGNING.md)

## Validate

- `flutter analyze`
- `flutter test` (or task-relevant tests)
