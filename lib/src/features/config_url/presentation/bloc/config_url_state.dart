part of 'config_url_bloc.dart';

sealed class ConfigUrlState extends Equatable {
  const ConfigUrlState();

  @override
  List<Object?> get props => [];
}

final class ConfigUrlInitial extends ConfigUrlState {
  const ConfigUrlInitial();
}

final class ConfigUrlLoading extends ConfigUrlState {
  const ConfigUrlLoading();
}

final class ConfigUrlSuccess extends ConfigUrlState {
  const ConfigUrlSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class ConfigUrlFailure extends ConfigUrlState {
  const ConfigUrlFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
