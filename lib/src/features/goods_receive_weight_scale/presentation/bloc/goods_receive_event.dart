part of 'goods_receive_bloc.dart';

sealed class GoodsReceiveEvent extends Equatable {
  const GoodsReceiveEvent();
  @override
  List<Object?> get props => [];
}

final class GoodsReceiveLoadRequested extends GoodsReceiveEvent {
  const GoodsReceiveLoadRequested(this.deviceId);
  final String deviceId;
  @override
  List<Object?> get props => [deviceId];
}

final class GoodsReceiveWeightRequested extends GoodsReceiveEvent {
  const GoodsReceiveWeightRequested(
    this.setup, {
    required this.scaleIp,
    required this.scalePort,
    this.silent = false,
  });
  final GoodsReceiveSetup setup;
  final String scaleIp;
  final int scalePort;
  final bool silent;
  @override
  List<Object?> get props => [setup, scaleIp, scalePort, silent];
}

final class GoodsReceiveSubmitRequested extends GoodsReceiveEvent {
  const GoodsReceiveSubmitRequested({
    required this.setup,
    required this.reading,
    required this.request,
  });
  final GoodsReceiveSetup setup;
  final WeightReading reading;
  final GoodsReceiveRequest request;
  @override
  List<Object?> get props => [setup, reading, request];
}

final class GoodsReceiveCloseRequested extends GoodsReceiveEvent {
  const GoodsReceiveCloseRequested(this.setup);

  final GoodsReceiveSetup setup;

  @override
  List<Object?> get props => [setup];
}
