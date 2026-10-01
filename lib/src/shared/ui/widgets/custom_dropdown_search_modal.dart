import 'dart:async';

import 'package:bs_mobile/src/shared/paging/paged_result.dart';
import 'package:bs_mobile/src/shared/ui/widgets/custom_modal_bottom_sheet.dart';
import 'package:flutter/material.dart';

class CustomDropdownSearchModal<T> extends StatefulWidget {
  final String label;
  final String hint;
  final List<T> items;
  final T? value;
  final Widget? prefixIcon;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final void Function(T?)? onSaved;
  final String Function(T)? itemToString;
  final bool enabled;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final void Function(String)? onSubmitted;
  final String searchHint;
  final String? notFoundMessage;
  final bool compact;
  final int pageSize;
  final Future<DropdownSearchPage<T>> Function({
    required int pageNumber,
    required int pageSize,
    String? searchText,
  })?
  onLoadPage;

  const CustomDropdownSearchModal({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.value,
    this.validator,
    this.onSaved,
    this.itemToString,
    this.enabled = true,
    this.focusNode,
    this.nextFocusNode,
    this.onSubmitted,
    this.searchHint = 'Search and select...',
    this.notFoundMessage,
    this.compact = false,
    this.prefixIcon,
    this.pageSize = 20,
    this.onLoadPage,
  });

  @override
  State<CustomDropdownSearchModal<T>> createState() =>
      _CustomDropdownSearchModalState<T>();
}

