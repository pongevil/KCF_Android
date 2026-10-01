import 'package:flutter/material.dart';

/// Singleton navigation service providing a global [NavigatorKey].
class AppNavigation {
  static final AppNavigation _instance = AppNavigation._();
  factory AppNavigation() => _instance;
  AppNavigation._();

  static AppNavigation get instance => _instance;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

/// Global convenience accessor.
final appNavigation = AppNavigation.instance;
