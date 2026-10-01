import 'package:bs_mobile/src/app/di/injection.dart';
import 'package:bs_mobile/src/core/navigation/app_navigation.dart';
import 'package:bs_mobile/src/core/network/api_error_notifier.dart';
import 'package:bs_mobile/src/core/network/session_expired_handler.dart';
import 'package:bs_mobile/src/core/push_notification/models/push_notification_payload.dart';
import 'package:bs_mobile/src/core/push_notification/push_notification_handler.dart';
import 'package:bs_mobile/src/core/routing/route_registry.dart';
import 'package:bs_mobile/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bs_mobile/src/global/blocs/version/version_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_file/open_file.dart';

import '../../shared/index.dart';

/// Central place for BLoC side-effects that belong in the presentation layer.
class AppBlocListeners extends StatefulWidget {
  final Widget child;

  const AppBlocListeners({super.key, required this.child});

  @override
  State<AppBlocListeners> createState() => _AppBlocListenersState();
}

class _AppBlocListenersState extends State<AppBlocListeners> {
  bool _updateDialogShown = false;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthLogout) {
              CustomShowAlert.showSuccess(
                state.authResponseModel?.messageText ?? 'Logged out',
              );
            }
          },
        ),
        BlocListener<VersionBloc, VersionState>(
          listener: (context, state) async {
            if (state is VersionUpdateAvailable) {
              if (_updateDialogShown) return;
              final navContext = appNavigation.navigatorKey.currentContext;
              if (navContext == null || !navContext.mounted) return;
              _updateDialogShown = true;
              await showDialog<void>(
                context: navContext,
                barrierDismissible: !state.isForceUpdate,
                builder: (_) => VersionUpdateDialog(
                  message: state.message,
                  isForceUpdate: state.isForceUpdate,
                ),
              );
              _updateDialogShown = false;
            } else if (state is VersionDownloading) {
              if (state.progress == 0) {
                CustomLoading.showProgress(
                  progress: 0,
                  text: 'Downloading... 0%',
                );
              } else {
                CustomLoading.setProgress(
                  state.progress / 100,
                  text: 'Downloading... ${state.progress}%',
                );
              }
            } else if (state is VersionDownloadNotify) {
              CustomLoading.dismiss(
                messageText: state.message,
                alertType: _mapAlertType(state.alertType),
              );
              if (state.alertType == VersionAlertType.success) {
                await Future<void>.delayed(const Duration(seconds: 1));
              }
            } else if (state is VersionShouldOpenApk) {
              final result = await OpenFile.open(state.path);
              if (result.type == ResultType.done) {
                await Future<void>.delayed(const Duration(seconds: 1));
                await SystemChannels.platform.invokeMethod<void>(
                  'SystemNavigator.pop',
                );
              } else if (result.type == ResultType.noAppToOpen) {
                CustomLoading.dismiss(
                  messageText: "Please enable 'Install from Unknown Sources'",
                  alertType: CustomAlertType.info,
                );
              } else if (result.type == ResultType.permissionDenied) {
                CustomLoading.dismiss(
                  messageText:
                      'Install permission denied. Enable it in Settings.',
                  alertType: CustomAlertType.info,
                );
              } else if (result.type == ResultType.fileNotFound) {
                CustomLoading.dismiss(
                  messageText:
                      'APK not found. Please reinstall or download again.',
                  alertType: CustomAlertType.info,
                );
              } else {
                CustomLoading.dismiss(
                  messageText: 'Unable to launch installer.',
                  alertType: CustomAlertType.info,
                );
              }
            } else if (state is VersionDownloadDismissLoading) {
              CustomLoading.dismiss();
            } else if (state is VersionDownloadFailure) {
              CustomLoading.dismiss();
              CustomShowAlert.showError(state.error);
            }
          },
        ),
      ],
      child: widget.child,
    );
  }

  CustomAlertType _mapAlertType(VersionAlertType type) {
    switch (type) {
      case VersionAlertType.success:
        return CustomAlertType.success;
      case VersionAlertType.info:
        return CustomAlertType.info;
      case VersionAlertType.error:
        return CustomAlertType.error;
    }
  }
}

void wireAppNotifiers({
  required SessionExpiredHandler sessionExpiredHandler,
  required ApiErrorNotifier errorNotifier,
}) {
  sessionExpiredHandler.onNotify = errorNotifier.showError;
  errorNotifier.onError = CustomShowAlert.showError;
}

void wirePushNotificationHandler() {
  final handler = getIt<PushNotificationHandler>();
  handler.onMessageOpenedApp = _navigateFromPushPayload;
}

void _navigateFromPushPayload(PushNotificationPayload payload) {
  final route = payload.route;
  if (route == null || route.isEmpty) return;

  final context = appNavigation.navigatorKey.currentContext;
  if (context == null || !context.mounted) return;

  RouteRegistry.navigateFromMenu(context, route);
}
