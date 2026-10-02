import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/webcal_timetable_service.dart';
import '../localization/app_strings.dart';

class WebcalImportProgressDialog extends StatelessWidget {
  const WebcalImportProgressDialog({super.key, required this.progress});

  final ValueListenable<WebcalImportProgress> progress;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        icon: const Icon(Icons.sync_rounded),
        title: Text(strings.importingCalendar),
        content: ValueListenableBuilder<WebcalImportProgress>(
          valueListenable: progress,
          builder: (context, value, _) {
            final current = value.stage.index;
            final details = {
              WebcalImportStage.downloading: _bytesLabel(value),
              WebcalImportStage.reading: value.eventCount == null
                  ? null
                  : strings.calendarEvents(value.eventCount!),
              WebcalImportStage.saving: null,
            };
            final labels = {
              WebcalImportStage.downloading: strings.importStepDownload,
              WebcalImportStage.reading: strings.importStepRead,
              WebcalImportStage.saving: strings.importStepSave,
            };
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(end: _fraction(value)),
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  builder: (context, fraction, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: fraction),
                  ),
                ),
                const SizedBox(height: 20),
                for (final stage in WebcalImportStage.values)
                  _StepRow(
                    label: labels[stage]!,
                    detail: stage.index == current ? details[stage] : null,
                    state: stage.index < current
                        ? _StepState.done
                        : stage.index == current
                        ? _StepState.active
                        : _StepState.pending,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String? _bytesLabel(WebcalImportProgress value) {
    final received = value.receivedBytes;
    if (received == null) {
      return null;
    }
    final kb = (received / 1024).ceil();
    final total = value.totalBytes;
    return total == null ? '$kb KB' : '$kb / ${(total / 1024).ceil()} KB';
  }

  static double _fraction(WebcalImportProgress value) => switch (value.stage) {
    WebcalImportStage.downloading =>
      0.05 +
          0.4 *
              ((value.totalBytes == null || value.receivedBytes == null)
                  ? 0.3
                  : (value.receivedBytes! / value.totalBytes!).clamp(0.0, 1.0)),
    WebcalImportStage.reading => value.eventCount == null ? 0.55 : 0.7,
    WebcalImportStage.saving => 0.9,
  };
}

enum _StepState { done, active, pending }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.state, this.detail});

  final String label;
  final String? detail;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = state == _StepState.pending
        ? scheme.onSurfaceVariant.withValues(alpha: 0.6)
        : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: switch (state) {
              _StepState.done => Icon(
                Icons.check_circle_rounded,
                size: 22,
                color: scheme.primary,
              ),
              _StepState.active => const Padding(
                padding: EdgeInsets.all(2),
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              _StepState.pending => Icon(
                Icons.radio_button_unchecked_rounded,
                size: 22,
                color: color,
              ),
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              detail == null ? label : '$label · $detail',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: state == _StepState.active
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
