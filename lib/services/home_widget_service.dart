import 'package:flutter/material.dart' show ColorScheme;
import 'package:home_widget/home_widget.dart';

import '../data/repositories/planner_repository.dart';
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
const _maxLessonsPerWeek = 40;
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

/// Pushes this week's and next week's classes to the home screen widget,
/// which can then page between them locally without relaunching Flutter.
/// Widgets are a best-effort feature, so any failure here (e.g. no widget
/// support on the current platform/build) is swallowed rather than surfaced.
Future<void> updateScheduleWidget(PlannerData data) async {
  try {
    final now = DateTime.now();
    final currentWeekStart = _mondayFor(now);
    final nextWeekStart = currentWeekStart.add(const Duration(days: 7));

    await HomeWidget.saveWidgetData<String>(
      _currentLinesKey,
      _weekLessonLines(data, currentWeekStart, now: now).join('\n'),
    );
    await HomeWidget.saveWidgetData<String>(
      _nextLinesKey,
      _weekLessonLines(data, nextWeekStart, now: now).join('\n'),
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
  final dateOnly = DateTime(value.year, value.month, value.day);
  return dateOnly.subtract(Duration(days: dateOnly.weekday - 1));
}

String _dateLabel(DateTime value) => '${value.day}.${value.month}.';

String _weekRangeLabel(DateTime weekStart) {
  final weekEnd = weekStart.add(const Duration(days: 6));
  return '${_dateLabel(weekStart)} - ${_dateLabel(weekEnd)}';
}

/// Lines for the (Mon-Sun) week starting at [weekStart], one per lesson
/// across all imported timetables (each tagged with its timetable id so the
/// widget can filter by the user's per-widget selection). For the week
/// containing [now], lessons that already ended are skipped.
List<String> _weekLessonLines(
  PlannerData data,
  DateTime weekStart, {
  required DateTime now,
}) {
  final weekEnd = weekStart.add(const Duration(days: 7));
  final upcoming =
      [
            for (final timetable in data.timetables)
              for (final lesson in timetable.lessons) (timetable.id, lesson),
          ]
          .where(
            (entry) =>
                entry.$2.endTime.isAfter(now) &&
                !entry.$2.startTime.isBefore(weekStart) &&
                entry.$2.startTime.isBefore(weekEnd),
          )
          .toList()
        ..sort(
          (first, second) => first.$2.startTime.compareTo(second.$2.startTime),
        );
  return upcoming
      .take(_maxLessonsPerWeek)
      .map(
        (entry) => _formatLesson(
          entry.$2,
          entry.$1,
          now,
          data.lessonStyle,
          data.language.code,
        ),
      )
      .toList();
}

/// Encodes a lesson as `day|dateLabel|startTime|endTime|courseName|room|
/// colorHex|timetableId|isToday`.
String _formatLesson(
  Lesson lesson,
  String timetableId,
  DateTime now,
  LessonStyleSettings lessonStyle,
  String languageCode,
) {
  final weekdayNames =
      _weekdayNamesByLanguage[languageCode] ?? _weekdayNamesByLanguage['en']!;
  final day = weekdayNames[lesson.startTime.weekday - 1];
  final dateLabel = _dateLabel(lesson.startTime);
  final startTime = _timeLabel(lesson.startTime);
  final endTime = _timeLabel(lesson.endTime);
  final room = lesson.rooms.isEmpty ? '' : lesson.rooms.first.name;
  final isToday =
      lesson.startTime.year == now.year &&
      lesson.startTime.month == now.month &&
      lesson.startTime.day == now.day;
  final course = lesson.courseName.replaceAll('|', '/');
  final safeRoom = room.replaceAll('|', '/');
  final colorHex = lessonColor(
    _placeholderScheme,
    lesson,
    lessonStyle,
  ).toARGB32().toRadixString(16).padLeft(8, '0');
  final safeTimetableId = timetableId.replaceAll('|', '/');
  return '$day|$dateLabel|$startTime|$endTime|$course|$safeRoom|$colorHex|$safeTimetableId|${isToday ? 1 : 0}';
}

String _timeLabel(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
