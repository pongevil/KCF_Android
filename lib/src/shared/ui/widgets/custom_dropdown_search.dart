import 'dart:async';
import 'package:bs_mobile/index.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class CustomDropdownSearch<T> extends StatefulWidget {
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
  final String searchHint;
  final FocusNode? nextFocusNode;
  final void Function(String)? onSubmitted;
  final String? notFoundMessage;
  final bool compact;
  final bool openDropdownOnFocus;
  final bool selectAllOnFocus;
  final TextEditingController? controller;

  /// การซ่อน soft keyboard จัดการแบบ global ผ่าน `SoftKeyboardController`
  /// (custom TextInputControl) แล้ว flag นี้จึงไม่มีผลกับตัว field โดยตรง
  /// เก็บไว้เพื่อความเข้ากันได้ของ call site เดิม
  final bool respectSoftKeyboard;

  final int pageSize;
  final Future<DropdownSearchPage<T>> Function({
    required int pageNumber,
    required int pageSize,
    String? searchText,
  })?
  onLoadPage;

  const CustomDropdownSearch({
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
    this.searchHint = 'Search and select...',
    this.nextFocusNode,
    this.onSubmitted,
    this.notFoundMessage,
    this.compact = false,
    this.prefixIcon,
    this.openDropdownOnFocus = false,
    this.selectAllOnFocus = false,
    this.respectSoftKeyboard = false,
    this.pageSize = 20,
    this.onLoadPage,
    this.controller,
  });

  @override
  State<CustomDropdownSearch<T>> createState() =>
      _CustomDropdownSearchState<T>();
}

class _CustomDropdownSearchState<T> extends State<CustomDropdownSearch<T>> {
  final TextEditingController _searchController = TextEditingController();
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _anchorKey = GlobalKey();
  final Object _tapGroupId = Object();

  List<T> _loadedItems = [];
  List<T> _filteredItems = [];
  bool _isDropdownOpen = false;
  T? _selectedItem;
  String? _selectedValue;
  Timer? _searchDebounce;
  int _pageNumber = 0;
  int _totalPages = 1;
  bool _isLoadingPage = false;
  bool _hideOverlayQueued = false;
  String _query = '';

  bool get _isRemotePaging => widget.onLoadPage != null;

  bool get _hasMore => _pageNumber < _totalPages;

  List<T> get _sourceItems => _isRemotePaging ? _loadedItems : widget.items;

  TextEditingController get _fieldController =>
      widget.controller ?? _searchController;

  String _itemText(T item) {
    return widget.itemToString != null
        ? widget.itemToString!(item)
        : item.toString();
  }

  void _hideOverlay() {
    _isDropdownOpen = false;
    if (!_overlayController.isShowing) {
      return;
    }

    // OverlayPortalController.hide() cannot be called while Flutter is in
    // the persistent-callbacks phase (for example, while a FutureBuilder is
    // rebuilding this widget). Defer only that case so normal user actions
    // still close the dropdown immediately.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_hideOverlayQueued) {
        return;
      }

