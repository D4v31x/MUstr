import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/app_update_service.dart';
import '../localization/app_strings.dart';

const _updateService = AppUpdateService();

final appUpdateController = AppUpdateController();

enum AppUpdatePhase {
  idle,
  checking,
  available,
  downloading,
  downloaded,
  installing,
  current,
  error,
}

class AppUpdateController extends ChangeNotifier {
  AppUpdatePhase phase = AppUpdatePhase.idle;
  AppRelease? release;
  File? apk;
  double progress = 0;
  String? error;
  bool _initialized = false;
  Future<void>? _downloadOperation;
  Timer? _hideTimer;

  bool get visible => phase != AppUpdatePhase.idle;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final downloaded = await _updateService.restoreDownloaded();
    if (downloaded != null) {
      release = downloaded.release;
      apk = downloaded.apk;
      progress = 1;
      phase = AppUpdatePhase.downloaded;
      notifyListeners();
    }
  }

  Future<void> check({
    bool silentWhenCurrent = false,
    bool silentOnError = false,
  }) async {
    if (phase == AppUpdatePhase.downloading ||
        phase == AppUpdatePhase.installing) {
      return;
    }
    if (phase == AppUpdatePhase.downloaded) return;
    _hideTimer?.cancel();
    final fullySilent = silentWhenCurrent && silentOnError;
    if (!fullySilent) phase = AppUpdatePhase.checking;
    error = null;
    if (!fullySilent) notifyListeners();
    try {
      final available = await _updateService.check();
      if (available == null) {
        phase = silentWhenCurrent
            ? AppUpdatePhase.idle
            : AppUpdatePhase.current;
        notifyListeners();
        if (!silentWhenCurrent) _hideLater();
        return;
      }
      release = available;
      phase = AppUpdatePhase.available;
      notifyListeners();
    } catch (exception) {
      if (silentOnError) {
        phase = AppUpdatePhase.idle;
      } else {
        error = _errorCode(exception);
        phase = AppUpdatePhase.error;
      }
      notifyListeners();
    }
  }

  Future<void> download() {
    final existing = _downloadOperation;
    if (existing != null) return existing;
    final target = release;
    if (target == null) return Future.value();
    final operation = _download(target);
    _downloadOperation = operation;
    return operation.whenComplete(() => _downloadOperation = null);
  }

  Future<void> _download(AppRelease target) async {
    _hideTimer?.cancel();
    phase = AppUpdatePhase.downloading;
    progress = 0;
    error = null;
    notifyListeners();
    try {
      apk = await _updateService.download(
        target,
        onProgress: (value) {
          progress = value;
          notifyListeners();
        },
      );
      progress = 1;
      phase = AppUpdatePhase.downloaded;
      notifyListeners();
    } catch (exception) {
      error = _errorCode(exception);
      phase = AppUpdatePhase.error;
      notifyListeners();
    }
  }

  Future<void> install() async {
    final file = apk;
    if (file == null || !await file.exists()) {
      apk = null;
      phase = AppUpdatePhase.available;
      notifyListeners();
      return;
    }
    phase = AppUpdatePhase.installing;
    error = null;
    notifyListeners();
    try {
      final result = await _updateService.install(file);
      if (result == ApkInstallResult.permissionRequired) {
        error = 'permission_required';
      }
      // Keep the APK until a later launch confirms the new version installed.
      phase = AppUpdatePhase.downloaded;
      notifyListeners();
    } catch (exception) {
      error = _errorCode(exception);
      phase = AppUpdatePhase.error;
      notifyListeners();
    }
  }

  void dismiss() {
    if (phase == AppUpdatePhase.downloading ||
        phase == AppUpdatePhase.installing ||
        phase == AppUpdatePhase.downloaded) {
      return;
    }
    phase = AppUpdatePhase.idle;
    notifyListeners();
  }

  void _hideLater() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (phase == AppUpdatePhase.current) {
        phase = AppUpdatePhase.idle;
        notifyListeners();
      }
    });
  }
}

