import 'package:flutter/foundation.dart';

import 'paged_result.dart';

/// Owns paging state for infinite-scroll lists. UI-agnostic.
///
/// [hasMore] uses `pageNumber < totalPages`. When [totalPages] is unknown
/// (`<= 0`), falls back to "maybe more" if the last page returned a full
/// [pageSize] of items.
class PagedListController<T> extends ChangeNotifier {
  PagedListController({required PagedLoader<T> loader, this.pageSize = 20})
    : _loader = loader;

  final PagedLoader<T> _loader;
  final int pageSize;

  final List<T> _items = <T>[];
  int _pageNumber = 0;
  int _totalPages = 0;
  String? _searchText;
  Object? _error;
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  bool _inFlight = false;
  bool _disposed = false;

  List<T> get items => List<T>.unmodifiable(_items);
  int get pageNumber => _pageNumber;
  int get totalPages => _totalPages;
  String? get searchText => _searchText;
  Object? get error => _error;
  bool get isInitialLoading => _isInitialLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoading => _isInitialLoading || _isLoadingMore;

  bool get hasMore {
    if (_totalPages > 0) {
      return _pageNumber < _totalPages;
    }
    // Unknown total: assume more if last fetch filled the page.
    if (_pageNumber == 0) return true;
    return _items.isNotEmpty && _items.length >= _pageNumber * pageSize;
  }

  Future<void> loadInitial({String? searchText}) async {
    if (searchText != null) {
      _searchText = searchText;
    }
    await _load(reset: true);
  }

  Future<void> loadMore() async {
    if (!hasMore || _inFlight || _isInitialLoading) return;
    await _load(reset: false);
  }

  Future<void> refresh() async {
    await _load(reset: true);
  }

  Future<void> setSearch(String? searchText) async {
    _searchText = searchText;
    await _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (_disposed) return;
    if (_inFlight) return;

    _inFlight = true;
    _error = null;

    if (reset) {
      _isInitialLoading = true;
      _isLoadingMore = false;
    } else {
      _isLoadingMore = true;
      _isInitialLoading = false;
    }
    _notify();

    final nextPage = reset ? 1 : _pageNumber + 1;

    try {
      final result = await _loader(
        pageNumber: nextPage,
        pageSize: pageSize,
        searchText: _searchText,
      );

      if (_disposed) return;

      if (reset) {
        _items
          ..clear()
          ..addAll(result.items);
      } else {
        _items.addAll(result.items);
      }

      _pageNumber = result.pageNumber;
      _totalPages = result.totalPages;
      _error = null;
    } catch (e) {
      if (_disposed) return;
      _error = e;
    } finally {
      _inFlight = false;
      _isInitialLoading = false;
      _isLoadingMore = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
