part of 'push_notification_bloc.dart';

@immutable
sealed class PushNotificationEvent {}

final class PushNotificationInit extends PushNotificationEvent {}

final class PushNotificationUnregister extends PushNotificationEvent {}
