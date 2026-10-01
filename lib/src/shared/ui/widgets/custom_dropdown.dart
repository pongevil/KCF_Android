import 'package:flutter/material.dart';

class Customdropdown<T> extends StatefulWidget {
  const Customdropdown({
    super.key,
    required this.label,
    this.value,
    required this.items,
    this.icon,
    required this.onChanged,
    this.itemToString,
    this.compact = false,
    this.decoration,
    this.hint,
    this.enabled = true,
    this.focusNode,
    this.validator,
    this.openDropdownOnFocus = false,
    this.dense = false,
    this.contentPadding,
    this.borderWidth = 2,
  });

  final String label;
  final T? value;
  final List<T> items;
  final IconData? icon;
  final void Function(T?) onChanged;
  final String Function(T)? itemToString;
  final bool compact;
  final InputDecoration? decoration;
  final String? hint;
  final bool enabled;
  final FocusNode? focusNode;
  final String? Function(T?)? validator;
  final bool openDropdownOnFocus;
  final bool dense;
  final EdgeInsetsGeometry? contentPadding;
  final double borderWidth;

  @override
  State<Customdropdown<T>> createState() => _CustomdropdownState<T>();
}

class _CustomdropdownState<T> extends State<Customdropdown<T>> {
  final _internalFocus = FocusNode();

  FocusNode get _focusNode => widget.focusNode ?? _internalFocus;

  String _itemText(T item) => widget.itemToString != null
      ? widget.itemToString!(item)
      : item.toString();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (widget.focusNode == null) {
      _internalFocus.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(Customdropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _internalFocus).removeListener(_onFocusChanged);
      _focusNode.addListener(_onFocusChanged);
    }
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasFocus = _focusNode.hasFocus;
    final containerColor = widget.enabled
        ? cs.surface
        : cs.surfaceContainerHighest.withValues(alpha: 0.5);
    final iconColor = hasFocus ? cs.primaryContainer : cs.onSurfaceVariant;
    final inputFontSize = widget.compact ? 13.0 : 14.0;
    final borderRadiusValue = widget.compact ? 10.0 : 13.0;
    final inputBorderRadius = BorderRadius.circular(borderRadiusValue);
    final enabledBorderColor = cs.primaryContainer;
    final activeBorderColor = cs.primaryContainer;
    final fieldFillColor = hasFocus ? cs.surface : containerColor;
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
    final selectedValue = widget.items.contains(widget.value)
        ? widget.value
        : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: inputBorderRadius,
        boxShadow: boxShadow,
      ),
      child: DropdownButtonFormField<T>(
        initialValue: selectedValue,
        items: widget.items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  _itemText(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: widget.enabled
            ? (value) {
                widget.onChanged(value);
                _focusNode.unfocus();
              }
            : null,
        focusNode: _focusNode,
        validator: widget.validator,
        onTap: _focusNode.requestFocus,
        isExpanded: true,
        menuMaxHeight: 300,
        borderRadius: BorderRadius.circular(borderRadiusValue),
        dropdownColor: cs.surface,
        icon: Icon(Icons.keyboard_arrow_down, color: iconColor),
        style: TextStyle(
          color: widget.enabled ? cs.onSurface : cs.onSurfaceVariant,
          fontSize: inputFontSize,
          fontWeight: FontWeight.w500,
        ),
        decoration: (widget.decoration ?? const InputDecoration()).copyWith(
          labelText: widget.label.isEmpty ? null : widget.label,
          labelStyle: TextStyle(
            color: hasFocus ? cs.primaryContainer : cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: TextStyle(
            color: hasFocus ? cs.primaryContainer : cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.72),
            fontWeight: FontWeight.w400,
            fontSize: inputFontSize,
          ),
          border: OutlineInputBorder(
            borderRadius: inputBorderRadius,
            borderSide: BorderSide(
              color: activeBorderColor,
              width: widget.borderWidth,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: inputBorderRadius,
            borderSide: BorderSide(
              color: enabledBorderColor,
              width: widget.borderWidth,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: inputBorderRadius,
            borderSide: BorderSide(
              color: activeBorderColor,
              width: widget.borderWidth,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: inputBorderRadius,
            borderSide: BorderSide(color: cs.error, width: widget.borderWidth),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: inputBorderRadius,
            borderSide: BorderSide(color: cs.error, width: widget.borderWidth),
          ),
          filled: true,
          fillColor: fieldFillColor,
          isDense: widget.compact || widget.dense,
          contentPadding:
              widget.contentPadding ??
              EdgeInsets.fromLTRB(
                12,
                widget.compact ? 14 : 18,
                12,
                widget.compact ? 10 : 14,
              ),
          prefixIcon: widget.icon != null
              ? Icon(
                  widget.icon,
                  size: widget.compact ? 18 : 22,
                  color: cs.onSurfaceVariant,
                )
              : null,
        ),
      ),
    );
  }
}
