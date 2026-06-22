
//lib/core/cubits/theme_cubit/theme_cubit.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants.dart';
import '../../services/shared_preferences_singleton.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeInitial(_loadInitialThemeMode())) {
    // Keep `state.themeMode` in sync with whatever was persisted.
  }

  static ThemeMode _loadInitialThemeMode() {
    final saved = Prefs.getString(kThemeModeKey);
    switch (saved) {
      case "light":
        return ThemeMode.light;
      case "dark":
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  bool get isDark => state.themeMode == ThemeMode.dark;

  void toggleTheme() {
    final next = isDark ? ThemeMode.light : ThemeMode.dark;
    _emitAndPersist(next);
  }

  void setThemeMode(ThemeMode mode) => _emitAndPersist(mode);

  void _emitAndPersist(ThemeMode mode) {
    Prefs.setString(kThemeModeKey, mode.name);
    emit(ThemeChanged(mode));
  }
}
