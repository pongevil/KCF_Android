import 'package:flutter/material.dart';

import 'app_color_palette.dart';
import 'app_semantic_colors.dart';

/// Semantic colors and UI tokens that differ by palette and brightness.
///
/// Widgets should read colors via [Theme.of] + this extension — not [ThemeConfig].
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.headerGradient,
    required this.barButtonColor,
    required this.barContentColor,
    required this.drawerHeaderDecoration,
    required this.drawerHeaderTitleColor,
    required this.appBarDecoration,
    required this.appBarContentColor,
    required this.pageBackgroundGradient,
    required this.pageBackgroundDecorativeColor,
    required this.shimmerBaseColor,
    required this.shimmerHighlightColor,
    required this.infoBoxBackgroundOpacity,
    required this.infoBoxBorderOpacity,
    required this.appBarShadowColor,
    required this.inboundMenuGradient,
    required this.outboundMenuGradient,
    required this.menuGradientAlt1,
    required this.menuGradientAlt2,
    required this.neutralIconBackground,
    required this.primaryGradient,
    required this.buttonPrimary,
    required this.buttonPrimaryOn,
    required this.buttonSuccess,
    required this.buttonSuccessOn,
    required this.buttonDanger,
    required this.buttonDangerOn,
    required this.buttonWarning,
    required this.buttonWarningOn,
    required this.buttonDisabled,
    required this.buttonDisabledOn,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.palette,
  });

  final List<Color> headerGradient;
  final Color barButtonColor;
  final Color barContentColor;
  final BoxDecoration drawerHeaderDecoration;
  final Color drawerHeaderTitleColor;
  final BoxDecoration appBarDecoration;
  final Color appBarContentColor;
  final List<Color> pageBackgroundGradient;
  final Color pageBackgroundDecorativeColor;
  final Color shimmerBaseColor;
  final Color shimmerHighlightColor;
  final double infoBoxBackgroundOpacity;
  final double infoBoxBorderOpacity;
  final Color appBarShadowColor;
  final List<Color> inboundMenuGradient;
  final List<Color> outboundMenuGradient;
  final List<Color> menuGradientAlt1;
  final List<Color> menuGradientAlt2;
  final Color neutralIconBackground;
  final List<Color> primaryGradient;
  final Color buttonPrimary;
  final Color buttonPrimaryOn;
  final Color buttonSuccess;
  final Color buttonSuccessOn;
  final Color buttonDanger;
  final Color buttonDangerOn;
  final Color buttonWarning;
  final Color buttonWarningOn;
  final Color buttonDisabled;
  final Color buttonDisabledOn;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final AppColorPalette palette;

  static AppThemeExtension fromPalette({
    required AppColorPalette palette,
    required ColorScheme cs,
    required Brightness brightness,
    required Color shadowColor,
  }) {
    final tokens = palette.tokens;
    final buttons = AppButtonColors.fromColorScheme(cs);
    final isDark = brightness == Brightness.dark;

    final outboundGradient = isDark
        ? [
            Color.alphaBlend(
              tokens.secondaryAccent.withValues(alpha: 0.22),
              const Color(0xFF1A1A1A),
            ),
            Color.alphaBlend(
              tokens.secondaryAccent.withValues(alpha: 0.12),
              const Color(0xFF121212),
            ),
          ]
        : [
            Color.lerp(tokens.secondaryAccent, cs.surface, 0.55)!,
            Color.lerp(tokens.secondaryAccent, tokens.primaryDark, 0.35)!,
          ];

    final menuGradientAlt1 = isDark
        ? [
            Color.alphaBlend(
              tokens.primaryLight.withValues(alpha: 0.2),
              const Color(0xFF1E1E1E),
            ),
            Color.alphaBlend(
              tokens.primary.withValues(alpha: 0.28),
              const Color(0xFF121212),
            ),
          ]
        : [tokens.primaryLight, tokens.primary];

    final menuGradientAlt2 = isDark
        ? [
            Color.alphaBlend(
              tokens.decorative.withValues(alpha: 0.15),
              const Color(0xFF1E1E1E),
            ),
            Color.alphaBlend(
              tokens.primaryDark.withValues(alpha: 0.25),
              const Color(0xFF121212),
            ),
          ]
        : [tokens.decorative, tokens.primaryDark];

    final inboundGradient = isDark
        ? [
            Color.alphaBlend(
              tokens.primary.withValues(alpha: 0.25),
              const Color(0xFF1A1A1A),
            ),
            Color.alphaBlend(
              tokens.primaryDark.withValues(alpha: 0.35),
              const Color(0xFF0A0A0A),
            ),
          ]
        : tokens.inboundMenuGradient;

    return AppThemeExtension(
      palette: palette,
      headerGradient: isDark
          ? [const Color(0xFF1A1A1A), const Color(0xFF121212)]
          : tokens.headerGradient,
      barButtonColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.12),
      barContentColor: isDark ? cs.onSurface : Colors.white,
      drawerHeaderDecoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : tokens.primaryDark,
      ),
      drawerHeaderTitleColor: isDark ? cs.onSurface : Colors.white,
      appBarDecoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant, width: 1)),
      ),
      appBarContentColor: cs.onSurface,
      pageBackgroundGradient: isDark
          ? [const Color(0xFF0A0A0A), const Color(0xFF0A0A0A)]
          : [cs.surfaceContainerHighest, cs.surfaceContainerHighest],
      pageBackgroundDecorativeColor: isDark
          ? cs.surfaceContainerHighest.withValues(alpha: 0.2)
          : tokens.decorative.withValues(alpha: 0.6),
      shimmerBaseColor: isDark
          ? cs.surfaceContainerHighest
          : Colors.white.withValues(alpha: 0.3),
      shimmerHighlightColor: isDark
          ? cs.surface
          : Colors.white.withValues(alpha: 0.8),
      infoBoxBackgroundOpacity: isDark ? 0.08 : 0.04,
      infoBoxBorderOpacity: isDark ? 0.15 : 0.08,
      appBarShadowColor: Colors.transparent,
      inboundMenuGradient: inboundGradient,
      outboundMenuGradient: outboundGradient,
      menuGradientAlt1: menuGradientAlt1,
      menuGradientAlt2: menuGradientAlt2,
      neutralIconBackground: cs.surfaceContainerHighest,
      primaryGradient: tokens.primaryGradient,
      buttonPrimary: buttons.buttonPrimary,
      buttonPrimaryOn: buttons.buttonPrimaryOn,
      buttonSuccess: buttons.buttonSuccess,
      buttonSuccessOn: buttons.buttonSuccessOn,
      buttonDanger: buttons.buttonDanger,
      buttonDangerOn: buttons.buttonDangerOn,
      buttonWarning: buttons.buttonWarning,
      buttonWarningOn: buttons.buttonWarningOn,
      buttonDisabled: buttons.buttonDisabled,
      buttonDisabledOn: buttons.buttonDisabledOn,
      success: buttons.success,
      warning: buttons.warning,
      error: buttons.error,
      info: buttons.info,
    );
  }

  @override
  AppThemeExtension copyWith({
    List<Color>? headerGradient,
    Color? barButtonColor,
    Color? barContentColor,
    BoxDecoration? drawerHeaderDecoration,
    Color? drawerHeaderTitleColor,
    BoxDecoration? appBarDecoration,
    Color? appBarContentColor,
    List<Color>? pageBackgroundGradient,
    Color? pageBackgroundDecorativeColor,
    Color? shimmerBaseColor,
    Color? shimmerHighlightColor,
    double? infoBoxBackgroundOpacity,
    double? infoBoxBorderOpacity,
    Color? appBarShadowColor,
    List<Color>? inboundMenuGradient,
    List<Color>? outboundMenuGradient,
    List<Color>? menuGradientAlt1,
    List<Color>? menuGradientAlt2,
    Color? neutralIconBackground,
    List<Color>? primaryGradient,
    Color? buttonPrimary,
    Color? buttonPrimaryOn,
    Color? buttonSuccess,
    Color? buttonSuccessOn,
    Color? buttonDanger,
    Color? buttonDangerOn,
    Color? buttonWarning,
    Color? buttonWarningOn,
    Color? buttonDisabled,
    Color? buttonDisabledOn,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    AppColorPalette? palette,
  }) {
    return AppThemeExtension(
      headerGradient: headerGradient ?? this.headerGradient,
      barButtonColor: barButtonColor ?? this.barButtonColor,
      barContentColor: barContentColor ?? this.barContentColor,
      drawerHeaderDecoration:
          drawerHeaderDecoration ?? this.drawerHeaderDecoration,
      drawerHeaderTitleColor:
          drawerHeaderTitleColor ?? this.drawerHeaderTitleColor,
      appBarDecoration: appBarDecoration ?? this.appBarDecoration,
      appBarContentColor: appBarContentColor ?? this.appBarContentColor,
      pageBackgroundGradient:
          pageBackgroundGradient ?? this.pageBackgroundGradient,
      pageBackgroundDecorativeColor:
          pageBackgroundDecorativeColor ?? this.pageBackgroundDecorativeColor,
      shimmerBaseColor: shimmerBaseColor ?? this.shimmerBaseColor,
      shimmerHighlightColor:
          shimmerHighlightColor ?? this.shimmerHighlightColor,
      infoBoxBackgroundOpacity:
          infoBoxBackgroundOpacity ?? this.infoBoxBackgroundOpacity,
      infoBoxBorderOpacity: infoBoxBorderOpacity ?? this.infoBoxBorderOpacity,
      appBarShadowColor: appBarShadowColor ?? this.appBarShadowColor,
      inboundMenuGradient: inboundMenuGradient ?? this.inboundMenuGradient,
      outboundMenuGradient: outboundMenuGradient ?? this.outboundMenuGradient,
      menuGradientAlt1: menuGradientAlt1 ?? this.menuGradientAlt1,
      menuGradientAlt2: menuGradientAlt2 ?? this.menuGradientAlt2,
      neutralIconBackground:
          neutralIconBackground ?? this.neutralIconBackground,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      buttonPrimary: buttonPrimary ?? this.buttonPrimary,
      buttonPrimaryOn: buttonPrimaryOn ?? this.buttonPrimaryOn,
      buttonSuccess: buttonSuccess ?? this.buttonSuccess,
      buttonSuccessOn: buttonSuccessOn ?? this.buttonSuccessOn,
      buttonDanger: buttonDanger ?? this.buttonDanger,
      buttonDangerOn: buttonDangerOn ?? this.buttonDangerOn,
      buttonWarning: buttonWarning ?? this.buttonWarning,
      buttonWarningOn: buttonWarningOn ?? this.buttonWarningOn,
      buttonDisabled: buttonDisabled ?? this.buttonDisabled,
      buttonDisabledOn: buttonDisabledOn ?? this.buttonDisabledOn,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      palette: palette ?? this.palette,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      headerGradient: _lerpColorList(headerGradient, other.headerGradient, t),
      barButtonColor: Color.lerp(barButtonColor, other.barButtonColor, t)!,
      barContentColor: Color.lerp(barContentColor, other.barContentColor, t)!,
      drawerHeaderDecoration: other.drawerHeaderDecoration,
      drawerHeaderTitleColor: Color.lerp(
        drawerHeaderTitleColor,
        other.drawerHeaderTitleColor,
        t,
      )!,
      appBarDecoration: other.appBarDecoration,
      appBarContentColor: Color.lerp(
        appBarContentColor,
        other.appBarContentColor,
        t,
      )!,
      pageBackgroundGradient: _lerpColorList(
        pageBackgroundGradient,
        other.pageBackgroundGradient,
        t,
      ),
      pageBackgroundDecorativeColor: Color.lerp(
        pageBackgroundDecorativeColor,
        other.pageBackgroundDecorativeColor,
        t,
      )!,
      shimmerBaseColor: Color.lerp(
        shimmerBaseColor,
        other.shimmerBaseColor,
        t,
      )!,
      shimmerHighlightColor: Color.lerp(
        shimmerHighlightColor,
        other.shimmerHighlightColor,
        t,
      )!,
      infoBoxBackgroundOpacity:
          infoBoxBackgroundOpacity +
          (other.infoBoxBackgroundOpacity - infoBoxBackgroundOpacity) * t,
      infoBoxBorderOpacity:
          infoBoxBorderOpacity +
          (other.infoBoxBorderOpacity - infoBoxBorderOpacity) * t,
      appBarShadowColor: Color.lerp(
        appBarShadowColor,
        other.appBarShadowColor,
        t,
      )!,
      inboundMenuGradient: _lerpColorList(
        inboundMenuGradient,
        other.inboundMenuGradient,
        t,
      ),
      outboundMenuGradient: _lerpColorList(
        outboundMenuGradient,
        other.outboundMenuGradient,
        t,
      ),
      menuGradientAlt1: _lerpColorList(
        menuGradientAlt1,
        other.menuGradientAlt1,
        t,
      ),
      menuGradientAlt2: _lerpColorList(
        menuGradientAlt2,
        other.menuGradientAlt2,
        t,
      ),
      neutralIconBackground: Color.lerp(
        neutralIconBackground,
        other.neutralIconBackground,
        t,
      )!,
      primaryGradient: _lerpColorList(
        primaryGradient,
        other.primaryGradient,
        t,
      ),
      buttonPrimary: Color.lerp(buttonPrimary, other.buttonPrimary, t)!,
      buttonPrimaryOn: Color.lerp(buttonPrimaryOn, other.buttonPrimaryOn, t)!,
      buttonSuccess: Color.lerp(buttonSuccess, other.buttonSuccess, t)!,
      buttonSuccessOn: Color.lerp(buttonSuccessOn, other.buttonSuccessOn, t)!,
      buttonDanger: Color.lerp(buttonDanger, other.buttonDanger, t)!,
      buttonDangerOn: Color.lerp(buttonDangerOn, other.buttonDangerOn, t)!,
      buttonWarning: Color.lerp(buttonWarning, other.buttonWarning, t)!,
      buttonWarningOn: Color.lerp(buttonWarningOn, other.buttonWarningOn, t)!,
      buttonDisabled: Color.lerp(buttonDisabled, other.buttonDisabled, t)!,
      buttonDisabledOn: Color.lerp(
        buttonDisabledOn,
        other.buttonDisabledOn,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      palette: t < 0.5 ? palette : other.palette,
    );
  }

  static List<Color> _lerpColorList(List<Color> a, List<Color> b, double t) {
    if (a.length != b.length) return t < 0.5 ? a : b;
    return List.generate(a.length, (i) => Color.lerp(a[i], b[i], t)!);
  }
}
