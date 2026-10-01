part of 'push_notification_bloc.dart';

@immutable
sealed class PushNotificationState {}

final class PushNotificationInitial extends PushNotificationState {}

final class PushNotificationInitializing extends PushNotificationState {}

final class PushNotificationDisabled extends PushNotificationState {
  PushNotificationDisabled({this.reason});

  final String? reason;
}

final class PushNotificationPermissionDenied extends PushNotificationState {
  PushNotificationPermissionDenied({this.reason});

  final String? reason;
}

final class PushNotificationReady extends PushNotificationState {
  PushNotificationReady({this.token});

  final String? token;
}

final class PushNotificationFailure extends PushNotificationState {
  PushNotificationFailure(this.message);

  final String message;
}
