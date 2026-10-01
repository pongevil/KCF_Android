import 'package:bs_mobile/src/core/app_config/app_config_repository.dart';
import 'package:bs_mobile/src/core/app_config/app_config_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AppConfigEvent {}

class LoadAppConfigEvent extends AppConfigEvent {}

class LoadAppConfigFromCacheEvent extends AppConfigEvent {}

abstract class AppConfigState {}

class AppConfigInitial extends AppConfigState {}

class AppConfigLoading extends AppConfigState {}

class AppConfigLoaded extends AppConfigState {}

class AppConfigFailure extends AppConfigState {
  final String message;

  AppConfigFailure(this.message);
}

class AppConfigBloc extends Bloc<AppConfigEvent, AppConfigState> {
  final AppConfigRepository _repository;

  AppConfigBloc(this._repository) : super(AppConfigInitial()) {
    on<LoadAppConfigEvent>(_onLoad);
    on<LoadAppConfigFromCacheEvent>(_onLoadFromCache);
  }

  Future<void> _onLoad(
    LoadAppConfigEvent event,
    Emitter<AppConfigState> emit,
  ) async {
    emit(AppConfigLoading());
    try {
      final config = await _repository.fetchAndCache();
      AppConfigService.instance.applyQuantity(config.quantity);
      emit(AppConfigLoaded());
    } catch (e) {
      emit(AppConfigFailure(e.toString()));
    }
  }

  Future<void> _onLoadFromCache(
    LoadAppConfigFromCacheEvent event,
    Emitter<AppConfigState> emit,
  ) async {
    try {
      final cached = await _repository.readCache();
      if (cached != null) {
        AppConfigService.instance.applyQuantity(cached.quantity);
      }
      emit(AppConfigLoaded());
    } catch (e) {
      emit(AppConfigFailure(e.toString()));
    }
  }
}
