---
name: bs-new-feature
description: >-
  Scaffolds a feature inside the current BS-Mobile Flutter template/project with models/, repository/, and presentation/
  (BLoC + pages), then wires DI and go_router. Use when adding a new feature,
  screen module, menu destination, or feature folder under lib/src/features/.
---

# bs-new-feature

## Before coding

1. Read [docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md)
2. Read the root [AGENTS.md](../../../AGENTS.md) preflight and hard rules
3. Use `lib/src/features/auth/` as the pragmatic reference (not clean-architecture templates)
4. Confirm the current workspace is an existing Flutter project (`pubspec.yaml` is present); never create a new root project or sibling folder as part of feature scaffolding
5. Search existing models, shared widgets, helpers/formatters, and repositories before adding new classes

## Checklist

1. Create `lib/src/features/<name>/`:
   - `models/`
   - `repository/` (concrete class; inject `ApiClient` via `getIt`)
   - `presentation/bloc/` + `presentation/pages/`
2. Register repository / bloc factory in `lib/src/app/di/injection.dart`
3. Add route constants in `lib/src/core/routing/routes.dart`
4. Register GoRoute in `lib/src/core/routing/app_router.dart`
5. If menu-driven: update `lib/src/core/routing/route_registry.dart`
6. Prefer shared widgets from `lib/src/shared/` — extend parameters before inventing feature-only duplicates
7. Navigate with `context.go` / `context.push` + `Routes.*`
8. Model boundaries:
   - Keep one canonical model per API contract/resource
   - Separate request and response models when their contracts differ
   - Use the existing response model in `List<...>`; create a list wrapper only for its own pagination/metadata
   - Create a UI model only for UI-specific state/data, with a responsibility-based name
9. Static UI strings use `context.tr('<feature-or-page>.<semantic_name>', fallback: '<actual display text>')` before passing them to shared widgets or `AppText`

## Do not

- Add `domain/` / use-case layers
- Put UI (`CustomShowAlert`, `CustomLoading`, dialogs, controllers) in BLoC or repository
- Hardcode `Color(0x...)` in features

## Validate

- `flutter analyze`
- Add/update task-relevant tests under `test/`
