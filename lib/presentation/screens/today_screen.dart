import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../data/repositories/planner_repository.dart';
import '../../domain/entities/exam.dart';
import '../../domain/entities/important_date.dart';
import '../../domain/entities/planner_task.dart';
import '../../domain/entities/timetable.dart';
import '../widgets/lesson_detail_sheet.dart';
import '../widgets/planner_formatters.dart';
import '../localization/app_strings.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, required this.data});

  final PlannerData data;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late final Timer _timer;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isSelectedToday = _sameDay(_selectedDay, now);
    final lessons = widget.data.timetable!.lessons
        .where((lesson) => _sameDay(lesson.date, _selectedDay))
        .where((lesson) => !isSelectedToday || lesson.endTime.isAfter(now))
        .toList();
    final active = lessons
        .where(
          (lesson) =>
              !now.isBefore(lesson.startTime) && now.isBefore(lesson.endTime),
        )
        .firstOrNull;
    final next = lessons
        .where((lesson) => lesson.startTime.isAfter(now))
        .firstOrNull;
    final importantDates = widget.data.importantDates
        .where((importantDate) => _sameDay(importantDate.date, _selectedDay))
        .toList();
    final exams = widget.data.exams
        .where((exam) => _sameDay(exam.scheduledAt, _selectedDay))
        .toList();
    final timelineItems = <_TodayTimelineItem>[
      for (final lesson in lessons) _TodayTimelineItem.lesson(lesson),
      for (final exam in exams) _TodayTimelineItem.exam(exam),
      for (final importantDate in importantDates)
        _TodayTimelineItem.importantDate(importantDate),
    ]..sort((first, second) => first.start.compareTo(second.start));
    final upcomingTasks = widget.data.tasks
        .where((task) => !task.isCompleted)
        .take(3)
        .toList();
    final strings = context.strings;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSelectedToday ? strings.today.toUpperCase() : 'SCHEDULE',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayLabel(context, _selectedDay),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: _pickDay,
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          strings.classesToday(lessons.length),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        _FocusCard(
          lesson: active ?? next,
          style: widget.data.lessonStyle,
          isActive: active != null,
          now: now,
        ),
        const SizedBox(height: 32),
        _SectionHeader(title: strings.timeline, icon: Icons.schedule_outlined),
        const SizedBox(height: 12),
        if (timelineItems.isEmpty)
          const _EmptyDay()
        else
          ...timelineItems.map((item) {
            if (item.lesson != null) {
              return _LessonTile(
                lesson: item.lesson!,
                style: widget.data.lessonStyle,
                isActive: item.lesson == active,
                showRoom: widget.data.showRoomInSchedule,
              );
            }
            if (item.exam != null) {
              return _ExamScheduleTile(
                exam: item.exam!,
                style: widget.data.lessonStyle,
              );
            }
            return _ImportantDateScheduleTile(
              importantDate: item.importantDate!,
              style: widget.data.lessonStyle,
            );
          }),
        const SizedBox(height: 28),
        _SectionHeader(title: strings.dueSoon, icon: Icons.assignment_outlined),
        const SizedBox(height: 12),
        if (upcomingTasks.isEmpty) Text(strings.nothingUrgent),
        ...upcomingTasks.map(
          (task) => _TaskTile(task: task, subjects: widget.data.subjects),
        ),
      ],
    );
  }

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  Future<void> _pickDay() async {
    final timetable = widget.data.timetable!;
    final firstDate = timetable.firstDate!;
    final lastDate = timetable.lastDate!;
    final initialDate = _selectedDay.isBefore(firstDate)
        ? firstDate
        : _selectedDay.isAfter(lastDate)
        ? lastDate
        : _selectedDay;
    final day = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (day != null) setState(() => _selectedDay = day);
  }
}

class _TodayTimelineItem {
  _TodayTimelineItem.lesson(Lesson lesson)
    : lesson = lesson,
      exam = null,
      importantDate = null,
      start = lesson.startTime;

  _TodayTimelineItem.exam(Exam exam)
    : lesson = null,
      exam = exam,
      importantDate = null,
      start = exam.scheduledAt;

  _TodayTimelineItem.importantDate(ImportantDate importantDate)
    : lesson = null,
      exam = null,
      importantDate = importantDate,
      start = importantDate.scheduledAt;

  final Lesson? lesson;
  final Exam? exam;
  final ImportantDate? importantDate;
  final DateTime start;
}

class _ExamScheduleTile extends StatelessWidget {
  const _ExamScheduleTile({required this.exam, required this.style});

  final Exam exam;
  final LessonStyleSettings style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = Color(style.examColorValue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              timeLabel(exam.scheduledAt),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Container(
            width: 4,
            height: 64,
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
                  context.strings.exam.toUpperCase(),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: color),
                ),
                Text(
                  exam.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (exam.location.isNotEmpty)
                  Text(
                    exam.location,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.school_outlined, color: color),
        ],
      ),
    );
  }
}

