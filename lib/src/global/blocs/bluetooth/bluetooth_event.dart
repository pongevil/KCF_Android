part of 'bluetooth_bloc.dart';

@immutable
sealed class BluetoothEvent extends Equatable {}

class BluetoothObserve extends BluetoothEvent {
  BluetoothObserve();
  @override
  List<Object?> get props => [];
}

class BluetoothNotify extends BluetoothEvent {
  BluetoothNotify({this.isConnected = false});
  @override
  List<Object?> get props => [isConnected];
  final bool isConnected;
}
