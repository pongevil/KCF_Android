import 'package:bs_mobile/src/global/blocs/network/network_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkHelper {
  static void observe(NetworkBloc bloc) {
    Connectivity().onConnectivityChanged.listen((result) {
      final isConnected =
          result.isNotEmpty && result.first != ConnectivityResult.none;
      bloc.add(NetworkNotify(isConnected: isConnected));
    });
  }
}
