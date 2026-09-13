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

enum AppColorTheme {
  materialYou('material_you', null),
  muniBlue('muni_blue', Color(0xff005ca9)),
  emerald('emerald', Color(0xff047857)),
  coral('coral', Color(0xffbe123c));

  const AppColorTheme(this.code, this.seedColor);

  final String code;
  final Color? seedColor;

  static AppColorTheme fromCode(String? code) =>
      AppColorTheme.values.firstWhere(
        (theme) => theme.code == code,
        orElse: () => AppColorTheme.materialYou,
      );
}
