import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'bluetooth_event.dart';
part 'bluetooth_state.dart';

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothState> {
  BluetoothBloc._() : super(BluetoothInitial()) {
    on<BluetoothObserve>(_onObserve);
    on<BluetoothNotify>(_onNotify);
  }

  static final BluetoothBloc _instance = BluetoothBloc._();
  factory BluetoothBloc() => _instance;

  void _onObserve(BluetoothObserve event, Emitter<BluetoothState> emit) {
    // BluetoothObserve is a no-op until a BLE plugin is wired.
    // Intentionally empty — keeps event registered for future hardware work.
  }

  void _onNotify(BluetoothNotify event, Emitter<BluetoothState> emit) {
    event.isConnected ? emit(BluetoothSuccess()) : emit(BluetoothFailure());
  }
}
