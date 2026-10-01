---
name: bs-bloc
description: >-
  Implements BS-Mobile command-pattern BLoCs with Equatable events/states
  (Initial | Loading | Success | Failure). Use when creating or changing
  feature BLoCs, Cubits, events, states, or BlocListener wiring.
---

# bs-bloc

## Before coding

1. Read [docs/BLOC_PATTERN.md](../../../docs/BLOC_PATTERN.md)
2. Prefer the command pattern used by `features/auth/`
3. Keep UI state on the page (`TextEditingController`, tabs, dialogs, animations)

## Checklist

1. Events and states extend `Equatable` (or project-equivalent)
2. Default state machine: `Initial` → `Loading` → `Success` | `Failure`
3. BLoC calls concrete repository / `ApiClient` — no UI imports
4. Show alerts/loading only in page / `BlocListener` / `app_bloc_listeners`
5. Register the bloc in `lib/src/app/di/injection.dart` when app-scoped
6. Session-style `copyWith` blocs only for complex flows (e.g. AI) — call out in PR

## Do not

- Import `CustomShowAlert` / `CustomLoading` inside the bloc
- Emit UI chrome from repository
- Stuff form controllers into bloc state

## Validate

- `flutter analyze`
- Prefer `bloc_test` coverage for new/changed blocs
