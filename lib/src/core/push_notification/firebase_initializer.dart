import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:bs_mobile/src/core/push_notification/push_notification_config.dart';

/// Initializes Firebase when [PushNotificationConfig.enabled] is true.
///
/// Uses native `google-services.json` / `GoogleService-Info.plist` when present.
abstract final class FirebaseInitializer {
  static bool isConfigured = false;

  static Future<bool> initialize() async {
    if (!PushNotificationConfig.enabled) {
      if (kDebugMode) {
        debugPrint(
          'FirebaseInitializer: skipped (set --dart-define=ENABLE_FCM=true)',
        );
      }
      return false;
    }

    if (Firebase.apps.isNotEmpty) {
      isConfigured = true;
      return true;
    }

    try {
      await Firebase.initializeApp();
      isConfigured = true;
      if (kDebugMode) {
        debugPrint('FirebaseInitializer: initialized');
      }
      return true;
    } catch (e, stackTrace) {
      isConfigured = false;
      debugPrint('FirebaseInitializer: failed — $e\n$stackTrace');
      return false;
    }
  }
}
