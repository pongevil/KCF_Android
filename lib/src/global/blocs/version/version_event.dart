part of 'version_bloc.dart';

@immutable
sealed class VersionEvent {}

class VersionCheckEvent extends VersionEvent {
  VersionCheckEvent();
}

class VersionDownloadEvent extends VersionEvent {
  VersionDownloadEvent();
}
