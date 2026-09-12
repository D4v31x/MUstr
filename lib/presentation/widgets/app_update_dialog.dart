import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/app_update_service.dart';
import '../localization/app_strings.dart';

const _updateService = AppUpdateService();

Future<void> checkForAppUpdate(
  BuildContext context, {
  bool silentWhenCurrent = false,
  bool silentOnError = false,
}) async {
  try {
    final release = await _updateService.check();
    if (!context.mounted) return;
    if (release == null) {
      if (!silentWhenCurrent) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.strings.updateCurrent)));
      }
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AppUpdateDialog(release: release),
    );
  } catch (error) {
    if (!context.mounted || silentOnError) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${context.strings.updateFailed} $error')),
    );
  }
}

class _AppUpdateDialog extends StatefulWidget {
  const _AppUpdateDialog({required this.release});

  final AppRelease release;

  @override
  State<_AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<_AppUpdateDialog> {
  double? _progress;
  File? _apk;
  String? _error;
  bool _busy = false;

  Future<void> _download() async {
    setState(() {
      _busy = true;
      _error = null;
      _progress = 0;
    });
    try {
      final apk = await _updateService.download(
        widget.release,
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );
      if (!mounted) return;
      setState(() {
        _apk = apk;
        _busy = false;
        _progress = 1;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _install() async {
    final apk = _apk;
    if (apk == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _updateService.install(apk);
      if (!mounted) return;
      if (result == ApkInstallResult.permissionRequired) {
        setState(() {
          _busy = false;
          _error = context.strings.updatePermission;
        });
      } else {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final downloaded = _apk != null;
    return AlertDialog(
      icon: const Icon(Icons.system_update_alt_rounded),
      title: Text(strings.updateAvailable),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.updateVersion(widget.release.version)),
            if (widget.release.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(widget.release.notes.trim()),
            ],
            if (_progress case final progress?) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(value: progress == 0 ? null : progress),
              const SizedBox(height: 8),
              Text(
                downloaded
                    ? strings.updateReady
                    : '${strings.updateDownloading} ${(progress * 100).round()}%',
              ),
            ],
            if (_error case final error?) ...[
              const SizedBox(height: 16),
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(strings.updateLater),
        ),
        FilledButton.icon(
          onPressed: _busy
              ? null
              : downloaded
              ? _install
              : _download,
          icon: Icon(
            downloaded ? Icons.install_mobile_rounded : Icons.download_rounded,
          ),
          label: Text(downloaded ? strings.updateInstall : strings.updateNow),
        ),
      ],
    );
  }
}
