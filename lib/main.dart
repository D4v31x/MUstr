import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_ui/material_ui.dart';

import 'domain/entities/app_language.dart';
import 'domain/entities/app_theme_mode.dart';
import 'presentation/localization/app_strings.dart';
import 'presentation/providers/planner_providers.dart';
import 'presentation/screens/planner_shell.dart';
import 'presentation/screens/update_check_screen.dart';
import 'presentation/widgets/app_update_dialog.dart';
import 'services/analytics_service.dart';

final _navigatorKey = GlobalKey<NavigatorState>();
final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
          navigatorKey: _navigatorKey,
          scaffoldMessengerKey: _scaffoldMessengerKey,
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
          builder: (context, child) => _UpdateLaunchNotifier(
            navigatorKey: _navigatorKey,
            scaffoldMessengerKey: _scaffoldMessengerKey,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class _UpdateLaunchNotifier extends StatefulWidget {
  const _UpdateLaunchNotifier({
    required this.navigatorKey,
    required this.scaffoldMessengerKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Widget child;

  @override
  State<_UpdateLaunchNotifier> createState() => _UpdateLaunchNotifierState();
}

class _UpdateLaunchNotifierState extends State<_UpdateLaunchNotifier> {
  String? _announcedVersion;

  @override
  void initState() {
    super.initState();
    appUpdateController.addListener(_onUpdateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          checkForAppUpdate(silentWhenCurrent: true, silentOnError: true),
        );
      }
    });
  }

  @override
  void dispose() {
    appUpdateController.removeListener(_onUpdateChanged);
    super.dispose();
  }

  void _onUpdateChanged() {
    final release = appUpdateController.release;
    if (!mounted ||
        appUpdateController.phase != AppUpdatePhase.available ||
        release == null ||
        release.version == _announcedVersion) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          appUpdateController.phase != AppUpdatePhase.available ||
          release.version == _announcedVersion) {
        return;
      }
      final messenger = widget.scaffoldMessengerKey.currentState;
      if (messenger == null) {
        return;
      }
      _announcedVersion = release.version;
      final strings = context.strings;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 12),
            content: Text(strings.updateVersion(release.version)),
            action: SnackBarAction(
              label: strings.open,
              onPressed: () {
                widget.navigatorKey.currentState?.push(
                  MaterialPageRoute<void>(
                    builder: (_) => const UpdateCheckScreen(autoStart: false),
                  ),
                );
              },
            ),
          ),
        );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
