import 'package:bs_mobile/src/core/helpers/network_helper.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'network_event.dart';
part 'network_state.dart';

class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  NetworkBloc() : super(NetworkInitial()) {
    on<NetworkObserve>(_onObserve);
    on<NetworkNotify>(_onNotify);
  }

  void _onObserve(NetworkObserve event, Emitter<NetworkState> emit) {
    NetworkHelper.observe(event.bloc);
  }

  Future<void> _onNotify(
    NetworkNotify event,
    Emitter<NetworkState> emit,
  ) async {
    await AppStorage.setNetwork(event.isConnected);
    event.isConnected ? emit(NetworkSuccess()) : emit(NetworkFailure());
  }
}
