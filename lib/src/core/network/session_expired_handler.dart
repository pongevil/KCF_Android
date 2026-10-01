import 'package:bs_mobile/src/global/local/app_storage.dart';

/// Clears session persistence and notifies the app to navigate / alert.
///
/// Navigation is injected from the app layer so core does not import GetIt
/// or [GoRouter] directly.
class SessionExpiredHandler {
  SessionExpiredHandler({this.navigateToLogin});

  /// App-level callback (e.g. `getIt<GoRouter>().go(Routes.login)`).
  void Function()? navigateToLogin;

  /// Optional UI notifier (wired to [CustomShowAlert] from app).
  void Function(String message)? onNotify;

  Future<void> handle({
    String message = 'Session expired, please log in again',
  }) async {
    await AppStorage.clearCacheData();
    navigateToLogin?.call();
    onNotify?.call(message);
  }
}
