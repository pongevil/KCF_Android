import 'package:bs_mobile/src/core/theme/app_theme_extension.dart';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:flutter/material.dart';

enum CustomButtonVariant { primary, success, danger, warning, disabled }

class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = CustomButtonVariant.primary,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.width,
    this.height,
  });

  final String text;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double? height;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = true);
    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _controller.reverse();
          setState(() => _isPressed = false);
        }
      });
    });
    widget.onPressed!();
  }

  (Color bg, Color fg) _resolveColors(AppThemeExtension app) {
    if (widget.backgroundColor != null || widget.textColor != null) {
      return (
        widget.backgroundColor ?? app.buttonPrimary,
        widget.textColor ?? app.buttonPrimaryOn,
      );
    }

    return switch (widget.variant) {
      CustomButtonVariant.primary => (app.buttonPrimary, app.buttonPrimaryOn),
      CustomButtonVariant.success => (app.buttonSuccess, app.buttonSuccessOn),
      CustomButtonVariant.danger => (app.buttonDanger, app.buttonDangerOn),
      CustomButtonVariant.warning => (app.buttonWarning, app.buttonWarningOn),
      CustomButtonVariant.disabled => (
        app.buttonDisabled,
        app.buttonDisabledOn,
      ),
    };
  }

  bool get _isDisabled =>
      widget.variant == CustomButtonVariant.disabled ||
      widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppThemeExtension>()!;
    final (baseColor, contentColor) = _resolveColors(app);

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, _) => Transform.scale(
        scale: _scale.value,
        child: Container(
          width: widget.width,
          height: widget.height ?? 50,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isDisabled
                ? null
                : [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.2),
                      blurRadius: _isPressed ? 2 : 8,
                      offset: _isPressed
                          ? const Offset(0, 1)
                          : const Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isDisabled ? null : _handleTap,
              borderRadius: BorderRadius.circular(12),
              splashColor: contentColor.withValues(alpha: 0.1),
              highlightColor: contentColor.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: contentColor, size: 20),
                      const SizedBox(width: 8),
                    ],
                    AppText(
                      widget.text,
                      color: widget.textColor ?? contentColor,
                      style: TextStyle(
                        color: widget.textColor ?? contentColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
