import 'package:bs_mobile/src/core/push_notification/push_notification_service.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'push_notification_event.dart';
part 'push_notification_state.dart';

class PushNotificationBloc
    extends Bloc<PushNotificationEvent, PushNotificationState> {
  PushNotificationBloc(this._service) : super(PushNotificationInitial()) {
    on<PushNotificationInit>(_onInit);
    on<PushNotificationUnregister>(_onUnregister);
  }

  final PushNotificationService _service;

  Future<void> _onInit(
    PushNotificationInit event,
    Emitter<PushNotificationState> emit,
  ) async {
    emit(PushNotificationInitializing());
    final status = await _service.initialize();

    switch (status.result) {
      case PushNotificationInitResult.disabled:
        emit(PushNotificationDisabled(reason: status.reason));
      case PushNotificationInitResult.firebaseNotConfigured:
        emit(PushNotificationDisabled(reason: status.reason));
      case PushNotificationInitResult.permissionDenied:
        emit(PushNotificationPermissionDenied(reason: status.reason));
      case PushNotificationInitResult.ready:
        emit(PushNotificationReady(token: status.token));
      case PushNotificationInitResult.failure:
        emit(PushNotificationFailure(status.reason ?? 'Unknown error'));
    }
  }

  Future<void> _onUnregister(
    PushNotificationUnregister event,
    Emitter<PushNotificationState> emit,
  ) async {
    await _service.unregister();
    emit(PushNotificationDisabled(reason: 'Unregistered'));
  }
}
