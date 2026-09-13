import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/timetable.dart';
import 'planner_formatters.dart';
import 'faculty_badge.dart';
import 'change_confirmation_dialog.dart';
import '../localization/app_strings.dart';
import '../providers/planner_providers.dart';

Future<void> showLessonDetails(
  BuildContext context,
  Lesson lesson, {
  required LessonStyleSettings style,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.85,
  ),
  builder: (_) => _LessonDetails(lesson: lesson, style: style),
);

class _LessonDetails extends ConsumerStatefulWidget {
  const _LessonDetails({required this.lesson, required this.style});

  final Lesson lesson;
  final LessonStyleSettings style;

  @override
  ConsumerState<_LessonDetails> createState() => _LessonDetailsState();
}

class _LessonDetailsState extends ConsumerState<_LessonDetails> {
  static const _colors = <int>[
    0xff2563eb,
    0xff0f766e,
    0xffc2410c,
    0xffbe123c,
    0xff7e22ce,
    0xff475569,
  ];
  late LessonPriority _priority = widget.lesson.priority;
  late int? _customColorValue = widget.lesson.customColorValue;
  late DateTime? _reminderAt = widget.lesson.reminderAt;

  Lesson get _editedLesson => widget.lesson.copyWithPresentation(
    priority: _priority,
    customColorValue: _customColorValue,
    clearCustomColor: _customColorValue == null,
    reminderAt: _reminderAt,
    clearReminder: _reminderAt == null,
  );

  String _priorityLabel(AppStrings strings, LessonPriority value) =>
      switch (value) {
        LessonPriority.low => strings.low,
        LessonPriority.normal => strings.normal,
        LessonPriority.high => strings.high,
      };

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final color = lessonColor(
      Theme.of(context).colorScheme,
      _editedLesson,
      widget.style,
    );
    final strings = context.strings;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.courseCode,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: color),
              ),
              const SizedBox(height: 4),
              Text(
                lesson.courseName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _AttendanceBadge(lesson: lesson, color: color),
              const SizedBox(height: 24),
              _DetailRow(
                icon: Icons.schedule_outlined,
                value:
                    '${dayLabel(context, lesson.date)}\n${timeLabel(lesson.startTime)} - ${timeLabel(lesson.endTime)}',
              ),
              if (lesson.rooms.isNotEmpty)
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  value: lesson.rooms.map((room) => room.name).join(', '),
                ),
              if (lesson.teachers.isNotEmpty)
                _DetailRow(
                  icon: Icons.person_outline,
                  value: lesson.teachers
                      .map((teacher) => teacher.name)
                      .join(', '),
                ),
              if (lesson.faculty != null)
                _FacultyDetailRow(facultyId: lesson.faculty!),
              const Divider(height: 32),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.notifications_outlined),
                title: Text(strings.classReminder),
                subtitle: Text(
                  _reminderAt == null
                      ? strings.noReminder
                      : '${dayLabel(context, _reminderAt!)} ${timeLabel(_reminderAt!)}',
                ),
                value: _reminderAt != null,
                onChanged: (enabled) => setState(() {
                  _reminderAt = enabled
                      ? lesson.startTime.subtract(const Duration(minutes: 15))
                      : null;
                }),
              ),
              if (_reminderAt != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _pickReminder,
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text(strings.changeReminderTime),
                  ),
                ),
              const Divider(height: 32),
              Text(
                strings.personalPriority,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SegmentedButton<LessonPriority>(
                segments: LessonPriority.values
                    .map(
                      (value) => ButtonSegment(
                        value: value,
                        label: Text(_priorityLabel(strings, value)),
                      ),
                    )
                    .toList(),
                selected: {_priority},
                onSelectionChanged: (values) =>
                    setState(() => _priority = values.single),
              ),
              const SizedBox(height: 24),
              Text(
                strings.classColor,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors
                    .map(
                      (value) => _ColorChoice(
                        colorValue: value,
                        selected: _customColorValue == value,
                        onTap: () => setState(() => _customColorValue = value),
                      ),
                    )
                    .toList(),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _customColorValue = null),
                  icon: const Icon(Icons.restart_alt),
                  label: Text(strings.useTypeColor),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    if (!await confirmEdit(context)) return;
                    await ref
                        .read(plannerProvider.notifier)
                        .saveLessonPresentation(_editedLesson);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: Text(strings.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickReminder() async {
    final current = _reminderAt!;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time != null) {
      setState(() {
        _reminderAt = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      });
    }
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.colorValue,
    required this.selected,
    required this.onTap,
  });

  final int colorValue;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(24),
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Color(colorValue),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.onSurface
              : Colors.transparent,
          width: 3,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, color: Colors.white, size: 18)
          : null,
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    ),
  );
}

class _AttendanceBadge extends StatelessWidget {
  const _AttendanceBadge({required this.lesson, required this.color});

  final Lesson lesson;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final label = switch (lesson.kind) {
      LessonKind.seminar => strings.seminarDetails(lesson.seminarGroup),
      LessonKind.lecture => strings.lecture,
      LessonKind.event => strings.event,
    };
    return Chip(
      avatar: Icon(
        lesson.kind == LessonKind.seminar
            ? Icons.groups_outlined
            : Icons.auto_stories_outlined,
        size: 18,
      ),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.16),
      side: BorderSide.none,
    );
  }
}

class _FacultyDetailRow extends StatelessWidget {
  const _FacultyDetailRow({required this.facultyId});

  final String facultyId;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      children: [
        Icon(
          Icons.account_balance_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 16),
        FacultyBadge(facultyId: facultyId),
      ],
    ),
  );
}
