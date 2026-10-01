import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:bs_mobile/src/core/push_notification/push_notification_config.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:flutter/foundation.dart';

/// Registers FCM device tokens with the backend via [ApiClient].
class PushNotificationRepository {
  PushNotificationRepository(this._client);

  final ApiClient _client;

  Future<bool> registerToken(String fcmToken) async {
    final userId = await AppStorage.getUserId();
    if (userId == null || userId.isEmpty) {
      if (kDebugMode) {
        debugPrint('PushNotificationRepository: skip register — no user id');
      }
      return false;
    }

    try {
      await _client.post(
        PushNotificationConfig.registerTokenPath,
        data: {
          'fcm_token': fcmToken,
          'user_id': userId,
          'platform': defaultTargetPlatform.name,
        },
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationRepository.registerToken failed: $e');
      }
      return false;
    }
  }

  Future<bool> unregisterToken(String fcmToken) async {
    try {
      await _client.post(
        PushNotificationConfig.unregisterTokenPath,
        data: {'fcm_token': fcmToken},
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationRepository.unregisterToken failed: $e');
      }
      return false;
    }
  }
}
