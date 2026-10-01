---
name: flutter-add-integration-test
description: Create and run end-to-end Flutter flows with the modern integration_test package in BS-Mobile. Use when testing real navigation, platform plugins, or complete user journeys; do not enable Flutter Driver by default.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 16 Sep 2026 00:00:00 GMT
---

# BS-Mobile Integration Tests

Use `integration_test` for device-level flows in this existing Flutter Template. These tests complement unit/widget tests; they are not a reason to create a second Flutter project or to change the production entrypoint for a test-only driver.

## Before coding

1. Read the root [`AGENTS.md`](../../../AGENTS.md) and inspect `lib/main.dart`, `lib/src/app/bootstrap.dart`, and the relevant feature route.
2. Read [`docs/ARCHITECTURE.md`](../../../docs/ARCHITECTURE.md) plus [`docs/SHARED_WIDGETS.md`](../../../docs/SHARED_WIDGETS.md) when the flow interacts with shared widgets or modal forms.
3. Decide whether the test is a pure widget test (keep it under `test/`) or a device/plugin flow (use `integration_test/`).

## Project contract

- The production entrypoint is `lib/main.dart`, which calls `bootstrap()` and then `runApp`.
- Do not add `enableFlutterDriverExtension()` to production code for a normal integration test.
- Do not create `test_driver/`, `integration_driver()`, or a `flutter_driver` dependency unless the user explicitly asks to maintain or migrate a legacy Driver suite.
- Use `mocktail` for test doubles at replaceable boundaries; keep real platform behavior in device tests when that is what the flow is meant to verify.
- Use stable `ValueKey`s on important controls instead of relying on localized text or widget positions.

## Setup and authoring

1. Add the Flutter SDK `integration_test` dev dependency only when integration tests are requested and it is not already present:

   ```yaml
   dev_dependencies:
     integration_test:
       sdk: flutter
   ```

   Keep the existing `flutter_test` dependency; do not add a duplicate entry, then run `flutter pub get`.
2. Create `integration_test/<flow>_test.dart`.
3. Initialize the binding before the test body:

   ```dart
   void main() {
     IntegrationTestWidgetsFlutterBinding.ensureInitialized();
     // testWidgets(...) ...
   }
   ```
4. Start the real app through the existing bootstrap/entrypoint contract, or pump a deliberately isolated app when the test does not need platform initialization. Do not initialize the app twice.
5. Use `tester.tap`, `tester.enterText`, `tester.scrollUntilVisible`, and `tester.pumpAndSettle()` for finite animations and navigation transitions.
6. For fields and modal forms, follow the FocusNode, keyboard, and `showCustomModalBottomSheet<T>()` rules from `bs-shared-ui` and `docs/SHARED_WIDGETS.md`.

## Execution

Run on an explicitly selected Android emulator/device or iOS simulator:

```bash
flutter test integration_test -d <device-id>
flutter test integration_test/<flow>_test.dart -d <device-id>
```

The current template supports Android and iOS; do not add Chrome/web execution instructions unless web support is explicitly introduced. For CI, add a separate device/emulator job only when the repository has a reliable runner and the user requests it; the existing CI job is unit/widget analysis and test only.

## Validate

- `flutter analyze`
- `flutter test` for the existing unit/widget suite
- `flutter test integration_test -d <device-id>` on the target platform
- Confirm tests use stable keys, do not depend on network data without a deterministic fixture, and do not leave timers, controllers, or app state leaking between flows

## Legacy Driver exception

If the user explicitly requests legacy Flutter Driver support, isolate it from the modern default: document why it is needed, keep the driver extension out of normal production builds where possible, and verify the exact `flutter drive`/`test_driver` toolchain separately.
