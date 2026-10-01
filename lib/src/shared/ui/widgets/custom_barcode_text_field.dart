import 'package:bs_mobile/src/core/barcode/barcode_format_service.dart';
import 'package:bs_mobile/src/shared/camera/barcode_scan_helper.dart';
import 'package:bs_mobile/src/shared/ui/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

/// Barcode-aware text field — wraps [CustomTextField].
///
/// - Enter / HID submit → [BarcodeScanHelper.applyRaw]
/// - Prefix scan icon → [BarcodeScanHelper.scanAndApply]
/// - On success → focuses [nextFocusNode] when set
/// - Page owns and disposes [focusNode] / [nextFocusNode]
class CustomBarcodeTextField extends StatefulWidget {
  const CustomBarcodeTextField({
    super.key,
    required this.controller,
    required this.tagFunction,
    required this.entryField,
    required this.apply,
    this.focusNode,
    this.nextFocusNode,
    this.labelText,
    this.label,
    this.hintText,
    this.validator,
    this.compact = false,
    this.selectAllOnFocus = true,
    this.textInputAction = TextInputAction.next,
    this.scanTitle = 'สแกนโค้ด',
    this.scanHint,
    this.showScanButton = true,
    this.showAlert = true,
    this.formatService,
    this.onApplyResult,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;

  final String tagFunction;
  final String entryField;
  final Map<String, BarcodeApplyCallback> apply;

  final String? labelText;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool? compact;
  final bool selectAllOnFocus;
  final TextInputAction? textInputAction;

  final String scanTitle;
  final String? scanHint;
  final bool showScanButton;
  final bool showAlert;
  final BarcodeFormatService? formatService;

  /// Optional trailing icon (scan stays on prefix).
  final Widget? suffixIcon;

  /// Optional hook after apply (camera or raw).
  final void Function(BarcodeApplyResult result)? onApplyResult;

  @override
  State<CustomBarcodeTextField> createState() => _CustomBarcodeTextFieldState();
}

class _CustomBarcodeTextFieldState extends State<CustomBarcodeTextField> {
  bool _busy = false;

  Future<void> _handleRaw(String raw) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await BarcodeScanHelper.applyRaw(
        raw: raw,
        tagFunction: widget.tagFunction,
        entryField: widget.entryField,
        apply: widget.apply,
        showAlert: widget.showAlert,
        formatService: widget.formatService,
      );
      widget.onApplyResult?.call(result);
      if (result.success) {
        widget.nextFocusNode?.requestFocus();
      } else {
        widget.focusNode?.requestFocus();
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _handleCameraScan() async {
    if (_busy || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await BarcodeScanHelper.scanAndApply(
        context,
        tagFunction: widget.tagFunction,
        entryField: widget.entryField,
        apply: widget.apply,
        title: widget.scanTitle,
        hint: widget.scanHint,
        showAlert: widget.showAlert,
        formatService: widget.formatService,
      );
      if (!mounted) return;
      widget.onApplyResult?.call(result);
      if (result.success) {
        widget.nextFocusNode?.requestFocus();
      } else if (result.errorCode != 'cancelled') {
        widget.focusNode?.requestFocus();
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return CustomTextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      labelText: widget.labelText,
      label: widget.label,
      hintText: widget.hintText,
      validator: widget.validator,
      compact: widget.compact,
      selectAllOnFocus: widget.selectAllOnFocus,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: _handleRaw,
      prefixIcon: widget.showScanButton
          ? IconButton(
              tooltip: widget.scanTitle,
              onPressed: _busy ? null : _handleCameraScan,
              icon: Icon(Icons.qr_code_scanner_rounded, color: cs.primary),
            )
          : null,
      suffixIcon: widget.suffixIcon,
    );
  }
}
