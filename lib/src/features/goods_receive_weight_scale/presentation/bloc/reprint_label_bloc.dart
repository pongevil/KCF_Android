import 'package:bloc/bloc.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/models/goods_receive_models.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/repository/goods_receive_repository.dart';
import 'package:equatable/equatable.dart';

sealed class ReprintLabelEvent extends Equatable {
  const ReprintLabelEvent();
  @override
  List<Object?> get props => [];
}

final class ReprintLabelsLoadRequested extends ReprintLabelEvent {
  const ReprintLabelsLoadRequested({this.lineId, this.searchText});
  final String? lineId, searchText;
  @override
  List<Object?> get props => [lineId, searchText];
}

final class ReprintLabelsRequested extends ReprintLabelEvent {
  const ReprintLabelsRequested(
    this.labels, {
    required this.printerIp,
    required this.printerToken,
  });
  final List<GoodsReceiveLabel> labels;
  final String printerIp, printerToken;
  @override
  List<Object?> get props => [labels, printerIp, printerToken];
}

sealed class ReprintLabelState extends Equatable {
  const ReprintLabelState();
  @override
  List<Object?> get props => [];
}

final class ReprintLabelInitial extends ReprintLabelState {
  const ReprintLabelInitial();
}

final class ReprintLabelLoading extends ReprintLabelState {
  const ReprintLabelLoading();
}

final class ReprintLabelLoaded extends ReprintLabelState {
  const ReprintLabelLoaded(this.items);
  final List<GoodsReceiveLabel> items;
  @override
  List<Object?> get props => [items];
}

final class ReprintLabelSuccess extends ReprintLabelState {
  const ReprintLabelSuccess(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

final class ReprintLabelFailure extends ReprintLabelState {
  const ReprintLabelFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class ReprintLabelBloc extends Bloc<ReprintLabelEvent, ReprintLabelState> {
  ReprintLabelBloc(this._repository) : super(const ReprintLabelInitial()) {
    on<ReprintLabelsLoadRequested>(_load);
    on<ReprintLabelsRequested>(_reprint);
  }
  final GoodsReceiveRepository _repository;
  Future<void> _load(
    ReprintLabelsLoadRequested event,
    Emitter<ReprintLabelState> emit,
  ) async {
    emit(const ReprintLabelLoading());
    try {
      emit(
        ReprintLabelLoaded(
          await _repository.fetchLabels(
            lineId: event.lineId,
            searchText: event.searchText,
          ),
        ),
      );
    } catch (error) {
      emit(ReprintLabelFailure(error.toString()));
    }
  }

  Future<void> _reprint(
    ReprintLabelsRequested event,
    Emitter<ReprintLabelState> emit,
  ) async {
    if (event.labels.isEmpty) {
      emit(const ReprintLabelFailure('Please select at least one label'));
      return;
    }
    emit(const ReprintLabelLoading());
    try {
      emit(
        ReprintLabelSuccess(
          await _repository.reprintLabels(
            event.labels,
            printerIp: event.printerIp,
            printerToken: event.printerToken,
          ),
        ),
      );
    } catch (error) {
      emit(ReprintLabelFailure(error.toString()));
    }
  }
}
