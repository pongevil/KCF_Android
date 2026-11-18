import 'package:flutter/material.dart';

import 'app_color_palette.dart';
import 'app_theme_extension.dart';

extension ThemeContextX on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  AppThemeExtension get appTheme {
    final theme = Theme.of(this);
    return theme.extension<AppThemeExtension>() ??
        AppThemeExtension.fromPalette(
          palette: AppColorPaletteX.defaultPalette,
          cs: theme.colorScheme,
          brightness: theme.brightness,
          shadowColor: theme.shadowColor,
        );
  }
}
