import 'package:bs_mobile/src/core/theme/app_theme_extension.dart';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:flutter/material.dart';

/// Animated card used as the login form container.
class CustomLoginCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;

  const CustomLoginCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
  });

  @override
  State<CustomLoginCard> createState() => _CustomLoginCardState();
}

class _CustomLoginCardState extends State<CustomLoginCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: cs.outlineVariant, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding:
                      widget.padding ??
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Animated Background ──────────────────────────────────────────────────────

class CustomAnimatedBackground extends StatefulWidget {
  final Widget child;
  const CustomAnimatedBackground({super.key, required this.child});

  @override
  State<CustomAnimatedBackground> createState() =>
      _CustomAnimatedBackgroundState();
}

class _CustomAnimatedBackgroundState extends State<CustomAnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _c1, _c2;

  @override
  void initState() {
    super.initState();
    _c1 = AnimationController(duration: const Duration(seconds: 8), vsync: this)
      ..repeat(reverse: true);
    _c2 = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    super.dispose();
  }

  Widget _circle(
    AnimationController ctrl,
    double? top,
    double? left,
    double size,
    Color color, {
    double? bottom,
    double? right,
  }) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => Positioned(
        top: top != null ? top + ctrl.value * 30 : null,
        left: left != null ? left + ctrl.value * 20 : null,
        bottom: bottom != null ? bottom + ctrl.value * 30 : null,
        right: right != null ? right + ctrl.value * 20 : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppThemeExtension>()!;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: app.pageBackgroundGradient,
            ),
          ),
        ),
        _circle(_c1, -50, -50, 300, app.pageBackgroundDecorativeColor),
        _circle(
          _c2,
          null,
          null,
          250,
          app.pageBackgroundDecorativeColor,
          bottom: -50,
          right: -50,
        ),
        widget.child,
      ],
    );
  }
}

// ─── Animated Title ───────────────────────────────────────────────────────────

class CustomAnimatedTitle extends StatefulWidget {
  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const CustomAnimatedTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  State<CustomAnimatedTitle> createState() => _CustomAnimatedTitleState();
}

class _CustomAnimatedTitleState extends State<CustomAnimatedTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Column(
          children: [
            AppText(
              widget.title,
              style:
                  widget.titleStyle ??
                  TextStyle(
                    color: cs.onSurface,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
              textAlign: TextAlign.center,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              AppText(
                widget.subtitle!,
                style:
                    widget.subtitleStyle ??
                    TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
