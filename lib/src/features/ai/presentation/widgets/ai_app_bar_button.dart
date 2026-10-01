import 'package:bs_mobile/src/core/localization/locale_extension.dart';
import 'package:bs_mobile/src/core/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';

/// Prominent AI action button for app bars.
class AiAppBarAction extends StatelessWidget {
  const AiAppBarAction({super.key, required this.onPressed, this.tooltip});

  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = theme.extension<AppThemeExtension>()!;
    final contentColor = app.barContentColor;
    final label = context.tr('mobile.ai_assistant_short', fallback: 'AI');

    final child = Padding(
      padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: app.headerGradient,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: app.appBarShadowColor.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: contentColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: contentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final resolvedTooltip =
        tooltip ?? context.tr('mobile.ai_assistant', fallback: 'ผู้ช่วย AI');

    return Tooltip(message: resolvedTooltip, child: child);
  }
}
