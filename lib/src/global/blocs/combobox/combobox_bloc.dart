import 'package:bloc/bloc.dart';
import 'package:bs_mobile/src/global/blocs/combobox/models/combobox_api_model.dart';
import 'package:bs_mobile/src/global/blocs/combobox/repository/combobox_repository.dart';
import 'package:equatable/equatable.dart';

part 'combobox_event.dart';
part 'combobox_state.dart';

class ComboboxBloc extends Bloc<ComboboxEvent, ComboboxState> {
  ComboboxBloc({required ComboboxRepository comboboxRepository})
    : _comboboxRepository = comboboxRepository,
      super(const ComboboxInitial()) {
    on<FetchComboboxEvent>(_onFetch);
  }

  final ComboboxRepository _comboboxRepository;

  Future<void> _onFetch(
    FetchComboboxEvent event,
    Emitter<ComboboxState> emit,
  ) async {
    if (!event.forceRefresh && state is ComboboxLoaded) {
      return;
    }

    final previous = state.items;
    emit(ComboboxLoading(items: previous));

    final result = await _comboboxRepository.getCombobox(event.group_name);
    if (!result.isOk) {
      emit(
        ComboboxFailure(
          message: result.message ?? 'Failed to fetch warehouses',
          items: previous,
        ),
      );
      return;
    }

    final active =
        result.comboboxes.where((item) => item.isActive != false).toList()
          ..sort((a, b) {
            final sa = a.displaySequence ?? 0;
            final sb = b.displaySequence ?? 0;
            return sa.compareTo(sb);
          });

    emit(ComboboxLoaded(active));
  }
}
