import 'dart:async';

import 'package:bs_mobile/src/core/helpers/submit_debounce.dart';
import 'package:bs_mobile/src/shared/index.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.descriptionText,
    this.helperText,
    this.helperStyle,
    this.helperMaxLines = 2,
    this.descriptionInField = false,
    this.descriptionInFieldStyle,
    this.descriptionInFieldMaxLines = 1,
    this.descriptionInFieldLeft,
    this.descriptionInFieldRight,
    this.descriptionInFieldBottom = 15,
    this.prefixIconData,
    this.prefixIcon,
    this.prefixIconColor,
    this.focusedPrefixIconColor,
    this.suffixIcon,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.onTap,
    this.onFieldSubmitted,
    this.onTapOutside,
    this.minLines,
    this.maxLines,
    this.readOnly = false,
    this.isPassword = false,
    this.textInputAction,
    this.textStyle,
    this.hintStyle,
    this.contentPadding,
    this.borderRadius = 12,
    this.focusedBorderColor,
    this.enabledBorderColor,
    this.fillColor,
    this.focusedFillColor,
    this.isDense = false,

    // DATE PICKER
    this.enableDatePicker = false,
    this.openDatePickerOnFocus = false,
    this.dateFormat = 'dd/MM/yyyy',
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.onDateSelected,
    this.label,
    this.compact = false,
    this.selectAllOnFocus = false,
    this.keyboardType,
    this.respectSoftKeyboard = false,
  });

  final TextEditingController controller;

  final String? labelText;
  final String? hintText;
  final String? descriptionText;
  final String? helperText;
  final bool? compact;

  final TextStyle? helperStyle;
  final int helperMaxLines;

  final bool descriptionInField;
  final TextStyle? descriptionInFieldStyle;
  final int descriptionInFieldMaxLines;
  final double? descriptionInFieldLeft;
  final double? descriptionInFieldRight;
  final double descriptionInFieldBottom;

  final IconData? prefixIconData;
  final Widget? prefixIcon;
  final Color? prefixIconColor;
  final Color? focusedPrefixIconColor;
  final Widget? suffixIcon;

  final FocusNode? focusNode;

  final String? Function(String?)? validator;

  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final FutureOr<void> Function(String)? onFieldSubmitted;
  final TapRegionCallback? onTapOutside;

  final int? minLines;
  final int? maxLines;

  final bool readOnly;
  final bool isPassword;
  final String? label;

  final TextInputAction? textInputAction;

  final TextStyle? textStyle;
  final TextStyle? hintStyle;

  final EdgeInsetsGeometry? contentPadding;

  final double borderRadius;

  final Color? focusedBorderColor;
  final Color? enabledBorderColor;
  final Color? fillColor;
  final Color? focusedFillColor;

  final bool isDense;

  // DATE PICKER
  final bool enableDatePicker;
  final bool openDatePickerOnFocus;
  final String dateFormat;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;
  final void Function(DateTime?)? onDateSelected;
  final bool selectAllOnFocus;

  final TextInputType? keyboardType;

  /// การซ่อน soft keyboard จัดการแบบ global ผ่าน `SoftKeyboardController`
  /// (custom TextInputControl) แล้ว flag นี้จึงไม่มีผลกับตัว field โดยตรง
  /// เก็บไว้เพื่อความเข้ากันได้ของ call site เดิม
  final bool respectSoftKeyboard;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scale;

  bool _isFocused = false;
  bool _obscure = false;
  bool _isPickerVisible = false;
  bool _deferFocusPicker = false;

  bool get _isPassword => widget.isPassword || widget.labelText == 'Password';

  Widget _buildDatePickerIconButton(ColorScheme cs) {
    return IconButton(
      icon: const Icon(Icons.calendar_month),
      onPressed: () async {
        await _pickDate();
      },
      color: _isFocused ? cs.primaryContainer : cs.onSurfaceVariant,
    );
  }

  Widget? _buildPrefixIcon(ColorScheme cs) {
    return widget.prefixIcon ??
        (widget.prefixIconData != null
            ? Icon(
                widget.prefixIconData,
                color: _isFocused
                    ? (widget.focusedPrefixIconColor ??
                          widget.prefixIconColor ??
                          cs.primaryContainer)
                    : (widget.prefixIconColor ?? cs.onSurfaceVariant),
              )
            : null);
  }

  Widget? _buildSuffixIcon(ColorScheme cs) {
    if (_isPassword) {
      return IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_off : Icons.visibility,
          color: _isFocused ? cs.primaryContainer : cs.onSurfaceVariant,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      );
    }

    final datePickerIcon = widget.enableDatePicker
        ? _buildDatePickerIconButton(cs)
        : null;
    final trailingIcon = widget.suffixIcon;

    if (datePickerIcon != null && trailingIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [trailingIcon, datePickerIcon],
      );
    }

    return datePickerIcon ?? trailingIcon;
  }

  void _maybeSelectAllOnFocus() {
    if (!widget.selectAllOnFocus || widget.controller.text.isEmpty) {
      return;
    }

    TextFieldSelectionHelper.selectAllAfterFrame(widget.controller);
  }

  @override
  void initState() {
    super.initState();

    _obscure = _isPassword;

    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    widget.focusNode?.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final hasFocus = widget.focusNode?.hasFocus ?? false;

    setState(() {
      _isFocused = hasFocus;

      if (_isFocused) {
        _animCtrl.forward();
        _maybeSelectAllOnFocus();
      } else {
        _animCtrl.reverse();
      }
    });

    if (hasFocus &&
        widget.enableDatePicker &&
        widget.openDatePickerOnFocus &&
        !_isPickerVisible &&
        !_deferFocusPicker) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if ((widget.focusNode?.hasFocus ?? false) &&
            !_isPickerVisible &&
            !_deferFocusPicker) {
          _pickDate();
        }
      });
    }
  }

  void _releaseFocusPickerDefer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _deferFocusPicker = false;
      }
    });
  }

  Future<void> _pickDate() async {
    if (_isPickerVisible || !mounted) {
      return;
    }

    _isPickerVisible = true;
    if (widget.openDatePickerOnFocus) {
      _deferFocusPicker = true;
    }

    final now = DateTime.now();

    DateTime initialDate = widget.initialDate ?? now;

    if (widget.controller.text.trim().isNotEmpty) {
      try {
        initialDate = DateFormat(
          widget.dateFormat,
        ).parse(widget.controller.text.trim());
      } catch (_) {}
    }

    DateTime? picked;
    try {
      picked = await showDatePicker(
        context: context,
        locale: const Locale('en', 'GB'),
        initialDate: initialDate,
        firstDate: widget.firstDate ?? DateTime(2000),
        lastDate: widget.lastDate ?? DateTime(2100),
      );
    } finally {
      _isPickerVisible = false;
    }

    if (!mounted) {
      return;
    }

    if (picked != null) {
      final formatted = DateFormat(widget.dateFormat).format(picked);

      widget.controller.text = formatted;

      if (widget.onChanged != null) {
        widget.onChanged!(formatted);
      }

      if (widget.onDateSelected != null) {
        widget.onDateSelected!(picked);
      }

      setState(() {});
    }

    if (widget.openDatePickerOnFocus) {
      widget.focusNode?.unfocus();
      _releaseFocusPickerDefer();
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final borderRadius = BorderRadius.circular(widget.borderRadius);

    final focusedBorderColor = widget.focusedBorderColor ?? cs.primaryContainer;

    final enabledBorderColor = widget.enabledBorderColor ?? cs.primaryContainer;

    final usesFloatingLabel =
        widget.compact != true &&
        (widget.labelText?.trim().isNotEmpty ?? false);

    final fillColor =
        widget.fillColor ??
        (usesFloatingLabel
            ? cs.surface
            : cs.surfaceContainerHighest.withValues(alpha: 0.3));

    final focusedFillColor = widget.focusedFillColor ?? cs.surface;

    final descriptionText = widget.descriptionText ?? widget.helperText;

    final hasDescription = descriptionText?.trim().isNotEmpty ?? false;

    // Keep layout stable when descriptionInField is enabled so toggling
    // description visibility does not rebuild a different widget tree.
    final useDescriptionInFieldLayout =
        widget.descriptionInField && (hasDescription || _isFocused);
    final descriptionOverlayStyle =
        (widget.descriptionInFieldStyle ??
                TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ))
            .copyWith(height: widget.descriptionInFieldStyle?.height ?? 1.1);

    final effectiveMaxLines =
        widget.maxLines ?? (widget.minLines == null ? 1 : null);

    final field = AnimatedBuilder(
      animation: _scale,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final isTightHeight =
              constraints.hasBoundedHeight && constraints.maxHeight <= 56;
          final useCompactLayout = widget.compact == true || isTightHeight;
          final defaultContentPadding = useDescriptionInFieldLayout
              ? const EdgeInsets.fromLTRB(16, 8, 16, 34)
              : useCompactLayout
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 16);

          return Transform.scale(
            scale: _scale.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                color: cs.surface,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.compact == true) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: cs.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: AppText(
                            widget.label ?? '',
                            color: cs.secondary,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w800,
                            style: const TextStyle(letterSpacing: 0.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  TextFormField(
                    controller: widget.controller,
                    minLines: widget.minLines,
                    maxLines: effectiveMaxLines,
                    focusNode: widget.focusNode,
                    validator: widget.validator,
                    onChanged: (value) {
                      if (SoftKeyboardController.debugLogging) {
                        debugPrint(
                          '[SoftKb][field] onChanged '
                          'label="${widget.labelText ?? widget.label}" '
                          'value="$value"',
                        );
                      }
                      widget.onChanged?.call(value);
                    },
                    onFieldSubmitted: (value) async {
                      if (SoftKeyboardController.debugLogging) {
                        debugPrint(
                          '[SoftKb][field] onSubmitted '
                          'label="${widget.labelText ?? widget.label}" '
                          'value="$value"',
                        );
                      }
                      if (!SubmitDebounce.shouldHandle()) {
                        return;
                      }
                      await Future.delayed(const Duration(milliseconds: 100));
                      await widget.onFieldSubmitted?.call(value);
                    },
                    onTapOutside: widget.onTapOutside,
                    readOnly: widget.readOnly, //|| widget.enableDatePicker,
                    obscureText: _obscure,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    textAlignVertical: useDescriptionInFieldLayout
                        ? TextAlignVertical.top
                        : TextAlignVertical.center,
                    style:
                        widget.textStyle ??
                        TextStyle(
                          color: cs.onSurface,
                          fontSize: useCompactLayout ? 14 : 14,
                          fontWeight: FontWeight.w500,
                          textBaseline: TextBaseline.alphabetic,
                          height: useCompactLayout ? 1.1 : null,
                        ),
                    onTap: () async {
                      _maybeSelectAllOnFocus();

                      widget.onTap?.call();
                    },
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      labelText: widget.compact == true
                          ? null
                          : widget.labelText,
                      floatingLabelStyle: TextStyle(
                        color: _isFocused
                            ? cs.primaryContainer
                            : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      helperText: useDescriptionInFieldLayout
                          ? null
                          : descriptionText,
                      helperMaxLines: widget.helperMaxLines,
                      helperStyle:
                          widget.helperStyle ??
                          TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                      labelStyle: TextStyle(
                        color: _isFocused
                            ? cs.primaryContainer
                            : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      hintStyle:
                          widget.hintStyle ??
                          TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w400,
                          ),
                      prefixIcon: _buildPrefixIcon(cs),
                      suffixIcon: _buildSuffixIcon(cs),
                      filled: true,
                      fillColor: _isFocused ? focusedFillColor : fillColor,
                      isDense: widget.isDense || useCompactLayout,
                      border: OutlineInputBorder(
                        borderRadius: borderRadius,
                        borderSide: BorderSide(
                          color: enabledBorderColor,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: borderRadius,
                        borderSide: BorderSide(
                          color: enabledBorderColor,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: borderRadius,
                        borderSide: BorderSide(
                          color: focusedBorderColor,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: borderRadius,
                        borderSide: BorderSide(color: cs.error, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: borderRadius,
                        borderSide: BorderSide(color: cs.error, width: 2),
                      ),
                      errorMaxLines: 2,
                      contentPadding:
                          widget.contentPadding ?? defaultContentPadding,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (!widget.descriptionInField) {
      return field;
    }

    final descriptionStart =
        widget.descriptionInFieldLeft ??
        (widget.prefixIcon != null || widget.prefixIconData != null
            ? 50.0
            : 16.0);

    final hasSuffix =
        widget.suffixIcon != null || _isPassword || widget.enableDatePicker;
    final hasBothSuffixIcons =
        widget.suffixIcon != null && widget.enableDatePicker && !_isPassword;

    final descriptionEnd =
        widget.descriptionInFieldRight ??
        (hasSuffix ? (hasBothSuffixIcons ? 88.0 : 52.0) : 16.0);

    return Stack(
      children: [
        field,
        if (hasDescription)
          Positioned(
            left: descriptionStart,
            right: descriptionEnd,
            bottom: widget.descriptionInFieldBottom,
            child: IgnorePointer(
              child: Text(
                descriptionText!,
                maxLines: widget.descriptionInFieldMaxLines,
                overflow: TextOverflow.ellipsis,
                style: descriptionOverlayStyle,
              ),
            ),
          ),
      ],
    );
  }
}
