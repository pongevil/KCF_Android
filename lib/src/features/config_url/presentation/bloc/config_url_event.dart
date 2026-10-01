part of 'config_url_bloc.dart';

sealed class ConfigUrlEvent extends Equatable {
  const ConfigUrlEvent();

  @override
  List<Object?> get props => [];
}

/// Tests reachability of [url] and persists it on success (via repository).
final class ConnectionTestRequested extends ConfigUrlEvent {
  const ConnectionTestRequested(this.url);

  final String url;

  @override
  List<Object?> get props => [url];
}
