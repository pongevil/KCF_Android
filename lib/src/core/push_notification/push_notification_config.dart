/// Push notification / FCM configuration.
abstract final class PushNotificationConfig {
  /// Android notification channel id (must match manifest meta-data when set).
  static const androidChannelId = 'bs_mobile_default';

  static const androidChannelName = 'BS Mobile Notifications';
  static const androidChannelDescription =
      'Default channel for BS Mobile push notifications';

  /// Stub endpoint — wire to backend when API is ready.
  static const registerTokenPath = 'mobile/fcm/register';
  static const unregisterTokenPath = 'mobile/fcm/unregister';

  /// Enable FCM via `--dart-define=ENABLE_FCM=true` after native Firebase setup.
  static const bool enabled = bool.fromEnvironment('ENABLE_FCM');
}
