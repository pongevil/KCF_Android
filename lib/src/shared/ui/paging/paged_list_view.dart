import 'package:bs_mobile/src/shared/paging/paged_list_controller.dart';
import 'package:flutter/material.dart';

typedef PagedItemBuilder<T> =
    Widget Function(BuildContext context, T item, int index);

typedef PagedErrorBuilder =
    Widget Function(BuildContext context, Object error, VoidCallback retry);

/// Infinite-scroll [ListView] shell. Owns scroll-near-end → [loadMore] only.
///
/// All chrome (empty, loading, error, footers) is supplied by the caller —
/// no project-specific theme or copy is hard-coded here.
class PagedListView<T> extends StatelessWidget {
  const PagedListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.separatorBuilder,
    this.emptyBuilder,
    this.initialLoadingBuilder,
    this.loadMoreFooterBuilder,
    this.errorBuilder,
    this.noMoreFooterBuilder,
    this.scrollThreshold = 40,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.primary,
    this.controllerScroll,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  });

  final PagedListController<T> controller;
  final PagedItemBuilder<T> itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder? initialLoadingBuilder;
  final WidgetBuilder? loadMoreFooterBuilder;
  final PagedErrorBuilder? errorBuilder;
  final WidgetBuilder? noMoreFooterBuilder;

  /// Distance from the end (in pixels) that triggers [PagedListController.loadMore].
  final double scrollThreshold;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool? primary;
  final ScrollController? controllerScroll;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isInitialLoading && controller.items.isEmpty) {
          return initialLoadingBuilder?.call(context) ??
              const SizedBox.shrink();
        }

        if (controller.error != null && controller.items.isEmpty) {
          final err = controller.error!;
          return errorBuilder?.call(context, err, () {
                controller.loadInitial();
              }) ??
              const SizedBox.shrink();
        }

        if (controller.items.isEmpty) {
          return emptyBuilder?.call(context) ?? const SizedBox.shrink();
        }

        final showFooter =
            controller.isLoadingMore ||
            controller.error != null ||
            (noMoreFooterBuilder != null && !controller.hasMore) ||
            (loadMoreFooterBuilder != null && controller.hasMore);

        final itemCount = controller.items.length + (showFooter ? 1 : 0);

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is! ScrollUpdateNotification &&
                notification is! OverscrollNotification) {
              return false;
            }
            final metrics = notification.metrics;
            if (!controller.isLoading &&
                controller.hasMore &&
                metrics.maxScrollExtent > 0 &&
                metrics.pixels >= metrics.maxScrollExtent - scrollThreshold) {
              controller.loadMore();
            }
            return false;
          },
          child: separatorBuilder != null
              ? ListView.separated(
                  controller: controllerScroll,
                  padding: padding,
                  physics: physics,
                  shrinkWrap: shrinkWrap,
                  primary: primary,
                  keyboardDismissBehavior: keyboardDismissBehavior,
                  itemCount: itemCount,
                  separatorBuilder: (context, index) {
                    if (index >= controller.items.length - 1 && showFooter) {
                      return const SizedBox.shrink();
                    }
                    return separatorBuilder!(context, index);
                  },
                  itemBuilder: (context, index) =>
                      _buildItem(context, index, showFooter),
                )
              : ListView.builder(
                  controller: controllerScroll,
                  padding: padding,
                  physics: physics,
                  shrinkWrap: shrinkWrap,
                  primary: primary,
                  keyboardDismissBehavior: keyboardDismissBehavior,
                  itemCount: itemCount,
                  itemBuilder: (context, index) =>
                      _buildItem(context, index, showFooter),
                ),
        );
      },
    );
  }

  Widget _buildItem(BuildContext context, int index, bool showFooter) {
    if (index < controller.items.length) {
      return itemBuilder(context, controller.items[index], index);
    }

    if (controller.isLoadingMore) {
      return loadMoreFooterBuilder?.call(context) ?? const SizedBox.shrink();
    }

    if (controller.error != null) {
      final err = controller.error!;
      return errorBuilder?.call(context, err, () {
            controller.loadMore();
          }) ??
          const SizedBox.shrink();
    }

    if (!controller.hasMore) {
      return noMoreFooterBuilder?.call(context) ?? const SizedBox.shrink();
    }

    // hasMore but not loading — optional hint footer
    return loadMoreFooterBuilder?.call(context) ?? const SizedBox.shrink();
  }
}
