import 'package:flutter/material.dart';

enum AppThemeMode {
  system('system'),
  light('light'),
  dark('dark');

  const AppThemeMode(this.code);

  final String code;

  ThemeMode get themeMode => switch (this) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  static AppThemeMode fromCode(String? code) => AppThemeMode.values.firstWhere(
    (mode) => mode.code == code,
    orElse: () => AppThemeMode.system,
  );
}
