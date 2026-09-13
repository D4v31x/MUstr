import 'package:material_ui/material_ui.dart';

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
  ocean('ocean', Color(0xff0369a1)),
  emerald('emerald', Color(0xff047857)),
  lime('lime', Color(0xff4d7c0f)),
  amber('amber', Color(0xffb45309)),
  coral('coral', Color(0xffbe123c)),
  violet('violet', Color(0xff6d28d9)),
  rose('rose', Color(0xffbe185d));

  const AppColorTheme(this.code, this.seedColor);

  final String code;
  final Color? seedColor;

  static AppColorTheme fromCode(String? code) =>
      AppColorTheme.values.firstWhere(
        (theme) => theme.code == code,
        orElse: () => AppColorTheme.materialYou,
      );
}
