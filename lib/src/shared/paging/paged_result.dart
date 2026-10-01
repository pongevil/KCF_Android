/// One page of remote/local list data (1-based [pageNumber]).
class PagedResult<T> {
  final List<T> items;
  final int pageNumber;
  final int totalPages;
  final int? totalRecords;

  const PagedResult({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
    this.totalRecords,
  });
}

/// Fetches a single page. Used by [PagedListController] and dropdown search.
typedef PagedLoader<T> =
    Future<PagedResult<T>> Function({
      required int pageNumber,
      required int pageSize,
      String? searchText,
    });

/// Legacy alias used by dropdown search widgets.
typedef DropdownSearchPage<T> = PagedResult<T>;
