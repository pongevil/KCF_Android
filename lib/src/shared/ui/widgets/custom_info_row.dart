import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:flutter/material.dart';

class InfoRowCustom extends StatelessWidget {
  final String row1;
  final String row2;
  final IconData icon;

  const InfoRowCustom({
    required this.row1,
    required this.row2,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                row1,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(height: 2),
              AppText(
                row2,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