      _hideOverlayQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hideOverlayQueued = false;
        if (!mounted || _isDropdownOpen) {
          return;
        }
        if (_overlayController.isShowing) {
          _overlayController.hide();
        }
      });
      return;
    }

    _overlayController.hide();
  }

  @override
  void initState() {
    super.initState();
    _loadedItems = List.from(widget.items);
    _filteredItems = List.from(_sourceItems);

    final initialValue = widget.value;
    if (initialValue != null) {
      _selectedItem = initialValue;
      _selectedValue = _itemText(initialValue);
      _fieldController.text = _selectedValue!;
    }

    if (widget.focusNode != null) {
      widget.focusNode!.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    if (widget.focusNode != null) {
      widget.focusNode!.removeListener(_onFocusChanged);
    }
    _hideOverlay();
    _searchController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (widget.focusNode == null) {
      return;
    }

    if (widget.focusNode!.hasFocus) {
      if (!mounted) return;
      setState(() {});
      if (widget.selectAllOnFocus && _fieldController.text.isNotEmpty) {
        TextFieldSelectionHelper.selectAllAfterFrame(_fieldController);
      }
      if (widget.openDropdownOnFocus) {
        _openDropdown();
      }
      return;
    }

    _closeDropdown();
    if (!mounted) return;
    setState(() {});
  }

  void _closeDropdown() {
    if (!_isDropdownOpen && !_overlayController.isShowing) {
      return;
    }

    _hideOverlay();
    if (mounted) setState(() {});
  }

  void _openDropdown() {
    if (!widget.enabled || !mounted) {
      return;
    }

    if (!_isDropdownOpen) {
      _isDropdownOpen = true;
      // A new open request in the same frame must not be closed by a stale
      // deferred hide callback.
      _hideOverlayQueued = false;
      _overlayController.show();
    } else if (mounted) {
      setState(() {});
    }

    if (_isRemotePaging && _loadedItems.isEmpty) {
      _loadPage(reset: true);
    }
  }

  void _onFieldTap() {
    if (widget.selectAllOnFocus && _fieldController.text.isNotEmpty) {
      TextFieldSelectionHelper.selectAll(_fieldController);
    }
    _openDropdown();
  }

  void _syncExternalValue(T? value) {
    if (value != null) {
      _selectedItem = value;
      _selectedValue = _itemText(value);
      if (_fieldController.text != _selectedValue) {
        _fieldController.text = _selectedValue!;
      }
      return;
    }

    _selectedItem = null;
    _selectedValue = null;
    if (_fieldController.text.isNotEmpty) {
      _fieldController.clear();
    }
    _query = '';
    _filteredItems = List.from(_sourceItems);
    if (_isDropdownOpen) {
      _hideOverlay();
    }
  }

  bool _shouldResetDisplay(CustomDropdownSearch<T> oldWidget) {
    if (oldWidget.value != widget.value) {
      return true;
    }

    return widget.value == null &&
        widget.items.isEmpty &&
        oldWidget.items.isNotEmpty &&
        _fieldController.text.isNotEmpty;
  }

  @override
  void didUpdateWidget(CustomDropdownSearch<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isRemotePaging && oldWidget.items != widget.items) {
      _loadedItems = List.from(widget.items);
      _applyLocalFilter(_query);
    }

    if (_isRemotePaging && oldWidget.items != widget.items) {
      _loadedItems = List.from(widget.items);
      _filteredItems = List.from(_loadedItems);
    }

    // Parent callbacks can echo our selection (including null while typing).
    // Only a different external value should reset the current search.
    if (_shouldResetDisplay(oldWidget) && widget.value != _selectedItem) {
      _syncExternalValue(widget.value);
    }

    if (oldWidget.focusNode != widget.focusNode) {
      if (oldWidget.focusNode != null) {
        try {
          oldWidget.focusNode!.removeListener(_onFocusChanged);
        } catch (_) {}
      }
      if (widget.focusNode != null) {
        try {
          widget.focusNode!.addListener(_onFocusChanged);
        } catch (_) {}
      }
    } else if (oldWidget.openDropdownOnFocus != widget.openDropdownOnFocus &&
        widget.focusNode != null) {
      try {
        widget.focusNode!.removeListener(_onFocusChanged);
        widget.focusNode!.addListener(_onFocusChanged);
      } catch (_) {}
    }
  }

  List<T> _findExactMatches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return <T>[];
    }

    return _sourceItems.where((item) {
      final text = _itemText(item).toLowerCase();
      return text == normalized ||
          text.startsWith('$normalized -') ||
          text.startsWith('$normalized ');
    }).toList();
  }

  bool _isAlreadySelected(String query) {
    if (_selectedItem == null || _selectedValue == null) {
      return false;
    }

    return _selectedValue!.toLowerCase() == query.trim().toLowerCase();
  }

  void _filterItems(String query) {
    _query = query;

    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty && _selectedItem != null) {
      setState(() {
        _selectedItem = null;
        _selectedValue = null;
      });
      widget.onChanged(null);
    } else if (_selectedValue != null &&
        _selectedValue!.toLowerCase() != query.toLowerCase()) {
      setState(() {
        _selectedItem = null;
        _selectedValue = null;
      });
      widget.onChanged(null);
    }

    if (!_isDropdownOpen) {
      _openDropdown();
    }

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
        _filteredItems = List.from(widget.items);
        return;
      }

      _filteredItems = widget.items.where((item) {
        final itemText = _itemText(item);
        return itemText.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _loadPage({required bool reset, String? searchText}) async {
    final loader = widget.onLoadPage;
    if (loader == null || _isLoadingPage) {
      return;
    }

    if (!reset && !_hasMore) {
      return;
    }

    final pageNumber = reset ? 1 : _pageNumber + 1;
    final query = searchText ?? _query;
    final normalizedQuery = query.trim().isEmpty ? null : query.trim();

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
        searchText: normalizedQuery,
      );

      if (!mounted) {
        return;
      }

      final existingTexts = _loadedItems.map(_itemText).toSet();
      final mergedItems = [
        ..._loadedItems,
        ...page.items.where((item) => !existingTexts.contains(_itemText(item))),
      ];

      // Prefer API totalPages; if missing, keep loading while pages are full.
      var totalPages = page.totalPages;
      if (totalPages <= 0) {
        totalPages = page.items.length >= widget.pageSize
            ? page.pageNumber + 1
            : page.pageNumber;
      }

      setState(() {
        _loadedItems = mergedItems;
        _filteredItems = List.from(_loadedItems);
        _pageNumber = page.pageNumber;
        _totalPages = totalPages;
        _isLoadingPage = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoadingPage = false);
    }
  }

  void _selectItem(T item, {bool notify = true}) {
    final itemText = _itemText(item);
    final isSameSelection = _selectedItem == item && _selectedValue == itemText;

    setState(() {
      _selectedItem = item;
      _selectedValue = itemText;
      _fieldController.text = itemText;
      _query = '';
      _isDropdownOpen = false;
      _filteredItems = List.from(_sourceItems);
    });
    _hideOverlay();

    if (notify && !isSameSelection) {
      widget.onChanged(item);
    }

    if (widget.nextFocusNode != null) {
      try {
        widget.nextFocusNode!.requestFocus();
      } catch (_) {}
    }
  }

  Future<void> _handleSubmitted(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }

    if (_isAlreadySelected(trimmed)) {
      return;
    }

    var exactMatch = _findExactMatches(trimmed);

    if (exactMatch.isEmpty && _isRemotePaging) {
      await _loadPage(reset: true, searchText: trimmed);
      exactMatch = _findExactMatches(trimmed);

      if (exactMatch.isEmpty && _filteredItems.length == 1) {
        exactMatch = [_filteredItems.first];
      }
    }

    if (exactMatch.isNotEmpty) {
      _selectItem(exactMatch.first);
      return;
    }

    final message =
        widget.notFoundMessage ??
        '${widget.label} "$value" not found. Please scan a valid code.';
    CustomShowAlert.showWarning(message);

    _fieldController.text = trimmed;
    widget.onChanged(null);
    setState(() {
      _selectedItem = null;
      _selectedValue = null;
      _filteredItems = List.from(_sourceItems);
    });
    _hideOverlay();

    if (widget.focusNode != null) {
      try {
        widget.focusNode!.requestFocus();
      } catch (_) {}
    }

    TextFieldSelectionHelper.selectAllAfterFrame(_fieldController);

    if (widget.onSubmitted != null) {
      widget.onSubmitted!(trimmed);
    }
  }

  Widget _buildDropdownList(ThemeData theme, ColorScheme cs) {
    final showPagingFooter = _isRemotePaging && (_isLoadingPage || _hasMore);

    if (_filteredItems.isEmpty && !_isLoadingPage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No data found',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
          ),
        ),
      );
    }

    final itemCount = _filteredItems.length + (showPagingFooter ? 1 : 0);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is! ScrollUpdateNotification &&
            notification is! OverscrollNotification) {
          return false;
        }
        final metrics = notification.metrics;
        if (_isRemotePaging &&
            !_isLoadingPage &&
            _hasMore &&
            metrics.maxScrollExtent > 0 &&
            metrics.pixels >= metrics.maxScrollExtent - 40) {
          _loadPage(reset: false);
        }
        // Keep the overlay list's drag notification inside the dropdown.
        // Otherwise an ancestor form with keyboardDismissBehavior.onDrag
        // unfocuses this field and closes the overlay as soon as scrolling
        // starts.
        return true;
      },
      child: ListView.builder(
        primary: false,
        padding: EdgeInsets.zero,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= _filteredItems.length) {
            return _DropdownPagingFooter(
              isLoading: _isLoadingPage,
              hasMore: _hasMore,
              onLoadMore: () => _loadPage(reset: false),
            );
          }

          final item = _filteredItems[index];
          final itemText = _itemText(item);

          return Material(
            color: Colors.transparent,
            child: ListTile(
              tileColor: itemText == _selectedValue
                  ? cs.primary.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.16 : 0.08,
                    )
                  : Colors.transparent,
              title: Text(
                itemText,
                style: TextStyle(fontSize: 14, color: cs.onSurface),
              ),
              onTap: () => _selectItem(item),
              dense: true,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasFocus = widget.focusNode?.hasFocus ?? false;
    final isActive = _isDropdownOpen || hasFocus;
    final containerColor = widget.enabled
        ? cs.surface
        : cs.surfaceContainerHighest.withValues(alpha: 0.5);
    final iconColor = isActive ? cs.primaryContainer : cs.onSurfaceVariant;
    final inputFontSize = widget.compact ? 16.0 : 14.0;
    final borderRadiusValue = widget.compact ? 10.0 : 13.0;
    final inputBorderRadius = BorderRadius.circular(borderRadiusValue);
    final enabledBorderColor = cs.primaryContainer;
    final focusedBorderColor = cs.primaryContainer;
    final fieldFillColor = isActive ? cs.surface : containerColor;
    final activeBorderColor = isActive
        ? focusedBorderColor
        : enabledBorderColor;
    final boxShadow = widget.compact
        ? <BoxShadow>[]
        : [
            BoxShadow(
              color: theme.shadowColor.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.18 : 0.06,
              ),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ];

    final openTopRadius = BorderRadius.only(
      topLeft: Radius.circular(borderRadiusValue),
      topRight: Radius.circular(borderRadiusValue),
    );

    final field = Container(
      decoration: BoxDecoration(
        borderRadius: inputBorderRadius,
        boxShadow: boxShadow,
      ),
      child: TextFormField(
        groupId: _tapGroupId,
        controller: _fieldController,
        enabled: widget.enabled,
        validator: widget.validator == null
            ? null
            : (_) => widget.validator!(_selectedItem),
        onSaved: widget.onSaved == null
            ? null
            : (_) => widget.onSaved!(_selectedItem),
        onChanged: _filterItems,
        focusNode: widget.focusNode,
        onFieldSubmitted: _handleSubmitted,
        style: TextStyle(
          color: widget.enabled ? cs.onSurface : cs.onSurfaceVariant,
          fontSize: inputFontSize,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: cs.primary,
        onTap: _onFieldTap,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: isActive ? cs.primaryContainer : cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: TextStyle(
            color: isActive ? cs.primaryContainer : cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.72),
            fontWeight: FontWeight.w400,
          ),
          border: OutlineInputBorder(
            borderRadius: _isDropdownOpen ? openTopRadius : inputBorderRadius,
            borderSide: BorderSide(color: activeBorderColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: _isDropdownOpen ? openTopRadius : inputBorderRadius,
            borderSide: BorderSide(color: enabledBorderColor, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: _isDropdownOpen ? openTopRadius : inputBorderRadius,
            borderSide: BorderSide(color: focusedBorderColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: inputBorderRadius,
            borderSide: BorderSide(color: cs.error, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: inputBorderRadius,
            borderSide: BorderSide(color: cs.error, width: 2),
          ),
          filled: true,
          fillColor: fieldFillColor,
          contentPadding: EdgeInsets.fromLTRB(
            12,
            widget.compact ? 16 : 18,
            12,
            widget.compact ? 10 : 14,
          ),
          prefixIcon: widget.prefixIcon,
          suffixIcon: GestureDetector(
            onTap: () {
              if (!widget.enabled) return;
              if (_isDropdownOpen) {
                _closeDropdown();
                widget.focusNode?.unfocus();
              } else {
                widget.focusNode?.requestFocus();
                _openDropdown();
              }
            },
            child: Icon(
              _isDropdownOpen
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: iconColor,
            ),
          ),
        ),
      ),
    );

    return DropdownOverlayPortal(
      controller: _overlayController,
      layerLink: _layerLink,
      anchorKey: _anchorKey,
      tapRegionGroupId: _tapGroupId,
      borderRadius: borderRadiusValue,
      onTapOutside: () {
        _closeDropdown();
        widget.focusNode?.unfocus();
      },
      panelChild: _buildDropdownList(theme, cs),
      child: field,
    );
  }
}

class _DropdownPagingFooter extends StatelessWidget {
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;

  const _DropdownPagingFooter({
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
