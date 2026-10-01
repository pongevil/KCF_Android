import 'package:flutter/material.dart';

import 'app_theme_extension.dart';

extension ThemeContextX on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>()!;
}
