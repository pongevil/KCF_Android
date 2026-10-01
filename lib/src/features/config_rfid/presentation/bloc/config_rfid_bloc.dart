import 'package:bs_mobile/src/features/config_rfid/service/rfid_device_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'config_rfid_event.dart';
part 'config_rfid_state.dart';

class ConfigRfidBloc extends Bloc<ConfigRfidEvent, ConfigRfidState> {
  ConfigRfidBloc(this._service) : super(const ConfigRfidState()) {
    on<ConfigRfidPowerLoadRequested>(_onLoad);
    on<ConfigRfidPowerSetRequested>(_onSet);
  }

  final RfidDeviceService _service;

  Future<void> _onLoad(
    ConfigRfidPowerLoadRequested event,
    Emitter<ConfigRfidState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearStatus: true));
    try {
      final power = await _service.getPower();
      emit(state.copyWith(isLoading: false, currentPower: power));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          statusMessage: 'เกิดข้อผิดพลาด: $e',
          statusIsError: true,
        ),
      );
    }
  }

  Future<void> _onSet(
    ConfigRfidPowerSetRequested event,
    Emitter<ConfigRfidState> emit,
  ) async {
    emit(state.copyWith(isSetting: true, clearStatus: true));
    try {
      final ok = await _service.setPower(event.power);
      if (ok) {
        emit(
          state.copyWith(
            isSetting: false,
            currentPower: event.power,
            statusMessage: 'ตั้งค่าพลังงานเป็น ${event.power} สำเร็จ',
            statusIsError: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isSetting: false,
            statusMessage: 'ตั้งค่าพลังงานไม่สำเร็จ',
            statusIsError: true,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isSetting: false,
          statusMessage: 'เกิดข้อผิดพลาด: $e',
          statusIsError: true,
        ),
      );
    }
  }
}
