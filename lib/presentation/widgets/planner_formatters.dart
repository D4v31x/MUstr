import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/planner_task.dart';
import '../../domain/entities/faculty.dart';
import '../../domain/entities/timetable.dart';

String dayLabel(BuildContext context, DateTime value) => DateFormat(
  'EEEE, d MMMM',
  Localizations.localeOf(context).languageCode,
).format(value);
String compactDate(BuildContext context, DateTime value) => DateFormat(
  'EEE d MMM',
  Localizations.localeOf(context).languageCode,
).format(value);
String shortWeekday(BuildContext context, DateTime value) => DateFormat(
  'EEE',
  Localizations.localeOf(context).languageCode,
).format(value);
String timeLabel(DateTime value) => DateFormat('HH:mm').format(value);
String timetableCodeLabel(Lesson lesson) =>
    lesson.kind == LessonKind.seminar && lesson.seminarGroup != null
    ? '${lesson.courseCode} / ${lesson.seminarGroup}'
    : lesson.courseCode;
String dueLabel(BuildContext context, PlannerTask task) {
  final locale = Localizations.localeOf(context).languageCode;
  final date = DateFormat('EEE, d MMM', locale).format(task.dueDate);
  if (task.dueMinute == null) return date;
  final time =
      '${(task.dueMinute! ~/ 60).toString().padLeft(2, '0')}:${(task.dueMinute! % 60).toString().padLeft(2, '0')}';
  return switch (locale) {
    'cs' => '$date v $time',
    'sk' => '$date o $time',
    _ => '$date at $time',
  };
}

Color subjectColor(ColorScheme scheme, String key) {
  const colors = [
    Color(0xff006c65),
    Color(0xff875800),
    Color(0xff9b405d),
    Color(0xff4a5f9d),
    Color(0xff5f6b27),
    Color(0xff8b4e00),
  ];
  return colors[key.hashCode.abs() % colors.length];
}

Color eventColor(ColorScheme scheme, String? facultyId, String subjectKey) =>
    MuniFaculties.byId(facultyId)?.color ?? subjectColor(scheme, subjectKey);

Color lessonColor(
  ColorScheme scheme,
  Lesson lesson,
  LessonStyleSettings settings,
) {
  final colorValue =
      lesson.customColorValue ??
      settings.colorForSubject(lesson.subjectKey) ??
      settings.colorFor(lesson.kind);
  return colorValue == null
      ? eventColor(
          scheme,
          lesson.timetableFacultyId ?? lesson.faculty,
          lesson.subjectKey,
        )
      : Color(colorValue);
}

Color readableAccentColor(
  Color accent,
  Color background, {
  required Color fallback,
  double minimumContrast = 4.5,
}) {
  if (_contrastRatio(accent, background) >= minimumContrast) return accent;
  for (var step = 1; step <= 20; step++) {
    final adjusted = Color.lerp(accent, fallback, step / 20)!;
    if (_contrastRatio(adjusted, background) >= minimumContrast) {
      return adjusted;
    }
  }
  return fallback;
}

Color readableTextColor(Color background) =>
    _contrastRatio(Colors.black, background) >=
        _contrastRatio(Colors.white, background)
    ? Colors.black
    : Colors.white;

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

Color priorityColor(ColorScheme scheme, TaskPriority priority) =>
    switch (priority) {
      TaskPriority.high => scheme.error,
      TaskPriority.normal => scheme.primary,
      TaskPriority.low => scheme.tertiary,
    };

DateTime mondayFor(DateTime value) {
  return DateTime(value.year, value.month, value.day - value.weekday + 1);
}

DateTime addCalendarDays(DateTime value, int days) =>
    DateTime(value.year, value.month, value.day + days);

int calendarDayDifference(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
