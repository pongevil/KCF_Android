import 'package:bs_mobile/src/core/push_notification/models/push_notification_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PushNotificationPayload', () {
    test('fromDataMap resolves menu_path route', () {
      final payload = PushNotificationPayload.fromDataMap({
        'title': 'Hello',
        'body': 'World',
        'menu_path': '/home',
        'message_id': 'abc-123',
      });

      expect(payload.title, 'Hello');
      expect(payload.body, 'World');
      expect(payload.route, '/home');
      expect(payload.messageId, 'abc-123');
    });

    test('fromDataMap normalizes route without leading slash', () {
      final payload = PushNotificationPayload.fromDataMap({
        'route': 'settings',
      });

      expect(payload.route, '/settings');
    });

    test('fromDataMap prefers menu_path over route alias', () {
      final payload = PushNotificationPayload.fromDataMap({
        'menu_path': '/home',
        'route': '/settings',
      });

      expect(payload.route, '/home');
    });

    test('fromDataMap returns null route when missing', () {
      final payload = PushNotificationPayload.fromDataMap({
        'title': 'Only title',
      });

      expect(payload.route, isNull);
    });
  });
}
