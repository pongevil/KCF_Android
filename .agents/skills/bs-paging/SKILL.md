---
name: bs-paging
description: >-
  Implements infinite-scroll lists with PagedListController and PagedListView
  (logic middle layer, UI builders at the feature). Use when building paged
  lists, load-more scroll, remote search lists, or DropdownSearchPage-style
  paging outside dropdowns.
---

# bs-paging

## Before coding

1. Read [docs/PAGING.md](../../../docs/PAGING.md)
2. Check [docs/BLOC_PATTERN.md § Pagination](../../../docs/BLOC_PATTERN.md#pagination--load-more)
3. Reuse `lib/src/shared/paging/` + `lib/src/shared/ui/paging/`

## Checklist

1. Use this exception only for a simple list/search/refresh flow; use Command BLoC when paging participates in business validation, permissions, multi-step flow, or other feature state
2. Map API page payload to `PagedResult<T>` at the repository boundary
3. Create `PagedListController` with a `PagedLoader` (`pageNumber`, `pageSize`, `searchText`); the loader is the only repository-call boundary in the page
4. Call `loadInitial()` in `initState`; `dispose()` the controller
5. Let the controller exclusively own items/page/loading/error — do not duplicate those fields in the page
6. Render with `PagedListView` + feature `itemBuilder`
7. Supply empty / loading / error / footer builders in the feature (no project chrome baked into the shell)
8. Search UI (if any) lives outside the list — call `controller.setSearch(...)` (debounce recommended)
9. Pull-to-refresh: wrap `RefreshIndicator(onRefresh: controller.refresh)`

## Do not

- Re-implement scroll-near-end + page counters in each feature
- Mix Bloc-owned paging state with controller-owned paging state on the same page
- Call the repository from scroll/search callbacks outside `PagedLoader`
- Hardcode Thai copy / brand colors inside the shared paging shell

## Validate

- `flutter analyze`
- Controller unit tests under `test/src/shared/paging/` when changing core paging
