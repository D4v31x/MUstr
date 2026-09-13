import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/planner_repository.dart';
import '../../domain/entities/timetable.dart';
import '../localization/app_strings.dart';
import '../providers/planner_providers.dart';
import '../widgets/planner_formatters.dart';

const _colorChoices = <int>[
  0xff2563eb,
  0xff0369a1,
  0xff0e7490,
  0xff0f766e,
  0xff047857,
  0xff4d7c0f,
  0xffb45309,
  0xffd04a02,
  0xffbe123c,
  0xff9f1239,
  0xffbe185d,
  0xffa21caf,
  0xff7e22ce,
  0xff4f46e5,
  0xff475569,
  0xff374151,
];

class ScheduleColorsScreen extends ConsumerWidget {
  const ScheduleColorsScreen({super.key, required this.data});

  final PlannerData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentData = _plannerData(ref, data);
    final strings = context.strings;
    final style = currentData.lessonStyle;
    return Scaffold(
      appBar: AppBar(title: Text(strings.changeColors)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            strings.classAppearanceSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _ColorCategoryTile(
            icon: Icons.auto_stories_outlined,
            title: strings.classColors,
            colors: [style.lectureColorValue, style.seminarColorValue],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _ClassColorsEditor(data: currentData),
              ),
            ),
          ),
          _ColorCategoryTile(
            icon: Icons.school_outlined,
            title: strings.exam,
            colors: [style.examColorValue],
            onTap: () => _openEditor(context, currentData, _ColorTarget.exam),
          ),
          _ColorCategoryTile(
            icon: Icons.bookmark_outline_rounded,
            title: strings.importantDate,
            colors: [style.importantDateColorValue],
            onTap: () =>
                _openEditor(context, currentData, _ColorTarget.importantDate),
          ),
          _ColorCategoryTile(
            icon: Icons.date_range_outlined,
            title: strings.examPeriod,
            colors: [style.examPeriodColorValue],
            onTap: () =>
                _openEditor(context, currentData, _ColorTarget.examPeriod),
          ),
        ],
      ),
    );
  }

  void _openEditor(
    BuildContext context,
    PlannerData data,
    _ColorTarget target,
  ) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _ColorEditor(data: data, target: target),
    ),
  );
}

class _ColorCategoryTile extends StatelessWidget {
  const _ColorCategoryTile({
    required this.icon,
    required this.title,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final List<int> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...colors
                .take(4)
                .map(
                  (value) => Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: Color(value),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    ),
  );
}

class _ClassColorsEditor extends ConsumerWidget {
  const _ClassColorsEditor({required this.data});

  final PlannerData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentData = _plannerData(ref, data);
    final style = currentData.lessonStyle;
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(title: Text(strings.classColors)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _PreviewSection(
            child: _WeekBoardPreview(
              entries: [
                _WeekPreviewEntry(
                  color: Color(style.lectureColorValue),
                  title: 'Computer systems',
                  detail: 'PB151',
                  startFraction: 0.12,
                ),
                _WeekPreviewEntry(
                  color: Color(style.seminarColorValue),
                  title: 'Computer systems',
                  detail: 'PB151 / 02',
                  startFraction: 0.5,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _ColorPicker(
            label: strings.lecture,
            selected: style.lectureColorValue,
            onSelected: (color) => ref
                .read(plannerProvider.notifier)
                .saveLessonStyle(style.copyWith(lectureColorValue: color)),
          ),
          const SizedBox(height: 28),
          _ColorPicker(
            label: strings.seminar,
            selected: style.seminarColorValue,
            onSelected: (color) => ref
                .read(plannerProvider.notifier)
                .saveLessonStyle(style.copyWith(seminarColorValue: color)),
          ),
        ],
      ),
    );
  }
}

enum _ColorTarget { exam, importantDate, examPeriod }

class _ColorEditor extends ConsumerWidget {
  const _ColorEditor({required this.data, required this.target});

