import 'dart:async';

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../localization/app_strings.dart';
import '../widgets/app_update_dialog.dart';

class UpdateCheckScreen extends StatefulWidget {
  const UpdateCheckScreen({super.key, this.autoStart = true});

  final bool autoStart;

  @override
  State<UpdateCheckScreen> createState() => _UpdateCheckScreenState();
}

class _UpdateCheckScreenState extends State<UpdateCheckScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.autoStart) unawaited(appUpdateController.check());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _UpdateGridPainter(
                  lineColor: scheme.outlineVariant.withValues(alpha: 0.28),
                  accentColor: scheme.primary.withValues(alpha: 0.09),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: AnimatedBuilder(
                    animation: appUpdateController,
                    builder: (context, _) =>
                        _UpdateContent(controller: appUpdateController),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateContent extends StatelessWidget {
  const _UpdateContent({required this.controller});

  final AppUpdateController controller;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final scheme = Theme.of(context).colorScheme;
    final phase = controller.phase;
    final (icon, label) = switch (phase) {
      AppUpdatePhase.checking => (
        Icons.sync_rounded,
        strings.checkingForUpdates,
      ),
      AppUpdatePhase.available => (
        Icons.system_update_alt_rounded,
        controller.release == null
            ? strings.updateAvailable
            : strings.updateVersion(controller.release!.version),
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
        appUpdateErrorText(strings, controller.error),
      ),
      AppUpdatePhase.idle => (
        Icons.system_update_alt_rounded,
        strings.checkForUpdates,
      ),
    };
    final action = switch (phase) {
      AppUpdatePhase.available => FilledButton.icon(
        onPressed: controller.download,
        icon: const Icon(Icons.download_rounded),
        label: Text(strings.updateNow),
      ),
      AppUpdatePhase.downloaded => FilledButton.icon(
        onPressed: controller.install,
        icon: const Icon(Icons.install_mobile_rounded),
        label: Text(strings.updateInstall),
      ),
      AppUpdatePhase.current || AppUpdatePhase.error => OutlinedButton.icon(
        onPressed: () => controller.check(),
        icon: const Icon(Icons.refresh_rounded),
        label: Text(strings.checkForUpdates),
      ),
      _ => null,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'MUstr',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontFamily: 'MuniBold',
            color: scheme.primary,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 40),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: Column(
            key: ValueKey(phase),
            mainAxisSize: MainAxisSize.min,
            children: [
              if (phase == AppUpdatePhase.checking ||
                  phase == AppUpdatePhase.downloading ||
                  phase == AppUpdatePhase.installing)
                const M3ELoadingIndicator(
                  variant: M3ELoadingIndicatorVariant.contained,
                  semanticLabel: 'Checking for updates',
                )
              else
                Icon(icon, size: 52, color: scheme.primary),
              const SizedBox(height: 20),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (phase == AppUpdatePhase.downloading) ...[
                const SizedBox(height: 20),
                M3EProgressIndicator.linearWavy(
                  value: controller.progress == 0 ? null : controller.progress,
                  linearSize: M3EProgressIndicatorSize.s,
                ),
              ],
              if (action != null) ...[const SizedBox(height: 28), action],
            ],
          ),
        ),
      ],
    );
  }
}

class _UpdateGridPainter extends CustomPainter {
  const _UpdateGridPainter({
    required this.lineColor,
    required this.accentColor,
  });

  final Color lineColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final accentPaint = Paint()..color = accentColor;
    const cellWidth = 56.0;
    const cellHeight = 48.0;
    for (var x = 0.0; x <= size.width; x += cellWidth) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (var y = 0.0; y <= size.height; y += cellHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    for (var row = 2; row < (size.height / cellHeight).floor(); row += 4) {
      canvas.drawRect(
        Rect.fromLTWH(
          cellWidth,
          row * cellHeight + 6,
          cellWidth * 4,
          cellHeight - 12,
        ),
        accentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_UpdateGridPainter oldDelegate) =>
      lineColor != oldDelegate.lineColor ||
      accentColor != oldDelegate.accentColor;
}
