import 'package:flutter_test/flutter_test.dart';
import 'package:muni_timetable/domain/entities/timetable.dart';
import 'package:muni_timetable/services/webcal_timetable_service.dart';

void main() {
  test('parses and expands recurring webcal class events', () {
    const calendar = '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//MUNI//Schedule//EN
BEGIN:VEVENT
UID:pb123-seminar
DTSTAMP:20260901T080000Z
DTSTART;TZID=Europe/Prague:20260921T090000
DTEND;TZID=Europe/Prague:20260921T103000
RRULE:FREQ=WEEKLY;COUNT=2
SUMMARY:PB123 - Seminar A
LOCATION:A318
END:VEVENT
END:VCALENDAR
''';

    final timetable = WebcalTimetableService().parse(
      calendar,
      facultyId: 'fi',
      webcalUrl: 'https://example.invalid/schedule.ics',
      syncedAt: DateTime(2026, 9, 1),
    );

    expect(timetable.isWebcalSynced, isTrue);
    expect(timetable.lessons, hasLength(2));
    expect(timetable.lessons.first.courseCode, 'PB123');
    expect(timetable.lessons.first.kind, LessonKind.seminar);
    expect(timetable.lessons.first.rooms.single.name, 'A318');
    expect(timetable.lessons.map((lesson) => lesson.startTime.day), [21, 28]);
  });

  test('normalizes webcal URLs to HTTPS', () {
    expect(
      WebcalTimetableService.normalizeUrl('webcal://is.muni.cz/calendar.ics'),
      Uri.parse('https://is.muni.cz/calendar.ics'),
    );
  });
}
