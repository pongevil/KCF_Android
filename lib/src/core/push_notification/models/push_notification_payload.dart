import 'package:firebase_messaging/firebase_messaging.dart';

/// Normalized push payload from FCM [RemoteMessage].
class PushNotificationPayload {
  const PushNotificationPayload({
    required this.title,
    required this.body,
    required this.data,
    this.route,
    this.messageId,
  });

  final String? title;
  final String? body;
  final Map<String, String> data;
  final String? route;
  final String? messageId;

  factory PushNotificationPayload.fromRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );

    return PushNotificationPayload(
      title: notification?.title ?? data['title'],
      body: notification?.body ?? data['body'],
      data: data,
      route: _resolveRoute(data),
      messageId: message.messageId,
    );
  }

  factory PushNotificationPayload.fromDataMap(Map<String, dynamic> raw) {
    final data = raw.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );

    return PushNotificationPayload(
      title: data['title'],
      body: data['body'],
      data: data,
      route: _resolveRoute(data),
      messageId: data['message_id'],
    );
  }

  static String? _resolveRoute(Map<String, String> data) {
    final route = data['menu_path'] ?? data['route'] ?? data['path'];
    if (route == null || route.trim().isEmpty) return null;
    final trimmed = route.trim();
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }
}
