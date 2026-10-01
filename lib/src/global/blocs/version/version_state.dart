part of 'version_bloc.dart';

@immutable
sealed class VersionState {}

final class VersionInitial extends VersionState {}

final class VersionCheckInProgress extends VersionState {}

final class VersionCheckSuccess extends VersionState {
  final String latestVersion;
  final String releaseNotes;

  VersionCheckSuccess(this.latestVersion, this.releaseNotes);
}

final class VersionCheckFailure extends VersionState {
  final String error;

  VersionCheckFailure(this.error);
}

final class VersionUpToDate extends VersionState {}

final class VersionUpdateAvailable extends VersionState {
  final String message;
  final bool isForceUpdate;

  VersionUpdateAvailable(this.message, {this.isForceUpdate = false});
}

final class VersionDownloadInProgress extends VersionState {}

final class VersionDownloading extends VersionState {
  final int progress;

  VersionDownloading(this.progress);
}

enum VersionAlertType { success, info, error }

final class VersionDownloadNotify extends VersionState {
  final String message;
  final VersionAlertType alertType;

  VersionDownloadNotify(this.message, this.alertType);
}

final class VersionShouldOpenApk extends VersionState {
  final String path;

  VersionShouldOpenApk(this.path);
}

final class VersionShouldExitApp extends VersionState {}

final class VersionDownloadSuccess extends VersionState {
  final String message;

  VersionDownloadSuccess(this.message);
}

final class VersionDownloadFailure extends VersionState {
  final String error;

  VersionDownloadFailure(this.error);
}

final class VersionDownloadDismissLoading extends VersionState {}
