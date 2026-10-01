import 'dart:io';

import 'package:bs_mobile/src/core/push_notification/firebase_initializer.dart';
import 'package:bs_mobile/src/core/push_notification/local_notification_presenter.dart';
import 'package:bs_mobile/src/core/push_notification/models/push_notification_payload.dart';
import 'package:bs_mobile/src/core/push_notification/push_notification_config.dart';
import 'package:bs_mobile/src/core/push_notification/push_notification_handler.dart';
import 'package:bs_mobile/src/core/push_notification/push_notification_repository.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum PushNotificationInitResult {
  disabled,
  firebaseNotConfigured,
  permissionDenied,
  ready,
  failure,
}

class PushNotificationInitStatus {
  const PushNotificationInitStatus({
    required this.result,
    this.token,
    this.reason,
  });

  final PushNotificationInitResult result;
  final String? token;
  final String? reason;
}

/// Orchestrates FCM setup, permissions, token persistence, and message streams.
class PushNotificationService {
  PushNotificationService({
    required PushNotificationHandler handler,
    required PushNotificationRepository repository,
    LocalNotificationPresenter? presenter,
  }) : _handler = handler,
       _repository = repository,
       _presenter = presenter ?? LocalNotificationPresenter();

  final PushNotificationHandler _handler;
  final PushNotificationRepository _repository;
  final LocalNotificationPresenter _presenter;

  bool _streamsAttached = false;
  PushNotificationInitStatus? _lastStatus;

  Future<PushNotificationInitStatus> initialize() async {
    if (_lastStatus != null) return _lastStatus!;

    if (!PushNotificationConfig.enabled) {
      return _cache(
        PushNotificationInitStatus(
          result: PushNotificationInitResult.disabled,
          reason: 'FCM disabled — use --dart-define=ENABLE_FCM=true',
        ),
      );
    }

    final firebaseReady = await FirebaseInitializer.initialize();
    if (!firebaseReady) {
      return _cache(
        PushNotificationInitStatus(
          result: PushNotificationInitResult.firebaseNotConfigured,
          reason:
              'Firebase not configured — add google-services.json / GoogleService-Info.plist (see docs/FCM_INTEGRATION.md)',
        ),
      );
    }

    try {
      await _presenter.initialize(
        onNotificationTap: _handler.onMessageOpenedApp,
      );

      final permissionGranted = await _requestPermissions();
      if (!permissionGranted) {
        return _cache(
          PushNotificationInitStatus(
            result: PushNotificationInitResult.permissionDenied,
            reason: 'Notification permission denied',
          ),
        );
      }

      await _attachMessageStreams();

      final messaging = FirebaseMessaging.instance;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await AppStorage.setFcmToken(token);
        _handler.onTokenRefresh?.call(token);
        await _repository.registerToken(token);
      }

      messaging.onTokenRefresh.listen((token) async {
        await AppStorage.setFcmToken(token);
        _handler.onTokenRefresh?.call(token);
        await _repository.registerToken(token);
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handler.onMessageOpenedApp?.call(
          PushNotificationPayload.fromRemoteMessage(initialMessage),
        );
      }

      return _cache(
        PushNotificationInitStatus(
          result: PushNotificationInitResult.ready,
          token: token,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('PushNotificationService.initialize failed: $e\n$stackTrace');
      return _cache(
        PushNotificationInitStatus(
          result: PushNotificationInitResult.failure,
          reason: e.toString(),
        ),
      );
    }
  }

  PushNotificationInitStatus _cache(PushNotificationInitStatus status) {
    _lastStatus = status;
    return status;
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (!status.isGranted) return false;
    }

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> _attachMessageStreams() async {
    if (_streamsAttached) return;
    _streamsAttached = true;

    FirebaseMessaging.onMessage.listen((message) async {
      final payload = PushNotificationPayload.fromRemoteMessage(message);
      _handler.onForegroundMessage?.call(payload);
      await _presenter.show(payload);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handler.onMessageOpenedApp?.call(
        PushNotificationPayload.fromRemoteMessage(message),
      );
    });
  }

  Future<void> unregister() async {
    final token = await AppStorage.getFcmToken();
    if (token != null && token.isNotEmpty) {
      await _repository.unregisterToken(token);
    }
    await AppStorage.clearFcmToken();
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    _lastStatus = null;
    _streamsAttached = false;
  }
}
