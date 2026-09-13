import 'package:flutter/material.dart';
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
          if (currentData.subjects.isNotEmpty)
            _ColorCategoryTile(
              icon: Icons.menu_book_outlined,
              title: strings.subjectColors,
              colors: currentData.subjects
                  .map(
                    (subject) =>
                        style.colorForSubject(subject.id) ??
                        eventColor(
                          Theme.of(context).colorScheme,
                          subject.faculty,
                          subject.id,
                        ).toARGB32(),
                  )
                  .toList(),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _SubjectColorsScreen(data: currentData),
                ),
              ),
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
            child: Column(
              children: [
                _ScheduleEntryPreview(
                  color: Color(style.lectureColorValue),
                  label: strings.lecture,
                  title: 'PB151',
                ),
                const SizedBox(height: 12),
                _ScheduleEntryPreview(
                  color: Color(style.seminarColorValue),
                  label: strings.seminar,
                  title: 'PB151 / 02',
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

class _SubjectColorsScreen extends ConsumerWidget {
  const _SubjectColorsScreen({required this.data});

  final PlannerData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentData = _plannerData(ref, data);
    final style = currentData.lessonStyle;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.strings.subjectColors)),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemCount: currentData.subjects.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final subject = currentData.subjects[index];
          final color = Color(
            style.colorForSubject(subject.id) ??
                eventColor(scheme, subject.faculty, subject.id).toARGB32(),
          );
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                width: 16,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              title: Text(subject.courseCode),
              subtitle: Text(
                subject.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _ColorEditor(
                    data: currentData,
                    target: _ColorTarget.subject,
                    subject: subject,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _ColorTarget { exam, importantDate, examPeriod, subject }

class _ColorEditor extends ConsumerWidget {
  const _ColorEditor({required this.data, required this.target, this.subject});

  final PlannerData data;
  final _ColorTarget target;
  final Subject? subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentData = _plannerData(ref, data);
    final style = currentData.lessonStyle;
    final strings = context.strings;
    final title = switch (target) {
      _ColorTarget.exam => strings.exam,
      _ColorTarget.importantDate => strings.importantDate,
      _ColorTarget.examPeriod => strings.examPeriod,
      _ColorTarget.subject => subject!.courseCode,
    };
    final selected = switch (target) {
      _ColorTarget.exam => style.examColorValue,
      _ColorTarget.importantDate => style.importantDateColorValue,
      _ColorTarget.examPeriod => style.examPeriodColorValue,
      _ColorTarget.subject =>
        style.colorForSubject(subject!.id) ??
            eventColor(
              Theme.of(context).colorScheme,
              subject!.faculty,
              subject!.id,
            ).toARGB32(),
    };
    final hasOverride =
        target == _ColorTarget.subject &&
        style.colorForSubject(subject!.id) != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (hasOverride)
            IconButton(
              tooltip: strings.useAutomaticColor,
              icon: const Icon(Icons.restart_alt),
              onPressed: () {
                final colors = Map<String, int>.from(style.subjectColorValues)
                  ..remove(subject!.id);
                ref
                    .read(plannerProvider.notifier)
                    .saveLessonStyle(
                      style.copyWith(subjectColorValues: colors),
                    );
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _PreviewSection(
            child: target == _ColorTarget.examPeriod
                ? _ExamPeriodPreview(color: Color(selected), title: title)
                : _ScheduleEntryPreview(
                    color: Color(selected),
                    label: title,
                    title: target == _ColorTarget.subject
                        ? subject!.courseCode
                        : title,
                    subtitle: target == _ColorTarget.subject
                        ? subject!.name
                        : null,
                  ),
          ),
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
      _ColorTarget.subject => style.copyWith(
        subjectColorValues: Map<String, int>.from(style.subjectColorValues)
          ..[subject!.id] = color,
      ),
    };
    ref.read(plannerProvider.notifier).saveLessonStyle(updated);
  }
}

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
    ),
    child: child,
  );
}

class _ScheduleEntryPreview extends StatelessWidget {
  const _ScheduleEntryPreview({
    required this.color,
    required this.label,
    required this.title,
    this.subtitle,
  });

  final Color color;
  final String label;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 52,
        child: Text('09:00', style: Theme.of(context).textTheme.labelLarge),
      ),
      Container(
        width: 4,
        height: 68,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: readableAccentColor(
                  color,
                  Theme.of(context).colorScheme.surfaceContainerLow,
                  fallback: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    ],
  );
}

class _ExamPeriodPreview extends StatelessWidget {
  const _ExamPeriodPreview({required this.color, required this.title});

  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Icons.event_available_outlined, color: color),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(
              '14 Dec - 29 Jan',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ],
  );
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
