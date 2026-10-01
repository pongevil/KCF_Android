part of 'network_bloc.dart';

@immutable
abstract class NetworkEvent {}

class NetworkObserve extends NetworkEvent {
  final NetworkBloc bloc;
  NetworkObserve(this.bloc);
}

class NetworkNotify extends NetworkEvent {
  final bool isConnected;
  NetworkNotify({this.isConnected = false});
}
