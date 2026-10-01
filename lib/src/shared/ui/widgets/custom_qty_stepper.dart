import 'package:bs_mobile/index.dart';
import 'package:bs_mobile/src/core/app_config/app_config_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Quantity stepper with optional label — minus / text field / plus.
///
/// By default ([useQuantityConfig] = true) applies [QuantityConfig.inputPattern]
/// from [AppConfigService]. Parent should use [QuantityFormatter] for +/- logic.
///
/// When [label] is set, uses floating outline label style like [CustomTextField].
class CustomQtyStepper extends StatefulWidget {
  const CustomQtyStepper({
    super.key,
    required this.controller,
    required this.onDecrement,
    required this.onIncrement,
    this.label,
    this.accentColor,
    this.borderColor,
    this.borderRadius = 8,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.textInputAction,
    this.selectAllOnFocus = false,
    this.minHeight = 38,
    this.buttonWidth = 30,
    this.useQuantityConfig = true,
    this.allowDecimal = false,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final String? label;
  final Color? accentColor;

  /// Outer / focused border override. Defaults to theme outline / accent.
  final Color? borderColor;
  final double borderRadius;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool selectAllOnFocus;
  final double minHeight;
  final double buttonWidth;

  /// When true (default), uses [QuantityConfig.inputPattern] from
  /// [AppConfigService]. [allowDecimal] is ignored in this mode.
  final bool useQuantityConfig;

  /// Only used when [useQuantityConfig] is false.
  final bool allowDecimal;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<CustomQtyStepper> createState() => _CustomQtyStepperState();
}

class _CustomQtyStepperState extends State<CustomQtyStepper> {
  late final FocusNode _internalFocus;
  bool _isFocused = false;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocus;

  TextInputType _keyboardType() {
    if (widget.useQuantityConfig) {
      final decimalPlaces = AppConfigService.instance.quantity.decimalPlaces;
      return decimalPlaces > 0
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number;
    }

    return widget.allowDecimal
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.number;
  }

  List<TextInputFormatter>? _inputFormatters() {
    if (widget.inputFormatters != null) {
      return widget.inputFormatters;
    }

    if (widget.useQuantityConfig) {
      return [
        FilteringTextInputFormatter.allow(
          AppConfigService.instance.quantity.inputPattern,
        ),
      ];
    }

    if (widget.allowDecimal) {
      return null;
    }

    return [FilteringTextInputFormatter.digitsOnly];
  }

  @override
  void initState() {
    super.initState();
    _internalFocus = FocusNode();
    _isFocused = _focusNode.hasFocus;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant CustomQtyStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _internalFocus).removeListener(_onFocusChange);
      _focusNode.addListener(_onFocusChange);
      _isFocused = _focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _internalFocus.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (_isFocused != hasFocus) {
      setState(() => _isFocused = hasFocus);
    }

    if (!hasFocus ||
        !widget.selectAllOnFocus ||
        widget.controller.text.isEmpty) {
      return;
    }

    TextFieldSelectionHelper.selectAllAfterFrame(widget.controller);
  }

  OutlineInputBorder _outlineBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(color: color, width: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = widget.accentColor ?? cs.primaryContainer;
    final enabledBorder = widget.borderColor ?? accent;
    final focusedBorder = widget.borderColor ?? accent;
    final labelColor = _isFocused ? accent : cs.onSurfaceVariant;

    final row = Row(
      children: [
        _StepperButton(
          label: '−',
          width: widget.buttonWidth,
          height: widget.minHeight,
          onTap: widget.onDecrement,
          dividerColor: enabledBorder.withValues(alpha: 0.35),
        ),
        Expanded(
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            keyboardType: _keyboardType(),
            inputFormatters: _inputFormatters(),
            textInputAction: widget.textInputAction,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 9),
            ),
            style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
          ),
        ),
        _StepperButton(
          label: '+',
          width: widget.buttonWidth,
          height: widget.minHeight,
          onTap: widget.onIncrement,
          accent: accent,
          dividerColor: enabledBorder.withValues(alpha: 0.35),
          alignEnd: true,
        ),
      ],
    );

    final hasLabel = widget.label != null && widget.label!.trim().isNotEmpty;
    if (!hasLabel) {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: enabledBorder, width: 2),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          color: cs.surface,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: row,
        ),
      );
    }

    return Padding(
      // Floating label sits on the top border; leave room so Thai glyphs
      // (สระ/วรรณยุกต์) are not clipped by the parent.
      padding: const EdgeInsets.only(top: 8),
      child: InputDecorator(
        isFocused: _isFocused,
        isEmpty: false,
        decoration: InputDecoration(
          labelText: widget.label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          floatingLabelStyle: TextStyle(
            color: labelColor,
            fontWeight: FontWeight.w500,
            fontSize: 16,
            height: 1.25,
          ),
          labelStyle: TextStyle(
            color: labelColor,
            fontWeight: FontWeight.w500,
            fontSize: 16,
            height: 1.25,
          ),
          isDense: true,
          filled: true,
          fillColor: cs.surface,
          contentPadding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
          border: _outlineBorder(enabledBorder),
          enabledBorder: _outlineBorder(enabledBorder),
          focusedBorder: _outlineBorder(focusedBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius - 1),
          child: row,
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.label,
    required this.width,
    required this.height,
    required this.onTap,
    required this.dividerColor,
    this.accent,
    this.alignEnd = false,
  });

  final String label;
  final double width;
  final double height;
  final VoidCallback onTap;
  final Color dividerColor;
  final Color? accent;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              right: alignEnd
                  ? BorderSide.none
                  : BorderSide(color: dividerColor),
              left: alignEnd
                  ? BorderSide(color: dividerColor)
                  : BorderSide.none,
            ),
          ),
          child: SizedBox(
            width: width,
            height: height,
            child: Center(
              child: AppText(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: accent ?? cs.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
