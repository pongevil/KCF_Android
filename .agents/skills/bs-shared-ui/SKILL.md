---
name: bs-shared-ui
description: >-
  Builds or extends BS-Mobile shared UI using existing widgets, theme tokens,
  and Shared Widgets rules. Use when implementing screens, forms, dropdowns,
  buttons, cards, or when tempted to create a new TextField/Dropdown/Button
  inside features/.
---

# bs-shared-ui

## Before coding

1. Read [docs/SHARED_WIDGETS.md](../../../docs/SHARED_WIDGETS.md)
2. Check `lib/src/shared/ui/widgets/` for a close match
3. Check `lib/src/core/helpers/`, `lib/src/global/models/`, and the target feature for existing helpers, formatters, and models before creating any local class
4. Map mockup colors to `context.colorScheme` / `context.appTheme` — do not copy hex

## Decision tree

1. Nearby shared widget exists?
   - Parameters enough → use it
   - Missing parameter → add optional param + default on the shared widget
   - Never duplicate TextField / Dropdown / Button in `features/`
2. Truly domain-only chrome → `features/<name>/presentation/widgets/`
3. Brand-new reusable control → add under `lib/src/shared/ui/widgets/` and export barrel

## Checklist

1. Prefer shared widgets (`CustomTextField`, `CustomButton`, dropdowns, cards, …)
2. Dropdown: pick one of the three shared widgets in the SHARED_WIDGETS table:
   - `Customdropdown` for short, local lists
   - `CustomDropdownSearch` for inline search
   - `CustomDropdownSearchModal` for long/mobile lists or remote paging via `onLoadPage`
   Do not create or reference a separate `CustomDropdownPaging` widget.
3. Alerts via `CustomShowAlert` in presentation only
4. Loading via `CustomLoading` in presentation only
5. Import `package:bs_mobile/src/...`
6. **Focus (always on forms / text fields)**
   - Own a `FocusNode` per field in the page `State` — dispose in `dispose()`
   - Pass `focusNode:` into `CustomTextField` / `CustomDropdownSearch` (and `nextFocusNode:` when chaining)
   - On submit / scanner done: move focus with `nextFocus.requestFocus()` or `FocusScope.of(context).nextFocus()` via `onFieldSubmitted` / `textInputAction`
   - PDA / soft keyboard: respect `SoftKeyboardController` (`lib/src/shared/ui/keyboard/`); fields that must show keyboard use force-keyboard on focus when needed
   - Do not leave anonymous TextFields without a focus plan (scanner screens especially)
7. **UI strings / localization**
   - Static user-visible strings must use `context.tr('<page-or-feature>.<semantic_name>', fallback: '<actual display text>')` before passing them to `AppText`, `Text`, labels, hints, buttons, validation, dialogs, snackbars, tooltips, or empty/loading states
   - Use `common.<semantic_name>` only for genuinely cross-screen copy
   - Do not localize route/API keys, enum codes, asset paths, logs, test keys, or opaque server-provided content
8. **Modal / dialog with input**
   - Open bottom sheets through `showCustomModalBottomSheet<T>()`; do not call `showModalBottomSheet` directly
   - Pass the sheet content through `builder`; the helper owns `isScrollControlled`, transparent background, keyboard `AnimatedPadding`, `SafeArea(top: false)`, and keyboard dismissal
   - Return a scrollable sheet (`SingleChildScrollView`, `ListView`, or `DraggableScrollableSheet` with its provided `scrollController`)
   - Do not add a second `viewInsets.bottom` padding; keep save/confirm actions reachable while the keyboard is open
   - Create and dispose every `FocusNode` and `ScrollController` owned by the sheet

## Reuse / model boundary

- Search and reuse before creating a feature-local widget, formatter, helper, or model.
- Extend the shared implementation when it is missing a safe optional parameter; do not clone it into the page.
- Keep one canonical model per API contract. `Request` and `Response` models may be separate when they represent different contracts; a list may use `List<ExistingResponseModel>` and a wrapper may be separate when it owns pagination/metadata.
- Create a UI model only when it contains UI-specific state/data and name it by that responsibility.

## Validate

- `flutter analyze`
- Widget tests when behavior/params change meaningfully
- Confirm focus chain: enter / scan advances to the next intended field
