import 'package:material_ui/material_ui.dart' show Color, ColorScheme;
import 'package:home_widget/home_widget.dart';

import '../data/repositories/planner_repository.dart';
import '../domain/entities/exam.dart';
import '../domain/entities/important_date.dart';
import '../domain/entities/timetable.dart';
import '../presentation/widgets/planner_formatters.dart' show lessonColor;

// lessonColor's ColorScheme parameter is unused by its actual color logic
// (faculty/subject/custom colors), so a placeholder scheme is safe here.
const _placeholderScheme = ColorScheme.light();

const _androidWidgetProvider = 'ScheduleWidgetProvider';
const _currentLinesKey = 'schedule_lines_current';
const _nextLinesKey = 'schedule_lines_next';
const _currentLabelKey = 'schedule_label_current';
const _nextLabelKey = 'schedule_label_next';
const _availableTimetablesKey = 'available_timetables';
const _appLanguageKey = 'app_language';
const _maxScheduleItemsPerWeek = 40;
const _examLabels = {'en': 'Exam', 'cs': 'Zkouška', 'sk': 'Skúška'};
const _importantDateLabels = {
  'en': 'Important date',
  'cs': 'Důležité datum',
  'sk': 'Dôležitý dátum',
};
const _allDayLabels = {'en': 'All day', 'cs': 'Celý den', 'sk': 'Celý deň'};
const _weekdayNamesByLanguage = {
  'en': [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ],
  'cs': ['Pondělí', 'Úterý', 'Středa', 'Čtvrtek', 'Pátek', 'Sobota', 'Neděle'],
  'sk': [
    'Pondelok',
    'Utorok',
    'Streda',
    'Štvrtok',
    'Piatok',
    'Sobota',
    'Nedeľa',
  ],
};

/// Pushes this week's and next week's schedule to the home screen widget,
/// which can then page between them locally without relaunching Flutter.
/// Widgets are a best-effort feature, so any failure here (e.g. no widget
/// support on the current platform/build) is swallowed rather than surfaced.
Future<void> updateScheduleWidget(PlannerData data) async {
  try {
    final now = DateTime.now();
    final currentWeekStart = _mondayFor(now);
    final nextWeekStart = _addCalendarDays(currentWeekStart, 7);

    await HomeWidget.saveWidgetData<String>(
      _currentLinesKey,
      _weekScheduleLines(data, currentWeekStart, now: now).join('\n'),
    );
    await HomeWidget.saveWidgetData<String>(
      _nextLinesKey,
      _weekScheduleLines(data, nextWeekStart, now: now).join('\n'),
    );
    await HomeWidget.saveWidgetData<String>(
      _currentLabelKey,
      _weekRangeLabel(currentWeekStart),
    );
    await HomeWidget.saveWidgetData<String>(
      _nextLabelKey,
      _weekRangeLabel(nextWeekStart),
    );
    await HomeWidget.saveWidgetData<String>(
      _appLanguageKey,
      data.language.code,
    );
    await HomeWidget.saveWidgetData<String>(
      _availableTimetablesKey,
      data.timetables
          .map(
            (timetable) =>
                '${timetable.id}|${timetable.name.replaceAll('|', '/')}',
          )
          .join('\n'),
    );
    await HomeWidget.updateWidget(androidName: _androidWidgetProvider);
  } catch (_) {
    // No home screen widget support on this platform/build.
  }
}

DateTime _mondayFor(DateTime value) {
  return DateTime(value.year, value.month, value.day - value.weekday + 1);
}

DateTime _addCalendarDays(DateTime value, int days) =>
    DateTime(value.year, value.month, value.day + days);

String _dateLabel(DateTime value) => '${value.day}.${value.month}.';

String _weekRangeLabel(DateTime weekStart) {
  final weekEnd = _addCalendarDays(weekStart, 6);
  return '${_dateLabel(weekStart)} - ${_dateLabel(weekEnd)}';
}