class _ImportantDateScheduleTile extends StatelessWidget {
  const _ImportantDateScheduleTile({
    required this.importantDate,
    required this.style,
  });

  final ImportantDate importantDate;
  final LessonStyleSettings style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = Color(style.importantDateColorValue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              importantDate.timeMinute == null
                  ? context.strings.allDay
                  : timeLabel(importantDate.scheduledAt),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Container(
            width: 4,
            height: 64,
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
                  context.strings.importantDate.toUpperCase(),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: color),
                ),
                Text(
                  importantDate.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (importantDate.reminderAt != null)
                  Text(
                    context.strings.reminderSet,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.bookmark_outline_rounded, color: color),
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.lesson,
    required this.style,
    required this.isActive,
    required this.now,
  });

  final Lesson? lesson;
  final LessonStyleSettings style;
  final bool isActive;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (lesson == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.wb_sunny_outlined, color: scheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  context.strings.noMoreClasses,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final lessonAccent = lessonColor(scheme, lesson!, style);
    final cardColor = scheme.primaryContainer;
    final foregroundColor = scheme.onPrimaryContainer;
    final codeColor = readableAccentColor(
      lessonAccent,
      cardColor,
      fallback: foregroundColor,
    );
    final remaining = isActive
        ? lesson!.endTime.difference(now)
        : lesson!.startTime.difference(now);
    final label = isActive
        ? context.strings.inProgress
        : context.strings.upNext;
    return Card(
      color: cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => showLessonDetails(context, lesson!, style: style),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: foregroundColor,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: lessonAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foregroundColor.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                timetableCodeLabel(lesson!),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: codeColor),
              ),
              Text(
                lesson!.courseName,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: foregroundColor),
              ),
              const SizedBox(height: 20),
              Text(
                isActive
                    ? context.strings.endsIn(_duration(remaining))
                    : context.strings.startsIn(_duration(remaining)),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: foregroundColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _duration(Duration value) => value.inHours > 0
      ? '${value.inHours}h ${value.inMinutes.remainder(60)}m'
      : '${value.inMinutes}m';
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.style,
    required this.isActive,
    required this.showRoom,
  });

  final Lesson lesson;
  final LessonStyleSettings style;
  final bool isActive;
  final bool showRoom;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = lessonColor(scheme, lesson, style);
    final codeColor = readableAccentColor(
      color,
      scheme.surface,
      fallback: scheme.onSurface,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => showLessonDetails(context, lesson, style: style),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 52,
              child: Text(
                timeLabel(lesson.startTime),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Container(
              width: 4,
              height: 84,
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
                    timetableCodeLabel(lesson),
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: codeColor),
                  ),
                  Text(
                    lesson.courseName,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _kindLabel(context, lesson),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    [
                      '${timeLabel(lesson.startTime)} - ${timeLabel(lesson.endTime)}',
                      if (showRoom && lesson.rooms.isNotEmpty)
                        lesson.rooms.first.name,
                    ].join('  |  '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isActive) _ActiveLessonMarker(color: color),
          ],
        ),
      ),
    );
  }

  String _kindLabel(BuildContext context, Lesson lesson) =>
      switch (lesson.kind) {
        LessonKind.seminar => context.strings.seminarDetails(
          lesson.seminarGroup,
        ),
        LessonKind.lecture => context.strings.lecture,
        LessonKind.event => context.strings.event,
      };
}

class _ActiveLessonMarker extends StatefulWidget {
  const _ActiveLessonMarker({required this.color});

  final Color color;

  @override
  State<_ActiveLessonMarker> createState() => _ActiveLessonMarkerState();
}

class _ActiveLessonMarkerState extends State<_ActiveLessonMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 32,
    height: 84,
    child: Semantics(
      label: context.strings.inProgress,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = Curves.easeInOut.transform(_controller.value);
          final height = 4 + 80 * (1 - (2 * progress - 1).abs());
          final alignment = progress <= 0.5
              ? Alignment.topCenter
              : Alignment.bottomCenter;
          return Align(
            alignment: alignment,
            child: Container(
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.subjects});

  final PlannerTask task;
  final List<Subject> subjects;

  @override
  Widget build(BuildContext context) {
    final subject = task.subjectId == null
        ? null
        : subjects.where((item) => item.id == task.subjectId).firstOrNull;
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.radio_button_unchecked,
          color: priorityColor(Theme.of(context).colorScheme, task.priority),
        ),
        title: Text(task.title),
        subtitle: Text(
          '${subject?.courseCode ?? 'Unassigned'}  |  ${dueLabel(context, task)}',
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        context.strings.noClassesToday,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}
