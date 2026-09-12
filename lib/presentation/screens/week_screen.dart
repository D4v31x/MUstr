import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/planner_repository.dart';
import '../../domain/entities/exam.dart';
import '../../domain/entities/timetable.dart';
import '../widgets/lesson_detail_sheet.dart';
import '../widgets/planner_formatters.dart';
import '../localization/app_strings.dart';

const _examDuration = Duration(hours: 2);

class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key, required this.data});

  final PlannerData data;

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  static const _originPage = 1000;
  late final PageController _pageController;
  late DateTime _week;

  @override
  void initState() {
    super.initState();
    _week = mondayFor(DateTime.now());
    _pageController = PageController(initialPage: _originPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              IconButton.filledTonal(
                tooltip: strings.previousWeek,
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.weekOverview,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${compactDate(context, _week)} - ${compactDate(context, _week.add(const Duration(days: 6)))}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: strings.jumpToWeek,
                onPressed: _pickWeek,
                icon: const Icon(Icons.calendar_month_outlined),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: strings.nextWeek,
                onPressed: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) => setState(
              () => _week = mondayFor(
                DateTime.now(),
              ).add(Duration(days: (page - _originPage) * 7)),
            ),
            itemBuilder: (context, page) => WeekBoard(
              data: widget.data,
              week: mondayFor(
                DateTime.now(),
              ).add(Duration(days: (page - _originPage) * 7)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickWeek() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _week,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selectedDate == null || !mounted) {
      return;
    }
    final selectedWeek = mondayFor(selectedDate);
    final currentWeek = mondayFor(DateTime.now());
    final targetPage =
        _originPage + selectedWeek.difference(currentWeek).inDays ~/ 7;
    await _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }
}

class WeekBoard extends StatefulWidget {
  const WeekBoard({super.key, required this.data, required this.week});

  final PlannerData data;
  final DateTime week;

  @override
  State<WeekBoard> createState() => _WeekBoardState();
}

class _WeekBoardState extends State<WeekBoard> {
  late final Timer _clock;
  final _hController = ScrollController();
  final _vController = ScrollController();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clock.cancel();
    _hController.dispose();
    _vController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = widget.week.add(const Duration(days: 6));
    final lessons = widget.data.timetable!.lessons
        .where(
          (lesson) =>
              !lesson.date.isBefore(widget.week) &&
              lesson.date.isBefore(widget.week.add(const Duration(days: 7))),
        )
        .toList();
    final exams = widget.data.exams
        .where(
          (exam) =>
              !exam.scheduledAt.isBefore(widget.week) &&
              exam.scheduledAt.isBefore(
                widget.week.add(const Duration(days: 7)),
              ),
        )
        .toList();
    final activeExamPeriods = widget.data.examPeriods
        .where(
          (period) =>
              !period.endDate.isBefore(widget.week) &&
              !period.startDate.isAfter(weekEnd),
        )
        .toList();
    final items = [
      for (final lesson in lessons) _WeekItem.forLesson(lesson),
      for (final exam in exams) _WeekItem.forExam(exam),
    ];
    final earliest = items.isEmpty
        ? 420
        : (items
                      .map((item) => item.start.hour * 60 + item.start.minute)
                      .reduce((a, b) => a < b ? a : b) ~/
                  60) *
              60;
    final latest = items.isEmpty
        ? 1200
        : ((items
                          .map((item) => item.end.hour * 60 + item.end.minute)
                          .reduce((a, b) => a > b ? a : b) +
                      59) ~/
                  60) *
              60;
    final startMinute = earliest < 420 ? earliest : 420;
    final endMinute = latest > 1200 ? latest : 1200;
    const scale = 1.05;
    const rail = 68.0;
    const dayHeight = 92.0;
    const header = 48.0;
    final gridWidth = (endMinute - startMinute) * scale;
    final gridHeight = dayHeight * 7;
    final scheme = Theme.of(context).colorScheme;
    final todayIndex = widget.data.highlightCurrentDay
        ? List<int>.generate(7, (day) => day).firstWhere(
            (day) =>
                _sameDay(widget.week.add(Duration(days: day)), DateTime.now()),
            orElse: () => -1,
          )
        : -1;
    return Column(
      children: [
        if (activeExamPeriods.isNotEmpty)
          _ExamPeriodBanner(periods: activeExamPeriods),
        Expanded(
          child: Column(
            children: [
              // Hour row stays visible and pans in sync with horizontal scroll.
              SizedBox(
                height: header,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: rail),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _hController,
                        builder: (context, child) => OverflowBox(
                          alignment: Alignment.topLeft,
                          minWidth: 0,
                          maxWidth: double.infinity,
                          child: Transform.translate(
                            offset: Offset(
                              -(_hController.hasClients
                                  ? _hController.offset
                                  : 0.0),
                              0,
                            ),
                            child: child,
                          ),
                        ),
                        child: SizedBox(
                          width: gridWidth,
                          height: header,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (
                                var minute = startMinute;
                                minute <= endMinute;
                                minute += 60
                              )
                                Positioned(
                                  left: (minute - startMinute) * scale - 24,
                                  top: 0,
                                  width: 48,
                                  height: header,
                                  child: Text(
                                    '${(minute ~/ 60).toString().padLeft(2, '0')}:00',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    // Day column stays visible and pans in sync with vertical scroll.
                    SizedBox(
                      width: rail,
                      child: ClipRect(
                        child: AnimatedBuilder(
                          animation: _vController,
                          builder: (context, child) => OverflowBox(
                            alignment: Alignment.topLeft,
                            minHeight: 0,
                            maxHeight: double.infinity,
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                -(_vController.hasClients
                                    ? _vController.offset
                                    : 0.0),
                              ),
                              child: child,
                            ),
                          ),
                          child: SizedBox(
                            width: rail,
                            height: gridHeight,
                            child: Stack(
                              children: [
                                if (todayIndex >= 0)
                                  Positioned(
                                    left: 0,
                                    top: todayIndex * dayHeight,
                                    width: rail,
                                    height: dayHeight,
                                    child: Container(
                                      color: scheme.primary.withValues(
                                        alpha: 0.06,
                                      ),
                                    ),
                                  ),
                                for (var day = 0; day < 7; day++)
                                  _dayLabel(
                                    context,
                                    day,
                                    day * dayHeight,
                                    dayHeight,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        controller: _vController,
                        child: SingleChildScrollView(
                          controller: _vController,
                          child: SingleChildScrollView(
                            controller: _hController,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: gridWidth,
                              height: gridHeight,
                              child: Stack(
                                children: [
                                  if (todayIndex >= 0)
                                    Positioned(
                                      left: 0,
                                      top: todayIndex * dayHeight,
                                      width: gridWidth,
                                      height: dayHeight,
                                      child: Container(
                                        color: scheme.primary.withValues(
                                          alpha: 0.06,
                                        ),
                                      ),
                                    ),
                                  for (
                                    var minute = startMinute;
                                    minute <= endMinute;
                                    minute += 60
                                  )
                                    Positioned(
                                      left: (minute - startMinute) * scale,
                                      top: 0,
                                      height: gridHeight,
                                      child: Container(
                                        width: 1,
                                        color: scheme.outlineVariant,
                                      ),
                                    ),
                                  for (var day = 0; day <= 7; day++)
                                    Positioned(
                                      left: 0,
                                      top: day * dayHeight,
                                      width: gridWidth,
                                      child: Divider(
                                        height: 1,
                                        color: scheme.outlineVariant,
                                      ),
                                    ),
                                  ...items.map(
                                    (item) => _positionedItem(
                                      context,
                                      item,
                                      items,
                                      startMinute,
                                      scale,
                                      dayHeight,
                                    ),
                                  ),
                                  _nowLine(
                                    startMinute,
                                    endMinute,
                                    scale,
                                    gridHeight,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dayLabel(BuildContext context, int day, double top, double height) {
    final date = widget.week.add(Duration(days: day));
    final isToday = _sameDay(date, DateTime.now());
    return Positioned(
      left: 0,
      top: top,
      width: 60,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            shortWeekday(context, date),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '${date.day}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isToday ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _positionedItem(
    BuildContext context,
    _WeekItem item,
    List<_WeekItem> all,
    int startMinute,
    double scale,
    double dayHeight,
  ) {
    final sameDay =
        all.where((other) => _sameDay(other.start, item.start)).toList()
          ..sort((first, second) => first.start.compareTo(second.start));
    final conflicts = sameDay
        .where(
          (other) =>
              other.start.isBefore(item.end) && item.start.isBefore(other.end),
        )
        .toList();
    final index = conflicts.indexOf(item);
    final minute = item.start.hour * 60 + item.start.minute;
    final duration = item.end.difference(item.start).inMinutes;
    final itemHeight = (dayHeight - 8) / conflicts.length;
    final scheme = Theme.of(context).colorScheme;
    final fillColor = item.isExam
        ? scheme.error
        : lessonColor(scheme, item.lesson!, widget.data.lessonStyle);
    final foregroundColor = readableTextColor(fillColor);
    return Positioned(
      left: (minute - startMinute) * scale + 2,
      top: (item.start.weekday - 1) * dayHeight + 4 + index * itemHeight,
      width: (duration * scale - 4).clamp(34, double.infinity),
      height: itemHeight - 4,
      child: Material(
        color: fillColor,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => item.isExam
              ? _showExamDetails(context, item.exam!)
              : showLessonDetails(
                  context,
                  item.lesson!,
                  style: widget.data.lessonStyle,
                ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showCode = constraints.maxHeight >= 34;
              final showRoom =
                  widget.data.showRoomInSchedule && constraints.maxHeight >= 60;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: DefaultTextStyle(
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: foregroundColor,
                    height: 1,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.isExam
                            ? context.strings.exam
                            : item.lesson!.courseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: foregroundColor,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                      ),
                      if (showCode)
                        Text(
                          item.isExam
                              ? item.exam!.title
                              : timetableCodeLabel(item.lesson!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (showRoom && item.location.isNotEmpty)
                        Text(
                          item.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showExamDetails(
    BuildContext context,
    Exam exam,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.strings.exam,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 4),
            Text(exam.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            _ExamDetailRow(
              icon: Icons.schedule_outlined,
              value:
                  '${dayLabel(context, exam.scheduledAt)}\n${timeLabel(exam.scheduledAt)}',
            ),
            if (exam.location.isNotEmpty)
              _ExamDetailRow(
                icon: Icons.location_on_outlined,
                value: exam.location,
              ),
            if (exam.notes.isNotEmpty)
              _ExamDetailRow(icon: Icons.notes_outlined, value: exam.notes),
          ],
        ),
      ),
    ),
  );

  Widget _nowLine(int start, int end, double scale, double gridHeight) {
    final now = DateTime.now();
    if (now.isBefore(widget.week) ||
        !now.isBefore(widget.week.add(const Duration(days: 7)))) {
      return const SizedBox();
    }
    final minute = now.hour * 60 + now.minute;
    if (minute < start || minute > end) {
      return const SizedBox();
    }
    return Positioned(
      left: (minute - start) * scale,
      top: 0,
      height: gridHeight,
      child: Container(width: 2, color: Theme.of(context).colorScheme.error),
    );
  }

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

class _WeekItem {
  _WeekItem.forLesson(Lesson value)
    : lesson = value,
      exam = null,
      start = value.startTime,
      end = value.endTime;

  _WeekItem.forExam(Exam value)
    : lesson = null,
      exam = value,
      start = value.scheduledAt,
      end = value.scheduledAt.add(_examDuration);

  final Lesson? lesson;
  final Exam? exam;
  final DateTime start;
  final DateTime end;

  bool get isExam => exam != null;
  String get location => isExam
      ? exam!.location
      : lesson!.rooms.isEmpty
      ? ''
      : lesson!.rooms.first.name;
}

class _ExamPeriodBanner extends StatelessWidget {
  const _ExamPeriodBanner({required this.periods});

  final List<ExamPeriod> periods;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.event_available_outlined,
              color: scheme.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.strings.examPeriod,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    periods
                        .map(
                          (period) =>
                              '${compactDate(context, period.startDate)} - ${compactDate(context, period.endDate)}',
                        )
                        .join('\n'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamDetailRow extends StatelessWidget {
  const _ExamDetailRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.error),
        const SizedBox(width: 16),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    ),
  );
}
