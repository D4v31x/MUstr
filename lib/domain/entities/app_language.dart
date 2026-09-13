import 'package:material_ui/material_ui.dart';

enum AppLanguage {
  english('en', 'English'),
  czech('cs', 'Čeština'),
  slovak('sk', 'Slovenčina');

  const AppLanguage(this.code, this.label);

  final String code;
  final String label;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) => AppLanguage.values.firstWhere(
    (language) => language.code == code,
    orElse: () => AppLanguage.english,
  );
}
