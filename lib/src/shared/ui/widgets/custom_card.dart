import 'package:bs_mobile/src/core/theme/app_theme_extension.dart';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? subtitleTrailing;
  final IconData? icon;
  final Widget? headerTrailing;
  final Widget child;
  final EdgeInsets? padding;

  const CustomCard({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleTrailing,
    this.icon,
    this.headerTrailing,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.5),
                border: Border(bottom: BorderSide(color: cs.outlineVariant)),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: app.neutralIconBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: cs.onSurfaceVariant, size: 24),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: AppText(
                            title,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (subtitle != null) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: subtitleTrailing == null
                                ? [
                                    Expanded(
                                      child: AppText(
                                        subtitle!,
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ]
                                : [
                                    Expanded(
                                      child: AppText(
                                        subtitle!,
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Transform.translate(
                                      offset: const Offset(0, -4),
                                      child: subtitleTrailing!,
                                    ),
                                  ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (headerTrailing != null) ...[
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 96),
                      child: headerTrailing!,
                    ),
                  ],
                ],
              ),
            ),
            Padding(padding: padding ?? const EdgeInsets.all(24), child: child),
          ],
        ),
      ),
    );
  }
}

class CustomInfoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  const CustomInfoBox({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = Theme.of(context).extension<AppThemeExtension>()!;
    final c = color ?? cs.outlineVariant;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.withOpacity(app.infoBoxBackgroundOpacity),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: c.withOpacity(app.infoBoxBorderOpacity),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: c, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  label,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  value,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
