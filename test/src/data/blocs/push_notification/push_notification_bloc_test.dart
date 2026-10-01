import 'package:bloc_test/bloc_test.dart';
import 'package:bs_mobile/src/core/push_notification/push_notification_service.dart';
import 'package:bs_mobile/src/global/blocs/push_notification/push_notification_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPushNotificationService extends Mock
    implements PushNotificationService {}

void main() {
  late _MockPushNotificationService service;

  setUp(() {
    service = _MockPushNotificationService();
  });

  blocTest<PushNotificationBloc, PushNotificationState>(
    'emits PushNotificationDisabled when FCM is disabled',
    build: () {
      when(() => service.initialize()).thenAnswer(
        (_) async => PushNotificationInitStatus(
          result: PushNotificationInitResult.disabled,
          reason: 'FCM disabled',
        ),
      );
      return PushNotificationBloc(service);
    },
    act: (bloc) => bloc.add(PushNotificationInit()),
    expect: () => [
      isA<PushNotificationInitializing>(),
      isA<PushNotificationDisabled>().having(
        (s) => s.reason,
        'reason',
        'FCM disabled',
      ),
    ],
  );

  blocTest<PushNotificationBloc, PushNotificationState>(
    'emits PushNotificationReady when init succeeds',
    build: () {
      when(() => service.initialize()).thenAnswer(
        (_) async => PushNotificationInitStatus(
          result: PushNotificationInitResult.ready,
          token: 'test-token',
        ),
      );
      return PushNotificationBloc(service);
    },
    act: (bloc) => bloc.add(PushNotificationInit()),
    expect: () => [
      isA<PushNotificationInitializing>(),
      isA<PushNotificationReady>().having(
        (s) => s.token,
        'token',
        'test-token',
      ),
    ],
  );

  blocTest<PushNotificationBloc, PushNotificationState>(
    'emits PushNotificationPermissionDenied when permission denied',
    build: () {
      when(() => service.initialize()).thenAnswer(
        (_) async => PushNotificationInitStatus(
          result: PushNotificationInitResult.permissionDenied,
          reason: 'denied',
        ),
      );
      return PushNotificationBloc(service);
    },
    act: (bloc) => bloc.add(PushNotificationInit()),
    expect: () => [
      isA<PushNotificationInitializing>(),
      isA<PushNotificationPermissionDenied>(),
    ],
  );
}
