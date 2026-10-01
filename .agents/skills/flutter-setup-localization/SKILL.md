---
name: flutter-setup-localization
description: Extend BS-Mobile's API-driven JSON localization system. Use when changing locale loading, fallback strings, locale-aware widgets, or adding localized content; do not replace it with ARB generation unless explicitly requested.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 16 Sep 2026 00:00:00 GMT
---

# BS-Mobile Localization

Use this skill for localization work in the existing BS-Mobile template. This repository already has a runtime localization pipeline; it is not a blank Flutter app that should be initialized with a new ARB/l10n system.

## Before coding

1. Read [`docs/LOCALE.md`](../../../docs/LOCALE.md) and the root [`AGENTS.md`](../../../AGENTS.md).
2. Inspect `lib/src/core/localization/` and `lib/src/global/blocs/locale/` before changing a flow.
3. Keep the existing API/cache/fallback ownership unless the user explicitly requests a migration.

## Current contract

- `LocaleRepository` fetches locale resources from the API, reads/writes JSON disk cache, and loads the bundled fallback asset.
- `LocaleBloc` owns loading events and applies messages to `LocaleService`.
- `LocaleService` is the in-memory runtime source; widgets read strings through `context.tr(...)`.
- The fallback asset is `lib/src/global/mockdata/locale_resources_mock.json` and is declared in `pubspec.yaml`.
- Locale persistence uses `AppStorage`; do not introduce a second SQLite or generated-resource cache.
- `MaterialApp.router` still uses Flutter's built-in material localization delegates for framework strings, while app strings come from `LocaleService`.

## Adding or changing strings

1. Use a stable, namespaced key based on the page/feature and semantic meaning, such as `login.submit` or `settings.api_url`. Use `common.<semantic_name>` only for copy shared across screens.
2. Update the API contract or the bundled JSON fallback when the string must work offline/dev.
3. Consume static UI copy with `context.tr('login.submit', fallback: 'เข้าสู่ระบบ')` in presentation code, then pass the result to `AppText` or another UI property.
4. If the string has parameters, pass them through `context.tr(..., params: {...})` rather than concatenating UI text.
5. Add or update repository/service tests for fallback, cache, and parameter behavior as applicable.

### What must be localized

Use the rule above for screen titles, section/function/form names, labels, hints,
buttons, validation messages, dialogs, snackbars, tooltips, empty states, and loading copy.
`AppText` receives the translated string at the call site; do not add a second translation path inside the shared widget.

Do not localize route paths, API/JSON keys, enum or status codes, asset paths, logs,
test keys, or opaque text returned by the server. If the server returns a localization key,
resolve that key through `context.tr` with a safe fallback.

## Do not

- Do not add `l10n.yaml`, ARB files, generated `AppLocalizations`, or a parallel localization service for an ordinary change.
- Do not make repositories or BLoCs mutate widgets directly; the repository returns data and the BLoC applies it through `LocaleService`.
- Do not hardcode a new language-specific string without a fallback/key plan.
- Do not remove the fallback path when changing API loading.

## Validate

- `flutter analyze`
- Relevant tests under `test/src/core/localization/`
- Verify cold start/cache fallback and at least one widget lookup when UI behavior changes

## Explicit migration exception

If the user explicitly chooses ARB/code generation, treat it as an architecture migration: document the new source of truth, plan coexistence/removal of the JSON pipeline, update `docs/LOCALE.md`, and test both cold-start fallback and runtime locale changes before removing the old path.