  final PlannerData data;
  final _ColorTarget target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentData = _plannerData(ref, data);
    final style = currentData.lessonStyle;
    final strings = context.strings;
    final title = switch (target) {
      _ColorTarget.exam => strings.exam,
      _ColorTarget.importantDate => strings.importantDate,
      _ColorTarget.examPeriod => strings.examPeriod,
    };
    final selected = switch (target) {
      _ColorTarget.exam => style.examColorValue,
      _ColorTarget.importantDate => style.importantDateColorValue,
      _ColorTarget.examPeriod => style.examPeriodColorValue,
    };
    final preview = switch (target) {
      _ColorTarget.exam => _WeekPreviewEntry(
        color: Color(selected),
        title: strings.exam,
        detail: 'Programming final',
        startFraction: 0.25,
      ),
      _ColorTarget.importantDate => _WeekPreviewEntry(
        color: Color(selected),
        title: strings.importantDate,
        detail: 'Course registration',
        startFraction: 0.25,
      ),
      _ColorTarget.examPeriod => _WeekPreviewEntry(
        color: Color(selected),
        title: strings.examPeriod,
        detail: '14 Dec - 29 Jan',
        startFraction: 0.25,
      ),
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _PreviewSection(child: _WeekBoardPreview(entries: [preview])),
          const SizedBox(height: 28),
          _ColorPicker(
            label: strings.classColor,
            selected: selected,
            onSelected: (color) => _saveColor(ref, style, color),
          ),
        ],
      ),
    );
  }

  void _saveColor(WidgetRef ref, LessonStyleSettings style, int color) {
    final updated = switch (target) {
      _ColorTarget.exam => style.copyWith(examColorValue: color),
      _ColorTarget.importantDate => style.copyWith(
        importantDateColorValue: color,
      ),
      _ColorTarget.examPeriod => style.copyWith(examPeriodColorValue: color),
    };
    ref.read(plannerProvider.notifier).saveLessonStyle(updated);
  }
}

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: child,
  );
}

class _WeekBoardPreview extends StatelessWidget {
  const _WeekBoardPreview({required this.entries});

  final List<_WeekPreviewEntry> entries;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 126,
      child: Column(
        children: [
          SizedBox(
            height: 30,
            child: Row(
              children: [
                const SizedBox(width: 52),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['08:00', '09:00', '10:00']
                        .map(
                          (time) => Text(
                            time,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'MON',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text('14', style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => Stack(
                      children: [
                        for (var column = 0; column < 4; column++)
                          Positioned(
                            left: constraints.maxWidth * column / 3,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 1,
                              color: scheme.outlineVariant,
                            ),
                          ),
                        for (final entry in entries)
                          Positioned(
                            left:
                                constraints.maxWidth * entry.startFraction + 2,
                            top: 12,
                            width: (constraints.maxWidth * 0.38).clamp(
                              68,
                              constraints.maxWidth - 4,
                            ),
                            height: 34,
                            child: Material(
                              color: entry.color,
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                child: DefaultTextStyle(
                                  style: Theme.of(context).textTheme.labelSmall!
                                      .copyWith(
                                        color: readableTextColor(entry.color),
                                        height: 1,
                                      ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: readableTextColor(
                                                entry.color,
                                              ),
                                              fontWeight: FontWeight.w800,
                                              height: 1,
                                            ),
                                      ),
                                      Text(
                                        entry.detail,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekPreviewEntry {
  const _WeekPreviewEntry({
    required this.color,
    required this.title,
    required this.detail,
    required this.startFraction,
  });

  final Color color;
  final String title;
  final String detail;
  final double startFraction;
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _colorChoices
            .map(
              (color) => _ColorSwatch(
                colorValue: color,
                selected: color == selected,
                label: label,
                onTap: () => onSelected(color),
              ),
            )
            .toList(),
      ),
    ],
  );
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.colorValue,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final int colorValue;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: Tooltip(
      message: label,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(colorValue),
              shape: BoxShape.circle,
            ),
            child: selected
                ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                : null,
          ),
        ),
      ),
    ),
  );
}

PlannerData _plannerData(WidgetRef ref, PlannerData fallback) =>
    switch (ref.watch(plannerProvider)) {
      AsyncData(:final value) => value,
      _ => fallback,
    };
