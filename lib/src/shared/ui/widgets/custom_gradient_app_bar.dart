import 'package:bs_mobile/src/core/theme/app_theme_extension.dart';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum CustomGradientAppBarVariant { surface, green, orange, pink }

class CustomGradientAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final CustomGradientAppBarVariant variant;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final IconData? actionIcon;
  final VoidCallback? onActionPressed;
  final String? actionTooltip;
  final Widget? trailing;

  const CustomGradientAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.variant = CustomGradientAppBarVariant.surface,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.leading,
    this.actionIcon,
    this.onActionPressed,
    this.actionTooltip,
    this.trailing,
  });

  double get _toolbarHeight => subtitle == null ? 50 : 60;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = Theme.of(context).extension<AppThemeExtension>()!;
    final palette = _CustomGradientAppBarPalette.resolve(variant, cs, app);
    final resolvedLeading = _buildLeading(context, palette);
    final resolvedActions = _buildActions(palette);

    return DecoratedBox(
      decoration: palette.decoration,
      child: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: _toolbarHeight,
        automaticallyImplyLeading: false,
        leading: resolvedLeading,
        leadingWidth: resolvedLeading == null ? 0 : 72,
        titleSpacing: resolvedLeading == null ? 20 : 0,
        iconTheme: IconThemeData(color: palette.foregroundColor),
        systemOverlayStyle: palette.overlayStyle,
        title: _CustomGradientAppBarTitle(
          title: title,
          subtitle: subtitle,
          color: palette.foregroundColor,
        ),
        actions: resolvedActions.isEmpty ? null : resolvedActions,
        bottom: bottom,
      ),
    );
  }

  Widget? _buildLeading(
    BuildContext context,
    _CustomGradientAppBarPalette palette,
  ) {
    if (leading != null) {
      return leading;
    }

    final canPop = Navigator.of(context).canPop();
    if (!automaticallyImplyLeading || !canPop) {
      return null;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      child: _CustomGradientAppBarIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        foregroundColor: palette.buttonForegroundColor,
        backgroundColor: palette.buttonBackgroundColor,
        borderColor: palette.buttonBorderColor,
        onPressed: () => Navigator.maybePop(context),
      ),
    );
  }

  List<Widget> _buildActions(_CustomGradientAppBarPalette palette) {
    final resolvedActions = <Widget>[
      if (trailing != null)
        Padding(
          padding: EdgeInsets.only(
            top: 8,
            bottom: 8,
            right: actions == null || actions!.isEmpty ? 16 : 8,
          ),
          child: trailing,
        )
      else if (actionIcon != null && onActionPressed != null)
        Padding(
          padding: EdgeInsets.only(
            top: 8,
            bottom: 8,
            right: actions == null || actions!.isEmpty ? 16 : 8,
          ),
          child: _CustomGradientAppBarIconButton(
            icon: actionIcon!,
            foregroundColor: palette.buttonForegroundColor,
            backgroundColor: palette.buttonBackgroundColor,
            borderColor: palette.buttonBorderColor,
            onPressed: onActionPressed!,
            tooltip: actionTooltip,
          ),
        ),
      ...?actions,
    ];

    return resolvedActions;
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(_toolbarHeight + (bottom?.preferredSize.height ?? 0));
}

class _CustomGradientAppBarTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color color;

  const _CustomGradientAppBarTitle({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: subtitle == null ? 24 : 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            AppText(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color.withValues(alpha: 0.92),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomGradientAppBarIconButton extends StatelessWidget {
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onPressed;
  final String? tooltip;

  const _CustomGradientAppBarIconButton({
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Material(
      color: Colors.transparent,
      child: Ink(
        width: 42,
        height: 42,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Center(child: Icon(icon, size: 20, color: foregroundColor)),
        ),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) {
      return child;
    }

    return Tooltip(message: tooltip!, child: child);
  }
}

class _CustomGradientAppBarPalette {
  final BoxDecoration decoration;
  final Color foregroundColor;
  final Color buttonForegroundColor;
  final Color buttonBackgroundColor;
  final Color buttonBorderColor;
  final SystemUiOverlayStyle overlayStyle;

  const _CustomGradientAppBarPalette({
    required this.decoration,
    required this.foregroundColor,
    required this.buttonForegroundColor,
    required this.buttonBackgroundColor,
    required this.buttonBorderColor,
    required this.overlayStyle,
  });

  factory _CustomGradientAppBarPalette.resolve(
    CustomGradientAppBarVariant variant,
    ColorScheme cs,
    AppThemeExtension app,
  ) {
    const gradientButtonBg = Color(0x33000000);
    const gradientButtonBorder = Color(0x1FFFFFFF);

    switch (variant) {
      case CustomGradientAppBarVariant.green:
        return _CustomGradientAppBarPalette(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: app.primaryGradient,
            ),
          ),
          foregroundColor: Colors.white,
          buttonForegroundColor: Colors.white,
          buttonBackgroundColor: gradientButtonBg,
          buttonBorderColor: gradientButtonBorder,
          overlayStyle: SystemUiOverlayStyle.light,
        );
      case CustomGradientAppBarVariant.orange:
        return _CustomGradientAppBarPalette(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: app.outboundMenuGradient,
            ),
          ),
          foregroundColor: Colors.white,
          buttonForegroundColor: Colors.white,
          buttonBackgroundColor: gradientButtonBg,
          buttonBorderColor: gradientButtonBorder,
          overlayStyle: SystemUiOverlayStyle.light,
        );
      case CustomGradientAppBarVariant.pink:
        return _CustomGradientAppBarPalette(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: app.headerGradient,
            ),
          ),
          foregroundColor: Colors.white,
          buttonForegroundColor: Colors.white,
          buttonBackgroundColor: gradientButtonBg,
          buttonBorderColor: gradientButtonBorder,
          overlayStyle: SystemUiOverlayStyle.light,
        );
      case CustomGradientAppBarVariant.surface:
        return _CustomGradientAppBarPalette(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
              bottom: BorderSide(color: cs.outlineVariant, width: 1),
            ),
          ),
          foregroundColor: cs.onSurface,
          buttonForegroundColor: cs.onSurface,
          buttonBackgroundColor: cs.surfaceContainerHighest.withValues(
            alpha: 0.92,
          ),
          buttonBorderColor: cs.outlineVariant,
          overlayStyle: SystemUiOverlayStyle.dark,
        );
    }
  }
}
