import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:flutter/material.dart';

/// Placeholder for WMS / upcoming features.
class ComingSoonPage extends StatelessWidget {
  final String title;

  const ComingSoonPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: AppText(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction, size: 64, color: cs.primary),
            const SizedBox(height: 16),
            AppText(
              '$title - coming soon',
              style: TextStyle(fontSize: 18, color: cs.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
