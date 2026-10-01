import 'package:bs_mobile/src/core/theme/app_color_palette.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Events ─────────────────────────────────────────────────────────────────

abstract class ThemeEvent {}

class ThemeToggled extends ThemeEvent {}

class ThemeLoaded extends ThemeEvent {}

class ThemePaletteChanged extends ThemeEvent {
  final AppColorPalette palette;
  ThemePaletteChanged(this.palette);
}

// ─── State ──────────────────────────────────────────────────────────────────

class ThemeState {
  final ThemeMode themeMode;
  final AppColorPalette palette;

  const ThemeState({
    this.themeMode = ThemeMode.light,
    this.palette = AppColorPaletteX.defaultPalette,
  });

  bool get isDark => themeMode == ThemeMode.dark;

  ThemeState copyWith({ThemeMode? themeMode, AppColorPalette? palette}) =>
      ThemeState(
        themeMode: themeMode ?? this.themeMode,
        palette: palette ?? this.palette,
      );
}

// ─── Bloc ───────────────────────────────────────────────────────────────────

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState()) {
    on<ThemeLoaded>(_onLoaded);
    on<ThemeToggled>(_onToggled);
    on<ThemePaletteChanged>(_onPaletteChanged);
  }

  Future<void> _onLoaded(ThemeLoaded event, Emitter<ThemeState> emit) async {
    final isDark = await AppStorage.getDarkMode();
    final palette = await AppStorage.getColorPalette();
    emit(
      state.copyWith(
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        palette: palette,
      ),
    );
  }

  Future<void> _onToggled(ThemeToggled event, Emitter<ThemeState> emit) async {
    final newMode = state.isDark ? ThemeMode.light : ThemeMode.dark;
    await AppStorage.setDarkMode(newMode == ThemeMode.dark);
    emit(state.copyWith(themeMode: newMode));
  }

  Future<void> _onPaletteChanged(
    ThemePaletteChanged event,
    Emitter<ThemeState> emit,
  ) async {
    await AppStorage.setColorPalette(event.palette);
    emit(state.copyWith(palette: event.palette));
  }
}
