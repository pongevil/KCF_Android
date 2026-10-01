import 'package:bs_mobile/src/app/di/injection.dart';
import 'package:bs_mobile/src/core/navigation/app_navigation.dart';
import 'package:bs_mobile/src/core/routing/route_registry.dart';
import 'package:bs_mobile/src/core/routing/routes.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:bs_mobile/src/features/auth/presentation/pages/login_page.dart';
import 'package:bs_mobile/src/features/config_rfid/presentation/bloc/config_rfid_bloc.dart';
import 'package:bs_mobile/src/features/config_rfid/presentation/pages/config_rfid_page.dart';
import 'package:bs_mobile/src/features/config_url/presentation/pages/config_url_page.dart';
import 'package:bs_mobile/src/features/home/presentation/pages/home_page.dart';
import 'package:bs_mobile/src/features/settings/presentation/pages/settings_page.dart';
import 'package:bs_mobile/src/features/splash/presentation/pages/splash_page.dart';
import 'package:bs_mobile/src/shared/ui/pages/not_found_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter._();

  static const _publicPaths = {Routes.splash, Routes.login, Routes.configurl};

  static GoRouter create() {
    return GoRouter(
      navigatorKey: appNavigation.navigatorKey,
      initialLocation: Routes.splash,
      debugLogDiagnostics: true,
      redirect: _redirect,
      errorBuilder: (context, state) =>
          NotFoundPage(path: state.uri.toString()),
      routes: [
        _pageRoute(Routes.splash, const SplashPage()),
        _pageRoute(Routes.login, const LoginPage()),
        _pageRoute(Routes.configurl, const ConfigUrlPage()),
        _pageRoute(Routes.home, const HomePage()),
        _pageRoute(Routes.settings, const SettingsPage()),
        _pageRoute(
          Routes.configRfid,
          BlocProvider(
            create: (_) =>
                getIt<ConfigRfidBloc>()
                  ..add(const ConfigRfidPowerLoadRequested()),
            child: const ConfigRfidPage(),
          ),
        ),
      ],
    );
  }

  static Future<String?> _redirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    final location = RouteRegistry.normalize(state.uri.path);
    if (_publicPaths.contains(location)) return null;

    final token = await AppStorage.getToken();
    if (token == null || token.isEmpty) {
      return Routes.login;
    }
    return null;
  }

  static GoRoute _pageRoute(String path, Widget child) {
    return GoRoute(
      path: path,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: child,
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (path == Routes.splash) return child;
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuart,
            reverseCurve: Curves.easeInQuart,
          );
          return FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(curved),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
