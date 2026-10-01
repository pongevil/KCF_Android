import 'package:bs_mobile/src/core/localization/locale_repository.dart';
import 'package:bs_mobile/src/core/localization/locale_service.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Events ─────────────────────────────────────────────────────────────────

abstract class LocaleEvent {}

class LoadLocaleEvent extends LocaleEvent {}

class LoadLocaleFromCacheEvent extends LocaleEvent {}

// ─── State ──────────────────────────────────────────────────────────────────

abstract class LocaleState {}

class LocaleInitial extends LocaleState {}

class LocaleLoading extends LocaleState {}

class LocaleLoaded extends LocaleState {
  final String localeId;

  LocaleLoaded({required this.localeId});
}

class LocaleFailure extends LocaleState {
  final String message;

  LocaleFailure(this.message);
}

// ─── Bloc ───────────────────────────────────────────────────────────────────

class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  final LocaleRepository _repository;

  LocaleBloc(this._repository) : super(LocaleInitial()) {
    on<LoadLocaleEvent>(_onLoadLocale);
    on<LoadLocaleFromCacheEvent>(_onLoadFromCache);
  }

  Future<void> _ensureFallback() async {
    if (LocaleService.instance.isLoaded) return;
    final fallback = await _repository.loadFallbackMessages();
    LocaleService.instance.setFallback(fallback);
  }

  Future<void> _onLoadLocale(
    LoadLocaleEvent event,
    Emitter<LocaleState> emit,
  ) async {
    emit(LocaleLoading());
    try {
      await _ensureFallback();
      final remote = await _repository.fetchAndCache();
      LocaleService.instance.apply(remote);
      final localeId = await AppStorage.getLocaleId();
      emit(LocaleLoaded(localeId: localeId));
    } catch (e) {
      emit(LocaleFailure(e.toString()));
    }
  }

  Future<void> _onLoadFromCache(
    LoadLocaleFromCacheEvent event,
    Emitter<LocaleState> emit,
  ) async {
    try {
      await _ensureFallback();
      final cached = await _repository.readCache();
      if (cached != null) {
        LocaleService.instance.apply(cached);
      }
      final localeId = await AppStorage.getLocaleId();
      emit(LocaleLoaded(localeId: localeId));
    } catch (e) {
      emit(LocaleFailure(e.toString()));
    }
  }
}
