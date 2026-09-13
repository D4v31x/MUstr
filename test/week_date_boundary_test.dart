import 'package:flutter_test/flutter_test.dart';
import 'package:muni_timetable/presentation/widgets/planner_formatters.dart';

void main() {
  test('week start is midnight so Monday lessons stay in their own week', () {
    final weekStart = mondayFor(DateTime(2026, 9, 11, 15, 30));
    final mondayLesson = DateTime(2026, 9, 7);

    expect(weekStart, DateTime(2026, 9, 7));
    expect(mondayLesson.isBefore(weekStart), isFalse);
    expect(
      mondayLesson.isBefore(weekStart.add(const Duration(days: 7))),
      isTrue,
    );
  });

  test('week boundaries preserve weekdays across the October DST change', () {
    final weekStart = DateTime(2026, 10, 19);
    final nextWeekStart = addCalendarDays(weekStart, 7);

    expect(nextWeekStart, DateTime(2026, 10, 26));
    expect(nextWeekStart.weekday, DateTime.monday);
    expect(calendarDayDifference(weekStart, nextWeekStart), 7);
  });
}
