import 'package:bs_mobile/src/core/ai/ai_action.dart';
import 'package:bs_mobile/src/core/ai/models/ai_chat_response.dart';
import 'package:bs_mobile/src/core/routing/route_registry.dart';
import 'package:bs_mobile/src/shared/camera/camera_service.dart';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:flutter/material.dart';

/// Presentation-layer coordinator for AI side effects (navigation, camera,
/// SnackBar). Keep core AI models free of Flutter UI dependencies.
class AiActionCoordinator {
  AiActionCoordinator._();

  static Future<void> handle(
    BuildContext context,
    AiChatResponse response,
  ) async {
    switch (response.actionType) {
      case AiActionType.answerOnly:
      case AiActionType.pendingCrud:
        return;
      case AiActionType.navigate:
        await _handleNavigate(context, response);
      case AiActionType.openScanner:
        await _handleScanner(context);
      case AiActionType.unknown:
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(
              'AI action "${response.aiDecision}" is not supported on mobile yet.',
            ),
          ),
        );
    }
  }

  static Future<void> _handleNavigate(
    BuildContext context,
    AiChatResponse response,
  ) async {
    final route = _readRoute(response.raw);
    if (route == null || route.isEmpty) return;

    if (!context.mounted) return;
    RouteRegistry.navigateFromMenu(context, route);
  }

  static String? _readRoute(Map<String, dynamic> raw) {
    for (final key in ['route', 'navigate_to', 'navigateTo', 'path']) {
      final value = raw[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return null;
  }

  static Future<void> _handleScanner(BuildContext context) async {
    final code = await CameraService.scanBarcode(context);
    if (!context.mounted || code == null || code.isEmpty) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: AppText('Scanned: $code')));
  }
}
