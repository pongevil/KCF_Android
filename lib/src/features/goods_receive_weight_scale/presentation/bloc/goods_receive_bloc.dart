import 'package:bloc/bloc.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/models/goods_receive_models.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/repository/goods_receive_repository.dart';
import 'package:equatable/equatable.dart';

part 'goods_receive_event.dart';
part 'goods_receive_state.dart';

class GoodsReceiveBloc extends Bloc<GoodsReceiveEvent, GoodsReceiveState> {
  GoodsReceiveBloc(this._repository) : super(const GoodsReceiveInitial()) {
    on<GoodsReceiveLoadRequested>(_load);
    on<GoodsReceiveWeightRequested>(_readWeight);
    on<GoodsReceiveSubmitRequested>(_submit);
    on<GoodsReceiveCloseRequested>(_closeLatestOrder);
  }
  final GoodsReceiveRepository _repository;

  Future<void> _load(
    GoodsReceiveLoadRequested event,
    Emitter<GoodsReceiveState> emit,
  ) async {
    emit(const GoodsReceiveLoading());
    try {
      emit(
        GoodsReceiveReady(
          await _repository.fetchSetup(deviceId: event.deviceId),
        ),
      );
    } catch (error) {
      emit(GoodsReceiveFailure(error.toString()));
    }
  }

  Future<void> _readWeight(
    GoodsReceiveWeightRequested event,
    Emitter<GoodsReceiveState> emit,
  ) async {
    if (!event.silent || state is GoodsReceiveWeightFailure) {
      emit(GoodsReceiveWeightLoading(event.setup));
    }
    try {
      final reading = await _repository.readWeight(
        scaleId: event.setup.station.scaleId,
        scaleIp: event.scaleIp,
        scalePort: event.scalePort,
      );
      if (!reading.isStable || reading.weightKg < 0) {
        emit(GoodsReceiveWeightFailure(event.setup, 'Weight is not stable'));
        return;
      }
      emit(GoodsReceiveWeightReady(event.setup, reading));
    } catch (error) {
      emit(GoodsReceiveWeightFailure(event.setup, error.toString()));
    }
  }

  Future<void> _submit(
    GoodsReceiveSubmitRequested event,
    Emitter<GoodsReceiveState> emit,
  ) async {
    final request = event.request;
    if (request.cartId.trim().isEmpty ||
        request.skuId.isEmpty ||
        request.packagingId.isEmpty ||
        request.weightKg <= 0) {
      emit(
        GoodsReceiveFailure(
          'Please complete every receive step',
          setup: event.setup,
          reading: event.reading,
        ),
      );
      return;
    }
    emit(GoodsReceiveSubmitting(event.setup, event.reading));
    try {
      emit(
        GoodsReceiveSuccess(event.setup, await _repository.receive(request)),
      );
    } catch (error) {
      emit(
        GoodsReceiveFailure(
          error.toString(),
          setup: event.setup,
          reading: event.reading,
        ),
      );
    }
  }

  Future<void> _closeLatestOrder(
    GoodsReceiveCloseRequested event,
    Emitter<GoodsReceiveState> emit,
  ) async {
    final scaleMappingId = event.setup.station.scaleId.trim();
    if (scaleMappingId.isEmpty) {
      emit(
        GoodsReceiveFailure(
          'Scale mapping is not configured',
          setup: event.setup,
        ),
      );
      return;
    }

    emit(GoodsReceiveClosing(event.setup));
    try {
      final message = await _repository.closeLatestOrder(
        scaleMappingId: scaleMappingId,
      );
      emit(GoodsReceiveCloseSuccess(event.setup, message));
    } catch (error) {
      emit(GoodsReceiveFailure(error.toString(), setup: event.setup));
    }
  }
}
