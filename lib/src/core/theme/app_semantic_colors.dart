import 'package:flutter/material.dart';

/// Global semantic status colors (consistent across all palettes).
class AppSemanticColors {
  const AppSemanticColors._();

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFF6600);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF06B6D4);

  static const Color onLight = Colors.white;
}

/// Button and status colors resolved for a specific theme brightness.
class AppButtonColors {
  const AppButtonColors({
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
  });

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

  factory AppButtonColors.fromColorScheme(ColorScheme cs) {
    return AppButtonColors(
      buttonPrimary: cs.primary,
      buttonPrimaryOn: cs.onPrimary,
      buttonSuccess: AppSemanticColors.success,
      buttonSuccessOn: AppSemanticColors.onLight,
      buttonDanger: cs.error,
      buttonDangerOn: cs.onError,
      buttonWarning: AppSemanticColors.warning,
      buttonWarningOn: AppSemanticColors.onLight,
      buttonDisabled: cs.surfaceContainerHighest,
      buttonDisabledOn: cs.onSurface.withValues(alpha: 0.38),
      success: AppSemanticColors.success,
      warning: AppSemanticColors.warning,
      error: AppSemanticColors.error,
      info: AppSemanticColors.info,
    );
  }
}
