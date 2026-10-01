import 'package:flutter/material.dart';

import 'app_color_palette.dart';
import 'app_semantic_colors.dart';
import 'app_theme_extension.dart';

/// Central theme configuration.
///
/// **Boilerplate rule:** Widgets must NOT import this file to read colors.
/// Use [Theme.of(context).colorScheme] and [AppThemeExtension] instead.
class ThemeConfig {
  ThemeConfig._();

  static ThemeData theme({
    required AppColorPalette palette,
    required Brightness brightness,
  }) {
    final tokens = palette.tokens;
    final isDark = brightness == Brightness.dark;
    final cs = _buildColorScheme(tokens, isDark);
    final shadowColor = isDark
        ? const Color(0x40000000)
        : const Color(0x0A000000);
    final appExtension = AppThemeExtension.fromPalette(
      palette: palette,
      cs: cs,
      brightness: brightness,
      shadowColor: shadowColor,
    );

    final scaffoldBg = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFFFFFFF);
    final appBarBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return ThemeData(
      brightness: brightness,
      primaryColor: cs.primary,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: cs,
      fontFamily: 'Noto-Thai',
      fontFamilyFallback: const ['Noto'],
      iconTheme: IconThemeData(color: cs.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerColor: cs.outlineVariant,
      shadowColor: shadowColor,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: appExtension.buttonPrimary,
          foregroundColor: appExtension.buttonPrimaryOn,
          disabledBackgroundColor: appExtension.buttonDisabled,
          disabledForegroundColor: appExtension.buttonDisabledOn,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: appExtension.buttonPrimary,
          foregroundColor: appExtension.buttonPrimaryOn,
          disabledBackgroundColor: appExtension.buttonDisabled,
          disabledForegroundColor: appExtension.buttonDisabledOn,
        ),
      ),
      extensions: [appExtension],
    );
  }

  static ColorScheme _buildColorScheme(PaletteTokens tokens, bool isDark) {
    if (isDark) {
      return ColorScheme.dark(
        primary: tokens.primary,
        primaryContainer: tokens.primaryDark,
        secondary: tokens.primaryLight,
        tertiary: tokens.decorative,
        onTertiary: const Color(0xFF2D3436),
        surface: const Color(0xFF1E1E1E),
        surfaceContainerHighest: const Color(0xFF2A2A2A),
        onPrimary: Colors.white,
        onSurface: const Color(0xFFF4F7F6),
        onSurfaceVariant: const Color(0xFFA0B3B2),
        outline: tokens.accent,
        outlineVariant: const Color(0xFF333333),
        error: AppSemanticColors.error,
        onError: Colors.white,
      );
    }

    return ColorScheme.light(
      primary: tokens.primary,
      primaryContainer: tokens.primaryDark,
      secondary: tokens.accent,
      tertiary: tokens.decorative,
      onTertiary: const Color(0xFF2D3436),
      surface: const Color(0xFFFFFFFF),
      surfaceContainerHighest: const Color(0xFFF4F7F6),
      onPrimary: Colors.white,
      onSurface: const Color(0xFF2D3436),
      onSurfaceVariant: const Color(0xFF536E6F),
      outline: tokens.decorative,
      outlineVariant: const Color(0xFFE8ECEB),
      error: AppSemanticColors.error,
      onError: Colors.white,
    );
  }

  /// Legacy accessors — prefer [AppThemeExtension] in widgets.
  @Deprecated('Use Theme.of(context).colorScheme.primary or appTheme')
  static ThemeData get lightTheme => theme(
    palette: AppColorPaletteX.defaultPalette,
    brightness: Brightness.light,
  );

  @Deprecated('Use Theme.of(context).colorScheme or appTheme')
  static ThemeData get darkTheme => theme(
    palette: AppColorPaletteX.defaultPalette,
    brightness: Brightness.dark,
  );
}
