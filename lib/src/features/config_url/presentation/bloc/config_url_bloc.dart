import 'package:bs_mobile/src/features/config_url/repository/config_url_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'config_url_event.dart';
part 'config_url_state.dart';

class ConfigUrlBloc extends Bloc<ConfigUrlEvent, ConfigUrlState> {
  final ConfigUrlRepository _repository;

  ConfigUrlBloc(this._repository) : super(const ConfigUrlInitial()) {
    on<ConnectionTestRequested>(_onConnectionTest);
  }

  Future<void> _onConnectionTest(
    ConnectionTestRequested event,
    Emitter<ConfigUrlState> emit,
  ) async {
    emit(const ConfigUrlLoading());
    final success = await _repository.testConnection(event.url);
    if (success) {
      emit(const ConfigUrlSuccess('Connection Server Success'));
    } else {
      emit(const ConfigUrlFailure('Failed to Connection Server'));
    }
  }
}
