part of 'bluetooth_bloc.dart';

@immutable
sealed class BluetoothState {}

final class BluetoothInitial extends BluetoothState {}

final class BluetoothSuccess extends BluetoothState {}

final class BluetoothFailure extends BluetoothState {}
