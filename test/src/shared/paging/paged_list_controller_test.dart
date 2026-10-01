import 'package:bs_mobile/src/shared/paging/paged_list_controller.dart';
import 'package:bs_mobile/src/shared/paging/paged_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PagedListController', () {
    late List<({int pageNumber, int pageSize, String? searchText})> calls;

    PagedLoader<int> loaderOf({
      required Map<int, List<int>> pages,
      int totalPages = 3,
      Object? throwOnPage,
      Duration delay = Duration.zero,
    }) {
      return ({
        required int pageNumber,
        required int pageSize,
        String? searchText,
      }) async {
        calls.add((
          pageNumber: pageNumber,
          pageSize: pageSize,
          searchText: searchText,
        ));
        if (delay > Duration.zero) {
          await Future<void>.delayed(delay);
        }
        if (throwOnPage != null && pageNumber == throwOnPage) {
          throw Exception('load failed page $pageNumber');
        }
        return PagedResult<int>(
          items: pages[pageNumber] ?? const <int>[],
          pageNumber: pageNumber,
          totalPages: totalPages,
        );
      };
    }

    setUp(() {
      calls = <({int pageNumber, int pageSize, String? searchText})>[];
    });

    test('loadInitial fetches page 1 and sets items', () async {
      final controller = PagedListController<int>(
        loader: loaderOf(
          pages: {
            1: [1, 2],
            2: [3, 4],
          },
        ),
        pageSize: 2,
      );

      await controller.loadInitial();

      expect(controller.items, [1, 2]);
      expect(controller.pageNumber, 1);
      expect(controller.totalPages, 3);
      expect(controller.hasMore, isTrue);
      expect(controller.isLoading, isFalse);
      expect(calls.single.pageNumber, 1);
      controller.dispose();
    });

    test('loadMore appends next page', () async {
      final controller = PagedListController<int>(
        loader: loaderOf(
          pages: {
            1: [1, 2],
            2: [3, 4],
          },
        ),
        pageSize: 2,
      );

      await controller.loadInitial();
      await controller.loadMore();

      expect(controller.items, [1, 2, 3, 4]);
      expect(controller.pageNumber, 2);
      expect(calls.map((c) => c.pageNumber), [1, 2]);
      controller.dispose();
    });

    test('hasMore is false on last page', () async {
      final controller = PagedListController<int>(
        loader: loaderOf(
          pages: {
            1: [1],
            2: [2],
          },
          totalPages: 2,
        ),
        pageSize: 1,
      );

      await controller.loadInitial();
      await controller.loadMore();

      expect(controller.hasMore, isFalse);
      await controller.loadMore();
      expect(calls.length, 2, reason: 'loadMore ignored when !hasMore');
      controller.dispose();
    });

    test('double-fetch is ignored while in flight', () async {
      final controller = PagedListController<int>(
        loader: loaderOf(
          pages: {
            1: [1, 2],
            2: [3],
          },
          delay: const Duration(milliseconds: 40),
        ),
        pageSize: 2,
      );

      final first = controller.loadInitial();
      final second = controller.loadInitial();
      await Future.wait([first, second]);

      expect(calls.length, 1);
      expect(controller.items, [1, 2]);
      controller.dispose();
    });

    test('refresh replaces items from page 1', () async {
      var generation = 0;
      final controller = PagedListController<int>(
        loader:
            ({
              required int pageNumber,
              required int pageSize,
              String? searchText,
            }) async {
              generation++;
              return PagedResult<int>(
                items: generation == 1 ? [1, 2] : [10, 20],
                pageNumber: pageNumber,
                totalPages: 1,
              );
            },
        pageSize: 2,
      );

      await controller.loadInitial();
      expect(controller.items, [1, 2]);

      await controller.refresh();
      expect(controller.items, [10, 20]);
      expect(controller.pageNumber, 1);
      controller.dispose();
    });

    test('error on initial load sets error and keeps items empty', () async {
      final controller = PagedListController<int>(
        loader: loaderOf(pages: const {}, throwOnPage: 1),
      );

      await controller.loadInitial();

      expect(controller.error, isA<Exception>());
      expect(controller.items, isEmpty);
      expect(controller.isLoading, isFalse);
      controller.dispose();
    });

    test('error on loadMore keeps previous items', () async {
      final controller = PagedListController<int>(
        loader: loaderOf(
          pages: {
            1: [1, 2],
          },
          totalPages: 3,
          throwOnPage: 2,
        ),
        pageSize: 2,
      );

      await controller.loadInitial();
      await controller.loadMore();

      expect(controller.items, [1, 2]);
      expect(controller.error, isA<Exception>());
      expect(controller.pageNumber, 1);
      controller.dispose();
    });

    test('setSearch resets and passes searchText', () async {
      final controller = PagedListController<int>(
        loader: loaderOf(
          pages: {
            1: [100],
          },
          totalPages: 1,
        ),
      );

      await controller.loadInitial();
      await controller.setSearch('abc');

      expect(calls.last.searchText, 'abc');
      expect(controller.searchText, 'abc');
      expect(controller.items, [100]);
      controller.dispose();
    });

    test('hasMore fallback when totalPages is 0 and page is full', () async {
      final controller = PagedListController<int>(
        loader:
            ({
              required int pageNumber,
              required int pageSize,
              String? searchText,
            }) async {
              return PagedResult<int>(
                items: List<int>.generate(pageSize, (i) => i + pageNumber * 10),
                pageNumber: pageNumber,
                totalPages: 0,
              );
            },
        pageSize: 2,
      );

      await controller.loadInitial();
      expect(controller.hasMore, isTrue);

      await controller.loadMore();
      expect(controller.pageNumber, 2);
      expect(controller.items.length, 4);
      controller.dispose();
    });
  });
}
