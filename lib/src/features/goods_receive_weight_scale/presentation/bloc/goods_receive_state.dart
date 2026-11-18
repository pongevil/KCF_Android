part of 'goods_receive_bloc.dart';

sealed class GoodsReceiveState extends Equatable {
  const GoodsReceiveState();
  @override
  List<Object?> get props => [];
}

final class GoodsReceiveInitial extends GoodsReceiveState {
  const GoodsReceiveInitial();
}

final class GoodsReceiveLoading extends GoodsReceiveState {
  const GoodsReceiveLoading();
}

final class GoodsReceiveReady extends GoodsReceiveState {
  const GoodsReceiveReady(this.setup);
  final GoodsReceiveSetup setup;
  @override
  List<Object?> get props => [setup];
}

final class GoodsReceiveWeightLoading extends GoodsReceiveState {
  const GoodsReceiveWeightLoading(this.setup);
  final GoodsReceiveSetup setup;
  @override
  List<Object?> get props => [setup];
}

final class GoodsReceiveWeightReady extends GoodsReceiveState {
  const GoodsReceiveWeightReady(this.setup, this.reading);
  final GoodsReceiveSetup setup;
  final WeightReading reading;
  @override
  List<Object?> get props => [setup, reading];
}

final class GoodsReceiveWeightFailure extends GoodsReceiveState {
  const GoodsReceiveWeightFailure(this.setup, this.message);

  final GoodsReceiveSetup setup;
  final String message;

  @override
  List<Object?> get props => [setup, message];
}

final class GoodsReceiveSubmitting extends GoodsReceiveState {
  const GoodsReceiveSubmitting(this.setup, this.reading);
  final GoodsReceiveSetup setup;
  final WeightReading reading;
  @override
  List<Object?> get props => [setup, reading];
}

final class GoodsReceiveSuccess extends GoodsReceiveState {
  const GoodsReceiveSuccess(this.setup, this.label);
  final GoodsReceiveSetup setup;
  final GoodsReceiveLabel label;
  @override
  List<Object?> get props => [setup, label];
}

final class GoodsReceiveClosing extends GoodsReceiveState {
  const GoodsReceiveClosing(this.setup);

  final GoodsReceiveSetup setup;

  @override
  List<Object?> get props => [setup];
}

final class GoodsReceiveCloseSuccess extends GoodsReceiveState {
  const GoodsReceiveCloseSuccess(this.setup, this.message);

  final GoodsReceiveSetup setup;
  final String message;

  @override
  List<Object?> get props => [setup, message];
}

final class GoodsReceiveFailure extends GoodsReceiveState {
  const GoodsReceiveFailure(this.message, {this.setup, this.reading});
  final String message;
  final GoodsReceiveSetup? setup;
  final WeightReading? reading;
  @override
  List<Object?> get props => [message, setup, reading];
}
