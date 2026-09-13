import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../data/repositories/planner_repository.dart';
import '../../domain/entities/exam.dart';
import '../../domain/entities/important_date.dart';
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
                      '${compactDate(context, _week)} - ${compactDate(context, addCalendarDays(_week, 6))}',
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
                addCalendarDays(DateTime.now(), (page - _originPage) * 7),
              ),
            ),
            itemBuilder: (context, page) => WeekBoard(
              data: widget.data,
              week: mondayFor(
                addCalendarDays(DateTime.now(), (page - _originPage) * 7),
              ),
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
        _originPage + calendarDayDifference(currentWeek, selectedWeek) ~/ 7;
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
  var _didSetInitialTimeOffset = false;

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
    final weekEnd = addCalendarDays(widget.week, 6);
    final lessons = widget.data.timetable!.lessons
        .where(
          (lesson) =>
              !lesson.date.isBefore(widget.week) &&
              lesson.date.isBefore(addCalendarDays(widget.week, 7)),
        )
        .toList();
    final exams = widget.data.exams
        .where(
          (exam) =>
              !exam.scheduledAt.isBefore(widget.week) &&
              exam.scheduledAt.isBefore(addCalendarDays(widget.week, 7)),
        )
        .toList();
    final importantDates = widget.data.importantDates
        .where(
          (importantDate) =>
              !importantDate.date.isBefore(widget.week) &&
              importantDate.date.isBefore(addCalendarDays(widget.week, 7)),
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
      for (final importantDate in importantDates)
        _WeekItem.forImportantDate(importantDate),
    ];
    final crowdedGroups = _overlapGroups(
      items,
    ).where((group) => group.length >= 3).toList();
    final crowdedItems = crowdedGroups.expand((group) => group).toSet();
    final individualItems = items
        .where((item) => !crowdedItems.contains(item))
        .toList();
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
    const hourLabelHalfWidth = 24.0;
    final gridWidth = (endMinute - startMinute) * scale + hourLabelHalfWidth;
    final gridHeight = dayHeight * 7;
    final scheme = Theme.of(context).colorScheme;
    final todayIndex = widget.data.highlightCurrentDay
        ? List<int>.generate(7, (day) => day).firstWhere(
            (day) =>
                _sameDay(addCalendarDays(widget.week, day), DateTime.now()),
            orElse: () => -1,
          )
        : -1;
    _focusCurrentTime(
      startMinute: startMinute,
      endMinute: endMinute,
      scale: scale,
    );
    return Column(
      children: [
        if (activeExamPeriods.isNotEmpty)
          _ExamPeriodBanner(
            periods: activeExamPeriods,
            colorValue: widget.data.lessonStyle.examPeriodColorValue,
          ),
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
                                  ...individualItems.map(
                                    (item) => _positionedItem(
                                      context,
                                      item,
                                      individualItems,
                                      startMinute,
                                      scale,
                                      dayHeight,
                                    ),
                                  ),
                                  ...crowdedGroups.map(
                                    (group) => _positionedEventStack(
                                      context,
                                      group,
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

  List<List<_WeekItem>> _overlapGroups(List<_WeekItem> items) {
    final groups = <List<_WeekItem>>[];
    for (var day = 0; day < 7; day++) {
      final dayItems =
          items
              .where(
                (item) => calendarDayDifference(widget.week, item.start) == day,
              )
              .toList()
            ..sort((first, second) => first.start.compareTo(second.start));
      var group = <_WeekItem>[];
      DateTime? groupEnd;
      for (final item in dayItems) {
        if (groupEnd != null && !item.start.isBefore(groupEnd)) {
          groups.add(group);
          group = <_WeekItem>[];
          groupEnd = null;
        }
        group.add(item);
        if (groupEnd == null || item.end.isAfter(groupEnd)) {
          groupEnd = item.end;
        }
      }
      if (group.isNotEmpty) groups.add(group);
    }
    return groups;
  }

  void _focusCurrentTime({
    required int startMinute,
    required int endMinute,
    required double scale,
  }) {
    final currentWeekDay = calendarDayDifference(widget.week, DateTime.now());
    if (_didSetInitialTimeOffset || currentWeekDay < 0 || currentWeekDay > 6) {
      return;
    }
    _didSetInitialTimeOffset = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_hController.hasClients) return;
      final now = DateTime.now();
      final minute = now.hour * 60 + now.minute;
      final clampedMinute = minute.clamp(startMinute, endMinute).toDouble();
      final target =
          (clampedMinute - startMinute) * scale -
          _hController.position.viewportDimension * 0.35;
      _hController.jumpTo(
        target.clamp(0.0, _hController.position.maxScrollExtent),
      );
    });
  }

  Widget _dayLabel(BuildContext context, int day, double top, double height) {
    final date = addCalendarDays(widget.week, day);
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
    final itemSlotHeight = (dayHeight - 8) / conflicts.length;
    final itemHeight = (itemSlotHeight - 4)
        .clamp(2, double.infinity)
        .toDouble();
    final scheme = Theme.of(context).colorScheme;
    final fillColor = switch (item) {
      _WeekItem(exam: != null) => Color(widget.data.lessonStyle.examColorValue),
      _WeekItem(importantDate: != null) => Color(
        widget.data.lessonStyle.importantDateColorValue,
      ),
      _ => lessonColor(scheme, item.lesson!, widget.data.lessonStyle),
    };
    final foregroundColor = readableTextColor(fillColor);
    return Positioned(
      left: (minute - startMinute) * scale + 2,
      top:
          calendarDayDifference(widget.week, item.start) * dayHeight +
          4 +
          index * itemSlotHeight,
      width: (duration * scale - 4).clamp(34, double.infinity),
      height: itemHeight,
      child: Material(
        color: fillColor,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: item.isExam
              ? () => _showExamDetails(context, item.exam!)
              : item.isImportantDate
              ? null
              : () => showLessonDetails(
                  context,
                  item.lesson!,
                  style: widget.data.lessonStyle,
                ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showTitle = constraints.maxHeight >= 22;
              final showCode = constraints.maxHeight >= 40;
              final showRoom =
                  widget.data.showRoomInSchedule && constraints.maxHeight >= 58;
              final title = item.isExam
                  ? context.strings.exam
                  : item.isImportantDate
                  ? context.strings.importantDate
                  : item.lesson!.courseName;
              final detail = item.isExam
                  ? item.exam!.title
                  : item.isImportantDate
                  ? item.importantDate!.title
                  : timetableCodeLabel(item.lesson!);
              if (!showTitle) {
                return Semantics(
                  label: '$title: $detail',
                  child: Tooltip(
                    message: '$title: $detail',
                    child: const SizedBox.expand(),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: DefaultTextStyle(
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: foregroundColor,
                    height: 1,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
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
                          detail,
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

  Widget _positionedEventStack(
    BuildContext context,
    List<_WeekItem> items,
    int startMinute,
    double scale,
    double dayHeight,
  ) {
    final start = items
        .map((item) => item.start)
        .reduce((first, second) => first.isBefore(second) ? first : second);
    final end = items
        .map((item) => item.end)
        .reduce((first, second) => first.isAfter(second) ? first : second);
    final minute = start.hour * 60 + start.minute;
    final duration = end.difference(start).inMinutes;
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      left: (minute - startMinute) * scale + 2,
      top: calendarDayDifference(widget.week, start) * dayHeight + 4,
      width: (duration * scale - 4).clamp(72, double.infinity),
      height: dayHeight - 8,
      child: Material(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => _showEventStack(context, items),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Icon(Icons.layers_outlined, color: scheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${items.length} ${context.strings.scheduledEvents}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEventStack(
    BuildContext context,
    List<_WeekItem> items,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.65,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${items.length} ${context.strings.scheduledEvents}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final title = item.isExam
                        ? item.exam!.title
                        : item.isImportantDate
                        ? item.importantDate!.title
                        : item.lesson!.courseName;
                    final type = item.isExam
                        ? context.strings.exam
                        : item.isImportantDate
                        ? context.strings.importantDate
                        : timetableCodeLabel(item.lesson!);
                    final time =
                        item.isImportantDate &&
                            item.importantDate!.timeMinute == null
                        ? context.strings.allDay
                        : '${timeLabel(item.start)} - ${timeLabel(item.end)}';
                    return ListTile(
                      leading: Icon(
                        item.isExam
                            ? Icons.school_outlined
                            : item.isImportantDate
                            ? Icons.bookmark_outline_rounded
                            : Icons.event_note_outlined,
                      ),
                      title: Text(title),
                      subtitle: Text('$type | $time'),
                      onTap: item.isExam
                          ? () {
                              Navigator.of(context).pop();
                              _showExamDetails(context, item.exam!);
                            }
                          : item.isImportantDate
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              showLessonDetails(
                                context,
                                item.lesson!,
                                style: widget.data.lessonStyle,
                              );
                            },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

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
                color: Color(widget.data.lessonStyle.examColorValue),
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
        !now.isBefore(addCalendarDays(widget.week, 7))) {
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
      importantDate = null,
      start = value.startTime,
      end = value.endTime;

  _WeekItem.forExam(Exam value)
    : lesson = null,
      exam = value,
      importantDate = null,
      start = value.scheduledAt,
      end = value.scheduledAt.add(_examDuration);

  _WeekItem.forImportantDate(ImportantDate value)
    : lesson = null,
      exam = null,
      importantDate = value,
      start = value.timeMinute == null
          ? DateTime(value.date.year, value.date.month, value.date.day, 6)
          : value.scheduledAt,
      end = value.timeMinute == null
          ? DateTime(value.date.year, value.date.month, value.date.day, 7)
          : value.scheduledAt.add(const Duration(hours: 1));

  final Lesson? lesson;
  final Exam? exam;
  final ImportantDate? importantDate;
  final DateTime start;
  final DateTime end;

  bool get isExam => exam != null;
  bool get isImportantDate => importantDate != null;
  String get location => isExam
      ? exam!.location
      : lesson!.rooms.isEmpty
      ? ''
      : lesson!.rooms.first.name;
}

class _ExamPeriodBanner extends StatelessWidget {
  const _ExamPeriodBanner({required this.periods, required this.colorValue});

  final List<ExamPeriod> periods;
  final int colorValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = Color(colorValue);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.event_available_outlined, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.strings.examPeriod,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    periods
                        .map(
                          (period) =>
                              '${compactDate(context, period.startDate)} - ${compactDate(context, period.endDate)}',
                        )
                        .join('\n'),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: scheme.onSurface),
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
