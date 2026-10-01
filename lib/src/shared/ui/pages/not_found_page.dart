import 'package:bs_mobile/src/core/routing/routes.dart';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundPage extends StatelessWidget {
  final String? path;

  const NotFoundPage({super.key, this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText('Page not found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 12),
            AppText(path == null ? 'Unknown route' : 'No route: $path'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(Routes.home),
              child: const AppText('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
