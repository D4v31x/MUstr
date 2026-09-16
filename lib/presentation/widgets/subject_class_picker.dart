import 'package:material_ui/material_ui.dart';

import '../../domain/entities/timetable.dart';
import '../localization/app_strings.dart';
import 'planner_formatters.dart';

Future<Lesson?> pickSubjectClass(
  BuildContext context, {
  required List<Lesson> lessons,
}) async {
  final sessions =
      lessons.where((lesson) => lesson.kind != LessonKind.event).toList()
        ..sort((first, second) => first.startTime.compareTo(second.startTime));
  if (sessions.isEmpty) {
    return null;
  }

  final firstDate = _calendarDate(sessions.first.startTime);
  final lastDate = _calendarDate(sessions.last.startTime);
  final availableDays = sessions
      .map((lesson) => _calendarDate(lesson.startTime))
      .toSet();
  final date = await showDatePicker(
    context: context,
    initialDate: firstDate,
    firstDate: firstDate,
    lastDate: lastDate,
    selectableDayPredicate: availableDays.contains,
  );
  if (date == null || !context.mounted) {
    return null;
  }

  final sessionsOnDay = sessions
      .where((lesson) => _calendarDate(lesson.startTime) == date)
      .toList();
  return showModalBottomSheet<Lesson>(
    context: context,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.65,
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.strings.chooseClassSession,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              compactDate(context, date),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sessionsOnDay.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final lesson = sessionsOnDay[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      lesson.kind == LessonKind.seminar
                          ? Icons.groups_outlined
                          : Icons.auto_stories_outlined,
                    ),
                    title: Text(lesson.courseName),
                    subtitle: Text(
                      '${lesson.kind == LessonKind.seminar ? context.strings.seminarDetails(lesson.seminarGroup) : context.strings.lecture} | ${timeLabel(lesson.startTime)} - ${timeLabel(lesson.endTime)}',
                    ),
                    onTap: () => Navigator.of(context).pop(lesson),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

DateTime _calendarDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);
