import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_ui/material_ui.dart';

import 'domain/entities/app_language.dart';
import 'domain/entities/app_theme_mode.dart';
import 'presentation/providers/planner_providers.dart';
import 'presentation/screens/planner_shell.dart';
import 'presentation/widgets/app_update_dialog.dart';
import 'services/analytics_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await analyticsService.initialize();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Figtree'], license);
  });
  await appUpdateController.initialize();
  runApp(const ProviderScope(child: MuniPlannerApp()));
}

class MuniPlannerApp extends ConsumerWidget {
  const MuniPlannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planner = ref.watch(plannerProvider);
    final language = switch (planner) {
      AsyncData(:final value) => value.language,
      _ => AppLanguage.english,
    };
    final themeMode = switch (planner) {
      AsyncData(:final value) => value.themeMode.themeMode,
      _ => ThemeMode.system,
    };
    final colorTheme = switch (planner) {
      AsyncData(:final value) => value.colorTheme,
      _ => AppColorTheme.materialYou,
    };
    final seedColor = colorTheme.seedColor ?? const Color(0xff005ca9);
    final fallbackLight = ColorScheme.fromSeed(seedColor: seedColor);
    final fallbackDark = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    final useMaterialYou = colorTheme == AppColorTheme.materialYou;

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final lightScheme = useMaterialYou
            ? lightDynamic ?? fallbackLight
            : fallbackLight;
        final darkScheme = useMaterialYou
            ? darkDynamic ?? fallbackDark
            : fallbackDark;
        return MaterialApp(
          theme: ThemeData(
            colorScheme: lightScheme,
            fontFamily: 'Figtree',
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkScheme,
            fontFamily: 'Figtree',
            useMaterial3: true,
          ),
          themeMode: themeMode,
          title: 'MUstr',
          debugShowCheckedModeBanner: false,
          themeAnimationDuration: const Duration(milliseconds: 280),
          themeAnimationCurve: Curves.easeInOutCubic,
          locale: language.locale,
          supportedLocales: AppLanguage.values.map(
            (language) => language.locale,
          ),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const PlannerShell(),
        );
      },
    );
  }
}
