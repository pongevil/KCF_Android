import 'package:bs_mobile/src/core/push_notification/models/push_notification_payload.dart';
import 'package:bs_mobile/src/core/push_notification/push_notification_config.dart';
import 'package:bs_mobile/src/core/push_notification/local_notification_presenter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Top-level background FCM handler (must be registered before [runApp]).
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  if (!PushNotificationConfig.enabled) return;

  if (kDebugMode) {
    debugPrint('fcmBackgroundHandler: ${message.messageId}');
  }

  final presenter = LocalNotificationPresenter();
  await presenter.initialize();
  await presenter.show(PushNotificationPayload.fromRemoteMessage(message));
}
