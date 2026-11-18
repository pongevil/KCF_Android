import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'src/app/bootstrap.dart';
import 'src/core/push_notification/fcm_background_handler.dart';
import 'src/core/push_notification/push_notification_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  if (PushNotificationConfig.enabled) {
    FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
  }
  await bootstrap();
}
