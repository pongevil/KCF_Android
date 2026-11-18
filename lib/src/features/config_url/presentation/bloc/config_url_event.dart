part of 'config_url_bloc.dart';

sealed class ConfigUrlEvent extends Equatable {
  const ConfigUrlEvent();

  @override
  List<Object?> get props => [];
}

/// Tests reachability of [url] and persists it on success (via repository).
final class ConnectionTestRequested extends ConfigUrlEvent {
  const ConnectionTestRequested(this.host, this.port);

  final String host;
  final int port;

  @override
  List<Object?> get props => [host, port];
}
