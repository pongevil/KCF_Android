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
  const ConfigUrlSuccess();
}

final class ConfigUrlFailure extends ConfigUrlState {
  const ConfigUrlFailure();
}
