import 'package:flutter/material.dart';

sealed class ThemeState {
  const ThemeState(this.themeMode);
  final ThemeMode themeMode;
}

final class ThemeInitial extends ThemeState {
  const ThemeInitial(super.themeMode);
}

final class ThemeChanged extends ThemeState {
  const ThemeChanged(super.themeMode);
}
