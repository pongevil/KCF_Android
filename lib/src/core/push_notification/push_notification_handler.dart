import 'package:bs_mobile/src/core/push_notification/models/push_notification_payload.dart';

/// Callback registry for push notification events (no UI imports).
class PushNotificationHandler {
  void Function(PushNotificationPayload payload)? onForegroundMessage;
  void Function(PushNotificationPayload payload)? onMessageOpenedApp;
  void Function(String token)? onTokenRefresh;
}