Future<void> checkForAppUpdate(
  BuildContext context, {
  bool silentWhenCurrent = false,
  bool silentOnError = false,
}) => appUpdateController.check(
  silentWhenCurrent: silentWhenCurrent,
  silentOnError: silentOnError,
);

class AppUpdateStatusBar extends StatelessWidget {
  const AppUpdateStatusBar({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: appUpdateController,
    builder: (context, _) {
      final controller = appUpdateController;
      if (!controller.visible) return const SizedBox.shrink();
      final strings = context.strings;
      final scheme = Theme.of(context).colorScheme;
      final release = controller.release;
      final phase = controller.phase;

      final (icon, label) = switch (phase) {
        AppUpdatePhase.checking => (
          Icons.sync_rounded,
          strings.checkingForUpdates,
        ),
        AppUpdatePhase.available => (
          Icons.system_update_alt_rounded,
          release == null
              ? strings.updateAvailable
              : strings.updateVersion(release.version),
        ),
        AppUpdatePhase.downloading => (
          Icons.download_rounded,
          '${strings.updateDownloading} ${(controller.progress * 100).round()}%',
        ),
        AppUpdatePhase.downloaded => (
          Icons.install_mobile_rounded,
          controller.error == 'permission_required'
              ? strings.updatePermission
              : strings.updateReady,
        ),
        AppUpdatePhase.installing => (
          Icons.install_mobile_rounded,
          strings.updateInstall,
        ),
        AppUpdatePhase.current => (
          Icons.check_circle_outline_rounded,
          strings.updateCurrent,
        ),
        AppUpdatePhase.error => (
          Icons.error_outline_rounded,
          _errorText(strings, controller.error),
        ),
        AppUpdatePhase.idle => (Icons.info_outline, ''),
      };

      final progress = phase == AppUpdatePhase.downloading
          ? controller.progress
          : null;
      final action = switch (phase) {
        AppUpdatePhase.available => TextButton(
          onPressed: controller.download,
          child: Text(strings.updateNow),
        ),
        AppUpdatePhase.downloaded => FilledButton.tonalIcon(
          onPressed: controller.install,
          icon: const Icon(Icons.install_mobile_rounded, size: 18),
          label: Text(strings.updateInstall),
        ),
        AppUpdatePhase.error => TextButton(
          onPressed: () => controller.check(),
          child: Text(strings.checkForUpdates),
        ),
        _ => null,
      };

      return Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        elevation: 6,
        shadowColor: scheme.shadow.withValues(alpha: 0.18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, color: scheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  ?action,
                  if (phase != AppUpdatePhase.downloading &&
                      phase != AppUpdatePhase.installing &&
                      phase != AppUpdatePhase.downloaded)
                    IconButton(
                      onPressed: controller.dismiss,
                      tooltip: strings.cancel,
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress == 0 ? null : progress,
                    minHeight: 4,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

String _errorCode(Object exception) => switch (exception) {
  AppUpdateException(kind: final kind) => kind.name,
  _ => AppUpdateErrorKind.unknown.name,
};

String _errorText(AppStrings strings, String? code) => switch (code) {
  'network' => strings.updateNetworkUnavailable,
  'server' => strings.updateServerUnavailable,
  'invalidRelease' => strings.updateInvalidRelease,
  'integrity' => strings.updateIntegrityFailed,
  _ => strings.updateFailed,
};

class AppUpdateHost extends StatelessWidget {
  const AppUpdateHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Overlay(
    initialEntries: [
      OverlayEntry(
        builder: (overlayContext) => Stack(
          children: [
            Positioned.fill(child: child),
            Positioned(
              left: 16,
              right: 16,
              bottom: 88,
              child: SafeArea(
                top: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: const AppUpdateStatusBar(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
