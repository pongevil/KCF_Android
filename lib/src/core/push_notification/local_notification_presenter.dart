import 'dart:io';

import 'package:bs_mobile/src/core/push_notification/models/push_notification_payload.dart';
import 'package:bs_mobile/src/core/push_notification/push_notification_config.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Displays local notifications for foreground FCM messages.
class LocalNotificationPresenter {
  LocalNotificationPresenter() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _androidInitSettings = AndroidInitializationSettings(
    '@mipmap/launcher_icon',
  );

  static const _iosInitSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  Future<void> initialize({
    void Function(PushNotificationPayload payload)? onNotificationTap,
  }) async {
    if (_initialized) return;

    final settings = const InitializationSettings(
      android: _androidInitSettings,
      iOS: _iosInitSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty || onNotificationTap == null) {
          return;
        }
        onNotificationTap(
          PushNotificationPayload.fromDataMap({'route': payload}),
        );
      },
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          PushNotificationConfig.androidChannelId,
          PushNotificationConfig.androidChannelName,
          description: PushNotificationConfig.androidChannelDescription,
          importance: Importance.high,
        ),
      );
    }

    _initialized = true;
  }

  Future<void> show(PushNotificationPayload payload) async {
    if (!_initialized) return;

    final title = payload.title ?? 'BS Mobile';
    final body = payload.body ?? '';
    if (body.isEmpty && payload.title == null) return;

    final androidDetails = AndroidNotificationDetails(
      PushNotificationConfig.androidChannelId,
      PushNotificationConfig.androidChannelName,
      channelDescription: PushNotificationConfig.androidChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: payload.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload.route,
    );
  }
}
