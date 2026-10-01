part of 'config_rfid_bloc.dart';

sealed class ConfigRfidEvent extends Equatable {
  const ConfigRfidEvent();

  @override
  List<Object?> get props => [];
}

final class ConfigRfidPowerLoadRequested extends ConfigRfidEvent {
  const ConfigRfidPowerLoadRequested();
}

final class ConfigRfidPowerSetRequested extends ConfigRfidEvent {
  const ConfigRfidPowerSetRequested(this.power);

  final int power;

  @override
  List<Object?> get props => [power];
}
