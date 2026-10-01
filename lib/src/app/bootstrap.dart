import 'dart:io';

import 'package:bs_mobile/src/app/app.dart';
import 'package:bs_mobile/src/app/di/app_bloc_listeners.dart';
import 'package:bs_mobile/src/app/di/injection.dart';
import 'package:bs_mobile/src/core/network/api_error_notifier.dart';
import 'package:bs_mobile/src/core/network/config/http_overrides.dart';
import 'package:bs_mobile/src/core/network/session_expired_handler.dart';
import 'package:bs_mobile/src/core/push_notification/push_notification_config.dart';
import 'package:bs_mobile/src/core/push_notification/push_notification_service.dart';
import 'package:bs_mobile/src/database/core/app_database.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = DevHttpOverrides();

  await AppDatabase.instance.open();
  await configureDependencies();

  final packageInfo = await PackageInfo.fromPlatform();
  await AppStorage.setVersion(packageInfo.version);

  wireAppNotifiers(
    sessionExpiredHandler: getIt<SessionExpiredHandler>(),
    errorNotifier: getIt<ApiErrorNotifier>(),
  );
  wirePushNotificationHandler();

  if (PushNotificationConfig.enabled) {
    await getIt<PushNotificationService>().initialize();
  }

  runApp(const App());
}