class _CustomDropdownSearchModalState<T>
    extends State<CustomDropdownSearchModal<T>> {
  final TextEditingController _controller = TextEditingController();

  T? _selectedItem;
  String? _selectedText;

  String _itemText(T item) {
    return widget.itemToString != null
        ? widget.itemToString!(item)
        : item.toString();
  }

  @override
  void initState() {
    super.initState();

    if (widget.value != null) {
      _selectedItem = widget.value;
      _selectedText = _itemText(widget.value as T);
      _controller.text = _selectedText!;
    }
  }

  @override
  void didUpdateWidget(covariant CustomDropdownSearchModal<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      if (widget.value != null) {
        _selectedItem = widget.value;
        _selectedText = _itemText(widget.value as T);
        _controller.text = _selectedText!;
      } else {
        _selectedItem = null;
        _selectedText = null;
        _controller.clear();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openModal() async {
    if (!widget.enabled) return;

    final result = await showCustomModalBottomSheet<T>(
      context: context,
      builder: (_) {
        return _DropdownSearchModal<T>(
          label: widget.label,
          items: widget.items,
          selectedItem: _selectedItem,
          itemToString: widget.itemToString,
          searchHint: widget.searchHint,
          pageSize: widget.pageSize,
          onLoadPage: widget.onLoadPage,
        );
      },
    );

    if (result != null) {
      _selectItem(result);
    }
  }

  void _selectItem(T item) {
    final text = _itemText(item);

    setState(() {
      _selectedItem = item;
      _selectedText = text;
      _controller.text = text;
    });

    widget.onChanged(item);

    if (widget.nextFocusNode != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        widget.nextFocusNode?.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cs = theme.colorScheme;

    final inputVerticalPadding = widget.compact ? 10.0 : 14.0;
    final inputFontSize = widget.compact ? 16.0 : 14.0;

    final borderRadius = widget.compact ? 10.0 : 13.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.compact) ...[
          const SizedBox(height: 6),
          // Row(
          //   children: [
          //     Container(
          //       width: 6,
          //       height: 6,
          //       decoration: BoxDecoration(
          //         color: cs.error,
          //         shape: BoxShape.circle,
          //       ),
          //     ),
          //     const SizedBox(width: 8),
          //     AppText(
          //       text: widget.label,
          //       color: cs.secondary,
          //       fontSize: labelFontSize,
          //       fontWeight: FontWeight.w800,
          //       style: const TextStyle(letterSpacing: 0.5),
          //     ),
          //   ],
          // ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: cs.primaryContainer),
            borderRadius: BorderRadius.circular(borderRadius),
            color: widget.enabled
                ? cs.surface
                : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          child: TextFormField(
            controller: _controller,
            readOnly: true,
            enabled: widget.enabled,
            focusNode: widget.focusNode,
            validator: widget.validator == null
                ? null
                : (_) => widget.validator!(_selectedItem),
            onSaved: widget.onSaved == null
                ? null
                : (_) => widget.onSaved!(_selectedItem),
            onTap: _openModal,
            style: TextStyle(
              color: widget.enabled ? cs.onSurface : cs.onSurfaceVariant,
              fontSize: inputFontSize,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.72),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: inputVerticalPadding,
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: Icon(
                Icons.keyboard_arrow_down,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownSearchModal<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final T? selectedItem;
  final String Function(T)? itemToString;
  final String searchHint;
  final int pageSize;
  final Future<DropdownSearchPage<T>> Function({
    required int pageNumber,
    required int pageSize,
    String? searchText,
  })?
  onLoadPage;

  const _DropdownSearchModal({
    required this.label,
    required this.items,
    required this.selectedItem,
    required this.itemToString,
    required this.searchHint,
    required this.pageSize,
    required this.onLoadPage,
  });

  @override
  State<_DropdownSearchModal<T>> createState() =>
      _DropdownSearchModalState<T>();
}

class _DropdownSearchModalState<T> extends State<_DropdownSearchModal<T>> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late List<T> _loadedItems;
  late List<T> _filteredItems;
  Timer? _searchDebounce;
  int _pageNumber = 0;
  int _totalPages = 1;
  bool _isLoadingPage = false;
  String _query = '';

  bool get _isRemotePaging => widget.onLoadPage != null;

  bool get _hasMore => _pageNumber < _totalPages;

  String _itemText(T item) {
    return widget.itemToString != null
        ? widget.itemToString!(item)
        : item.toString();
  }

  @override
  void initState() {
    super.initState();
    _loadedItems = List.from(widget.items);
    _filteredItems = List.from(widget.items);

    if (_isRemotePaging) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPage(reset: true);
      });
    }
  }

  @override
  void didUpdateWidget(covariant _DropdownSearchModal<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isRemotePaging && oldWidget.items != widget.items) {
      _loadedItems = List.from(widget.items);
      _applyLocalFilter(_query);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filter(String query) {
    _query = query;

    if (_isRemotePaging) {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) {
          return;
        }
        _loadPage(reset: true);
      });
      return;
    }

    _applyLocalFilter(query);
  }

  void _applyLocalFilter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(_loadedItems);
        return;
      }

      _filteredItems = _loadedItems.where((item) {
        return _itemText(item).toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _loadPage({required bool reset}) async {
    final loader = widget.onLoadPage;
    if (loader == null || _isLoadingPage) {
      return;
    }

    if (!reset && !_hasMore) {
      return;
    }

    final pageNumber = reset ? 1 : _pageNumber + 1;
    final searchText = _query.trim().isEmpty ? null : _query.trim();

    setState(() {
      _isLoadingPage = true;
      if (reset) {
        _pageNumber = 0;
        _totalPages = 1;
        _loadedItems = [];
        _filteredItems = [];
      }
    });

    try {
      final page = await loader(
        pageNumber: pageNumber,
        pageSize: widget.pageSize,
        searchText: searchText,
      );

      if (!mounted) {
        return;
      }

      final existingTexts = _loadedItems.map(_itemText).toSet();

      setState(() {
        _loadedItems = [
          ..._loadedItems,
          ...page.items.where(
            (item) => !existingTexts.contains(_itemText(item)),
          ),
        ];
        _filteredItems = List.from(_loadedItems);
        _pageNumber = page.pageNumber;
        _totalPages = page.totalPages <= 0 ? page.pageNumber : page.totalPages;
        _isLoadingPage = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoadingPage = false);
      // CustomShowAlert.showWarning(error.toString());
    }
  }

  void _handleSubmit(String value) {
    final exactMatch = _loadedItems.where((item) {
      return _itemText(item).toLowerCase() == value.toLowerCase();
    }).toList();

    if (exactMatch.isNotEmpty) {
      Navigator.pop(context, exactMatch.first);
    } else {
      // CustomShowAlert.showError(
      //   '${widget.label} "$value" not found',
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final showPagingFooter = _isRemotePaging && (_isLoadingPage || _hasMore);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  onChanged: _filter,
                  onSubmitted: _handleSubmit,
                  style: TextStyle(fontSize: 14, color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _filteredItems.isEmpty && !_isLoadingPage
                    ? Center(
                        child: Text(
                          'No data found',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          final metrics = notification.metrics;
                          if (_isRemotePaging &&
                              !_isLoadingPage &&
                              _hasMore &&
                              metrics.pixels >= metrics.maxScrollExtent - 80) {
                            _loadPage(reset: false);
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: scrollController,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount:
                              _filteredItems.length +
                              (showPagingFooter ? 1 : 0),
                          itemBuilder: (_, index) {
                            if (index == _filteredItems.length) {
                              return _PagingFooter(
                                isLoading: _isLoadingPage,
                                hasMore: _hasMore,
                                onLoadMore: () => _loadPage(reset: false),
                              );
                            }

                            final item = _filteredItems[index];
                            final text = _itemText(item);

                            final isSelected = widget.selectedItem == item;

                            return ListTile(
                              tileColor: isSelected
                                  ? cs.primary.withValues(
                                      alpha: theme.brightness == Brightness.dark
                                          ? 0.16
                                          : 0.08,
                                    )
                                  : Colors.transparent,
                              title: Text(
                                text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: cs.onSurface,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle, color: cs.primary)
                                  : null,
                              onTap: () {
                                Navigator.pop(context, item);
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PagingFooter extends StatelessWidget {
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;

  const _PagingFooter({
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
          ),
        ),
      );
    }

    if (!hasMore) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: OutlinedButton.icon(
        onPressed: onLoadMore,
        icon: const Icon(Icons.expand_more_rounded),
        label: const Text('โหลดเพิ่ม'),
      ),
    );
  }
}
