part of 'config_rfid_bloc.dart';

final class ConfigRfidState extends Equatable {
  const ConfigRfidState({
    this.currentPower,
    this.isLoading = true,
    this.isSetting = false,
    this.statusMessage,
    this.statusIsError = false,
  });

  final int? currentPower;
  final bool isLoading;
  final bool isSetting;
  final String? statusMessage;
  final bool statusIsError;

  ConfigRfidState copyWith({
    int? currentPower,
    bool? isLoading,
    bool? isSetting,
    String? statusMessage,
    bool? statusIsError,
    bool clearStatus = false,
  }) {
    return ConfigRfidState(
      currentPower: currentPower ?? this.currentPower,
      isLoading: isLoading ?? this.isLoading,
      isSetting: isSetting ?? this.isSetting,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
      statusIsError: clearStatus
          ? false
          : (statusIsError ?? this.statusIsError),
    );
  }

  @override
  List<Object?> get props => [
    currentPower,
    isLoading,
    isSetting,
    statusMessage,
    statusIsError,
  ];
}
