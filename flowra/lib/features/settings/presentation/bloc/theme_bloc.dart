import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_event.dart';
import 'theme_state.dart';

/// Owns the app's light/dark preference and persists it across restarts via
/// [SharedPreferences]. The initial state is read synchronously from prefs (the
/// instance is already resolved during DI startup) so the app never flashes the
/// wrong theme on launch. Defaults to light when nothing has been saved yet.
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final SharedPreferences _prefs;

  static const String _prefsKey = 'theme_mode';

  ThemeBloc({required SharedPreferences prefs})
      : _prefs = prefs,
        super(ThemeState(_readInitial(prefs))) {
    on<ToggleThemeEvent>((event, emit) {
      final next = state.themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
      emit(ThemeState(next));
      _persist(next);
    });

    on<SetThemeEvent>((event, emit) {
      emit(ThemeState(event.themeMode));
      _persist(event.themeMode);
    });
  }

  static ThemeMode _readInitial(SharedPreferences prefs) {
    switch (prefs.getString(_prefsKey)) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.light;
    }
  }

  // Fire-and-forget cache write; the emitted state already drives the UI.
  void _persist(ThemeMode mode) {
    _prefs.setString(_prefsKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }
}
