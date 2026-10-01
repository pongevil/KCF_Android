import 'package:bs_mobile/src/core/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Maps API [menu_path] values to registered app routes.
class RouteRegistry {
  RouteRegistry._();

  static const Set<String> registeredPaths = {
    Routes.splash,
    Routes.login,
    Routes.home,
    Routes.configurl,
    Routes.settings,
    Routes.configRfid,
  };

  static String normalize(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  static bool isRegistered(String? path) {
    if (path == null || path.trim().isEmpty) return false;
    return registeredPaths.contains(normalize(path));
  }

  /// Navigate from dynamic menu/API path. Uses push for sub-screens.
  static void navigateFromMenu(BuildContext context, String path) {
    final location = normalize(path);
    if (!isRegistered(location)) {
      context.push(location);
      return;
    }
    if (location == Routes.home) {
      context.go(Routes.home);
      return;
    }
    context.push(location);
  }
}
