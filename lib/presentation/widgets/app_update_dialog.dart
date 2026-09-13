import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';

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
}

Future<void> checkForAppUpdate({
  bool silentWhenCurrent = false,
  bool silentOnError = false,
}) => appUpdateController.check(
  silentWhenCurrent: silentWhenCurrent,
  silentOnError: silentOnError,
);

String _errorCode(Object exception) => switch (exception) {
  AppUpdateException(kind: final kind) => kind.name,
  _ => AppUpdateErrorKind.unknown.name,
};

String appUpdateErrorText(AppStrings strings, String? code) => switch (code) {
  'network' => strings.updateNetworkUnavailable,
  'server' => strings.updateServerUnavailable,
  'invalidRelease' => strings.updateInvalidRelease,
  'integrity' => strings.updateIntegrityFailed,
  _ => strings.updateFailed,
};
