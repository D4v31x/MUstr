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
  final colorValue = lesson.customColorValue ?? settings.colorFor(lesson.kind);
  return colorValue == null
      ? eventColor(
          scheme,
          lesson.timetableFacultyId ?? lesson.faculty,
          lesson.subjectKey,
        )
      : Color(colorValue);
}

Color priorityColor(ColorScheme scheme, TaskPriority priority) =>
    switch (priority) {
      TaskPriority.high => scheme.error,
      TaskPriority.normal => scheme.primary,
      TaskPriority.low => scheme.tertiary,
    };

DateTime mondayFor(DateTime value) {
  final dateOnly = DateTime(value.year, value.month, value.day);
  return dateOnly.subtract(Duration(days: dateOnly.weekday - 1));
}
