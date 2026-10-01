import 'package:flutter/material.dart';

/// User-selectable color presets for the boilerplate app.
enum AppColorPalette { freshGreen, oceanBlue, royalPurple, sunsetOrange }

/// Brand tokens for a single color preset.
class PaletteTokens {
  const PaletteTokens({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
    required this.decorative,
    required this.secondaryAccent,
  });

  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color accent;
  final Color decorative;
  final Color secondaryAccent;

  List<Color> get primaryGradient => [primary, primaryDark];
  List<Color> get headerGradient => [primaryDark, accent];
  List<Color> get inboundMenuGradient => [primaryLight, primary];
}

extension AppColorPaletteX on AppColorPalette {
  static const AppColorPalette defaultPalette = AppColorPalette.freshGreen;

  String get storageKey => name;

  String get displayName => switch (this) {
    AppColorPalette.freshGreen => 'Fresh Green',
    AppColorPalette.oceanBlue => 'Ocean Blue',
    AppColorPalette.royalPurple => 'Royal Purple',
    AppColorPalette.sunsetOrange => 'Sunset Orange',
  };

  PaletteTokens get tokens => switch (this) {
    AppColorPalette.freshGreen => const PaletteTokens(
      primary: Color(0xFF00CE7C),
      primaryLight: Color(0xFFECFB56),
      primaryDark: Color(0xFF008065),
      accent: Color(0xFF1D4849),
      decorative: Color(0xFFDAF7E9),
      secondaryAccent: Color(0xFFFF6600),
    ),
    AppColorPalette.oceanBlue => const PaletteTokens(
      primary: Color(0xFF0EA5E9),
      primaryLight: Color(0xFF7DD3FC),
      primaryDark: Color(0xFF0369A1),
      accent: Color(0xFF0C4A6E),
      decorative: Color(0xFFE0F2FE),
      secondaryAccent: Color(0xFF0284C7),
    ),
    AppColorPalette.royalPurple => const PaletteTokens(
      primary: Color(0xFF8B5CF6),
      primaryLight: Color(0xFFC4B5FD),
      primaryDark: Color(0xFF6D28D9),
      accent: Color(0xFF4C1D95),
      decorative: Color(0xFFEDE9FE),
      secondaryAccent: Color(0xFFA855F7),
    ),
    AppColorPalette.sunsetOrange => const PaletteTokens(
      primary: Color(0xFFF97316),
      primaryLight: Color(0xFFFDBA74),
      primaryDark: Color(0xFFC2410C),
      accent: Color(0xFF7C2D12),
      decorative: Color(0xFFFFEDD5),
      secondaryAccent: Color(0xFFEA580C),
    ),
  };

  static AppColorPalette fromStorageKey(String? key) {
    if (key == null) return defaultPalette;
    return AppColorPalette.values.firstWhere(
      (p) => p.name == key,
      orElse: () => defaultPalette,
    );
  }
}
