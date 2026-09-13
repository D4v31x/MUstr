import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import 'domain/entities/app_language.dart';
import 'domain/entities/app_theme_mode.dart';
import 'presentation/providers/planner_providers.dart';
import 'presentation/screens/planner_shell.dart';
import 'presentation/widgets/app_update_dialog.dart';
import 'services/analytics_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
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
    return _MaterialYouSeedBuilder(
      builder: (materialYouSeed) {
        final lightScheme = _schemeFor(
          brightness: Brightness.light,
          colorTheme: colorTheme,
          materialYouSeed: materialYouSeed,
        );
        final darkScheme = _schemeFor(
          brightness: Brightness.dark,
          colorTheme: colorTheme,
          materialYouSeed: materialYouSeed,
        );
        final brightness = switch (themeMode) {
          ThemeMode.light => Brightness.light,
          ThemeMode.dark => Brightness.dark,
          _ => MediaQuery.platformBrightnessOf(context),
        };
        final expressiveSeed = _seedFor(colorTheme, materialYouSeed);
        return M3ETheme(
          data: themeMode == ThemeMode.system
              ? M3EThemeData.light(seedColor: expressiveSeed)
              : brightness == Brightness.dark
              ? M3EThemeData.dark(seedColor: expressiveSeed)
              : M3EThemeData.light(seedColor: expressiveSeed),
          initialTheme: brightness,
          autoTheming: themeMode == ThemeMode.system,
          child: MaterialApp(
            title: 'MUstr',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            locale: language.locale,
            supportedLocales: AppLanguage.values.map(
              (language) => language.locale,
            ),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => AppUpdateHost(child: child!),
            theme: _theme(Brightness.light, lightScheme),
            darkTheme: _theme(Brightness.dark, darkScheme),
            home: const PlannerShell(),
          ),
        );
      },
    );
  }

  ColorScheme _schemeFor({
    required Brightness brightness,
    required AppColorTheme colorTheme,
    required Color? materialYouSeed,
  }) {
    return ColorScheme.fromSeed(
      seedColor: _seedFor(colorTheme, materialYouSeed),
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
  }

  Color _seedFor(AppColorTheme colorTheme, Color? materialYouSeed) =>
      colorTheme == AppColorTheme.materialYou
      ? materialYouSeed ?? const Color(0xff005ca9)
      : colorTheme.seedColor!;

  ThemeData _theme(Brightness brightness, ColorScheme scheme) {
    final baseText = GoogleFonts.figtreeTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: baseText.copyWith(
        displaySmall: baseText.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        headlineMedium: baseText.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        headlineSmall: baseText.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        labelLarge: baseText.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        shadowColor: scheme.primary.withValues(alpha: 0.10),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => baseText.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}

class _MaterialYouSeedBuilder extends StatefulWidget {
  const _MaterialYouSeedBuilder({required this.builder});

  final Widget Function(Color? materialYouSeed) builder;

  @override
  State<_MaterialYouSeedBuilder> createState() =>
      _MaterialYouSeedBuilderState();
}

class _MaterialYouSeedBuilderState extends State<_MaterialYouSeedBuilder>
    with WidgetsBindingObserver {
  Color? _seed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSeed();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadSeed();
  }

  Future<void> _loadSeed() async {
    try {
      final palette = await DynamicColorPlugin.getCorePalette();
      if (palette == null || !mounted) return;
      setState(() => _seed = Color(palette.primary.get(40)));
    } on PlatformException {
      // Material You is unavailable on this platform or Android version.
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(_seed);
}