/// Lines for the (Mon-Sun) week starting at [weekStart], including classes,
/// exams, and important dates. Lesson rows are tagged with their timetable id
/// so the widget can filter those rows by its per-widget selection.
List<String> _weekScheduleLines(
  PlannerData data,
  DateTime weekStart, {
  required DateTime now,
}) {
  final weekEnd = _addCalendarDays(weekStart, 7);
  final upcoming = <_WidgetScheduleItem>[
    for (final timetable in data.timetables)
      for (final lesson in timetable.lessons)
        if (lesson.endTime.isAfter(now) &&
            !lesson.startTime.isBefore(weekStart) &&
            lesson.startTime.isBefore(weekEnd))
          _WidgetScheduleItem.lesson(lesson, timetable.id),
    for (final exam in data.exams)
      if (exam.scheduledAt.isAfter(now) &&
          !exam.scheduledAt.isBefore(weekStart) &&
          exam.scheduledAt.isBefore(weekEnd))
        _WidgetScheduleItem.exam(exam),
    for (final importantDate in data.importantDates)
      if (!importantDate.date.isBefore(weekStart) &&
          importantDate.date.isBefore(weekEnd) &&
          (importantDate.timeMinute == null ||
              importantDate.scheduledAt.isAfter(now)))
        _WidgetScheduleItem.importantDate(importantDate),
  ]..sort((first, second) => first.start.compareTo(second.start));
  return upcoming
      .take(_maxScheduleItemsPerWeek)
      .map(
        (item) => _formatScheduleItem(
          item,
          now,
          data.lessonStyle,
          data.language.code,
        ),
      )
      .toList();
}

/// Encodes an item as `day|dateLabel|startTime|endTime|title|location|
/// colorHex|timetableId|isToday|kind|endAtMillis`.
String _formatScheduleItem(
  _WidgetScheduleItem item,
  DateTime now,
  LessonStyleSettings lessonStyle,
  String languageCode,
) {
  final weekdayNames =
      _weekdayNamesByLanguage[languageCode] ?? _weekdayNamesByLanguage['en']!;
  final day = weekdayNames[item.start.weekday - 1];
  final dateLabel = _dateLabel(item.start);
  final startTime = item.isAllDay
      ? _allDayLabels[languageCode] ?? _allDayLabels['en']!
      : _timeLabel(item.start);
  final endTime = item.isAllDay ? '' : _timeLabel(item.end);
  final isToday =
      item.start.year == now.year &&
      item.start.month == now.month &&
      item.start.day == now.day;
  final label = switch (item.kind) {
    'exam' => _examLabels[languageCode] ?? _examLabels['en']!,
    'important-date' =>
      _importantDateLabels[languageCode] ?? _importantDateLabels['en']!,
    _ => null,
  };
  final safeTitle = (label == null ? item.title : '$label: ${item.title}')
      .replaceAll('|', '/');
  final safeLocation = item.location.replaceAll('|', '/');
  final safeTimetableId = item.timetableId.replaceAll('|', '/');
  return '$day|$dateLabel|$startTime|$endTime|$safeTitle|$safeLocation|${item.colorHex(lessonStyle)}|$safeTimetableId|${isToday ? 1 : 0}|${item.kind}|${item.end.millisecondsSinceEpoch}';
}

class _WidgetScheduleItem {
  const _WidgetScheduleItem._({
    required this.start,
    required this.end,
    required this.title,
    required this.location,
    required this.timetableId,
    required this.kind,
    required this.isAllDay,
    this.lesson,
  });

  factory _WidgetScheduleItem.lesson(Lesson lesson, String timetableId) =>
      _WidgetScheduleItem._(
        start: lesson.startTime,
        end: lesson.endTime,
        title: lesson.courseName,
        location: lesson.rooms.isEmpty ? '' : lesson.rooms.first.name,
        timetableId: timetableId,
        kind: 'lesson',
        isAllDay: false,
        lesson: lesson,
      );

  factory _WidgetScheduleItem.exam(Exam exam) => _WidgetScheduleItem._(
    start: exam.scheduledAt,
    end: exam.scheduledAt.add(const Duration(hours: 2)),
    title: exam.title,
    location: exam.location,
    timetableId: '',
    kind: 'exam',
    isAllDay: false,
  );

  factory _WidgetScheduleItem.importantDate(ImportantDate importantDate) =>
      _WidgetScheduleItem._(
        start: importantDate.scheduledAt,
        end: importantDate.scheduledAt,
        title: importantDate.title,
        location: '',
        timetableId: '',
        kind: 'important-date',
        isAllDay: importantDate.timeMinute == null,
      );

  final DateTime start;
  final DateTime end;
  final String title;
  final String location;
  final String timetableId;
  final String kind;
  final bool isAllDay;
  final Lesson? lesson;

  String colorHex(LessonStyleSettings lessonStyle) {
    final color = switch (kind) {
      'exam' => Color(lessonStyle.examColorValue),
      'important-date' => Color(lessonStyle.importantDateColorValue),
      _ => lessonColor(_placeholderScheme, lesson!, lessonStyle),
    };
    return color.toARGB32().toRadixString(16).padLeft(8, '0');
  }
}

String _timeLabel(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
