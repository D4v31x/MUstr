import 'package:flutter_test/flutter_test.dart';
import 'package:muni_timetable/data/repositories/planner_repository.dart';
import 'package:muni_timetable/domain/entities/app_language.dart';
import 'package:muni_timetable/domain/entities/timetable.dart';
import 'package:muni_timetable/services/backup_service.dart';
import 'package:muni_timetable/services/webcal_timetable_service.dart';

const _muniFeed = '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//MUNI//Schedule//EN
BEGIN:VEVENT
UID:lecture-1
DTSTAMP:20260901T080000Z
DTSTART;TZID=Europe/Prague:20260918T120000
DTEND;TZID=Europe/Prague:20260918T135000
SUMMARY:Výpočetní systémy – PB151 (přednáška v 140)
LOCATION:140
END:VEVENT
BEGIN:VEVENT
UID:seminar-1
DTSTAMP:20260901T080000Z
DTSTART;TZID=Europe/Prague:20260921T120000
DTEND;TZID=Europe/Prague:20260921T135000
SUMMARY:Základy programování – IB111/14 (seminář v A219)
LOCATION:A219
END:VEVENT
BEGIN:VEVENT
UID:exam-1
DTSTAMP:20260901T080000Z
DTSTART;TZID=Europe/Prague:20261102T080000
DTEND;TZID=Europe/Prague:20261102T080000
SUMMARY:Zkušební termín (IB111 – Základy programování)
END:VEVENT
BEGIN:VEVENT
UID:deadline-1
DTSTAMP:20260901T080000Z
DTSTART;TZID=Europe/Prague:20261101T120000
DTEND;TZID=Europe/Prague:20261101T120000
SUMMARY:Konec odhlašování ze zkušebního termínu (PB151 – Výpočetní systémy)
END:VEVENT
BEGIN:VEVENT
UID:quiz-1
DTSTAMP:20260901T080000Z
DTSTART;TZID=Europe/Prague:20261005T000000
DTEND;TZID=Europe/Prague:20261005T000000
SUMMARY:Odpovědník otevřen (PB151: 06 přednáška)
END:VEVENT
END:VCALENDAR
''';

Timetable _parse(String calendar) => WebcalTimetableService().parse(
  calendar,
  facultyId: 'fi',
  webcalUrl: 'https://example.invalid/schedule.ics',
  syncedAt: DateTime(2026, 9, 1),
);

Lesson _byCategory(Timetable timetable, FeedCategory category) =>
    timetable.lessons.firstWhere((lesson) => lesson.feedCategory == category);

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

    final timetable = _parse(calendar);

    expect(timetable.isWebcalSynced, isTrue);
    expect(timetable.lessons, hasLength(2));
    expect(timetable.lessons.first.courseCode, 'PB123');
    expect(timetable.lessons.first.kind, LessonKind.seminar);
    expect(timetable.lessons.first.rooms.single.name, 'A318');
    expect(timetable.lessons.map((lesson) => lesson.startTime.day), [21, 28]);
  });

  test('keeps Prague wall-clock times through storage round trips', () {
    final lesson = _byCategory(_parse(_muniFeed), FeedCategory.lecture);

    expect(lesson.startTime.hour, 12);
    expect(lesson.endTime.hour, 13);
    expect(lesson.startTime.isUtc, isFalse);
    expect(
      DateTime.parse(lesson.startTime.toIso8601String()),
      lesson.startTime,
    );
  });

  test('classifies MUNI classes, exams, deadlines and quizzes', () {
    final timetable = _parse(_muniFeed);

    expect(timetable.lessons.map((lesson) => lesson.feedCategory).toSet(), {
      FeedCategory.lecture,
      FeedCategory.seminar,
      FeedCategory.exam,
      FeedCategory.deadline,
      FeedCategory.quiz,
    });
  });

  test('splits course name, code and seminar group', () {
    final timetable = _parse(_muniFeed);
    final seminar = _byCategory(timetable, FeedCategory.seminar);

    expect(seminar.courseCode, 'IB111');
    expect(seminar.courseName, 'Základy programování');
    expect(seminar.seminarGroup, '14');
    expect(seminar.kind, LessonKind.seminar);
    expect(timetable.subjects.map((subject) => subject.courseCode), [
      'IB111',
      'PB151',
    ]);
  });

  test('events share the subject of their course', () {
    final timetable = _parse(_muniFeed);
    final quiz = _byCategory(timetable, FeedCategory.quiz);
    final exam = _byCategory(timetable, FeedCategory.exam);

    expect(quiz.kind, LessonKind.event);
    expect(quiz.courseName, 'Odpovědník otevřen: 06 přednáška');
    expect(quiz.subjectKey, 'webcal:fi:pb151');
    expect(exam.courseName, 'Zkušební termín');
    expect(exam.subjectKey, 'webcal:fi:ib111');
  });

  test('quizzes, deadlines and exam terms are instants without duration', () {
    final timetable = _parse(_muniFeed);

    for (final category in [
      FeedCategory.quiz,
      FeedCategory.deadline,
      FeedCategory.exam,
    ]) {
      expect(_byCategory(timetable, category).isInstant, isTrue);
    }
    expect(_byCategory(timetable, FeedCategory.lecture).isInstant, isFalse);
    expect(_byCategory(timetable, FeedCategory.seminar).isInstant, isFalse);
  });

  test('feed filter hides categories and subjects of feed lessons only', () {
    final timetable = _parse(_muniFeed);
    final quiz = _byCategory(timetable, FeedCategory.quiz);
    final lecture = _byCategory(timetable, FeedCategory.lecture);
    final manual = Lesson(
      id: 'manual',
      date: lecture.date,
      startTime: lecture.startTime,
      endTime: lecture.endTime,
      subjectKey: lecture.subjectKey,
      courseCode: lecture.courseCode,
      seminarGroup: null,
      kind: LessonKind.lecture,
      priority: LessonPriority.normal,
      customColorValue: null,
      courseName: lecture.courseName,
      subjectId: null,
      faculty: null,
      timetableFacultyId: null,
      semester: null,
      rooms: const [],
      teachers: const [],
    );

    final byCategory = const FeedFilter().withCategory(
      FeedCategory.quiz,
      visible: false,
    );
    expect(byCategory.hides(quiz), isTrue);
    expect(byCategory.hides(lecture), isFalse);

    final bySubject = const FeedFilter().withSubject(
      lecture.subjectKey,
      visible: false,
    );
    expect(bySubject.hides(quiz), isTrue);
    expect(bySubject.hides(lecture), isTrue);
    expect(bySubject.hides(manual), isFalse);
    expect(
      bySubject.withSubject(lecture.subjectKey, visible: true).isEmpty,
      isTrue,
    );
  });

  test('app-wide filter drops hidden subjects and is backed up', () {
    final timetable = _parse(_muniFeed);
    final data = PlannerData(
      timetable: null,
      timetables: const [],
      faculties: const [],
      language: AppLanguage.english,
      subjects: const [],
      tasks: const [],
      eventFilter: const FeedFilter()
          .withSubject('webcal:fi:ib111', visible: false)
          .withCategory(FeedCategory.quiz, visible: false),
    ).withTimetables([timetable]);

    expect(data.subjects.map((subject) => subject.courseCode), ['PB151']);
    final settings =
        const BackupService().createDocument(data)['settings']!
            as Map<String, Object?>;
    expect(settings['eventFilter'], {
      'hiddenCategories': ['quiz'],
      'hiddenSubjectIds': ['webcal:fi:ib111'],
    });
  });

  test(
    'known course prefixes map to their faculty or the whole university',
    () {
      const calendar = '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//MUNI//Schedule//EN
BEGIN:VEVENT
UID:bss-1
DTSTAMP:20260901T080000Z
DTSTART;TZID=Europe/Prague:20260916T140000
DTEND;TZID=Europe/Prague:20260916T154000
SUMMARY:Úvod do kyberbezpečnosti – BSSb1203 (přednáška v online výuka)
END:VEVENT
BEGIN:VEVENT
UID:aut-1
DTSTAMP:20260901T080000Z
DTSTART;TZID=Europe/Prague:20260917T100000
DTEND;TZID=Europe/Prague:20260917T113000
SUMMARY:Základy plánování – AUT_TM1/Skupina_B (seminář v B11)
END:VEVENT
END:VCALENDAR
''';
      final timetable = _parse(calendar);
      final facultyOf = {
        for (final subject in timetable.subjects)
          subject.courseCode: subject.faculty,
      };

      expect(facultyOf, {'BSSb1203': 'fss', 'AUT_TM1': 'muni'});
      expect(timetable.lessons.map((lesson) => lesson.timetableFacultyId), [
        'fss',
        'muni',
      ]);
    },
  );

  test('a university-wide course appears in every faculty view', () {
    final parsed = _parse(_muniFeed);
    const wide = 'webcal:fi:pb151';
    final timetable = parsed.copyWith(
      lessons: [
        for (final lesson in parsed.lessons)
          lesson.subjectKey == wide ? lesson.withFaculty('muni') : lesson,
      ],
      subjects: [
        for (final subject in parsed.subjects)
          subject.id == wide ? subject.copyWith(faculty: 'muni') : subject,
      ],
    );
    final data = PlannerData(
      timetable: null,
      timetables: [timetable],
      faculties: const [],
      language: AppLanguage.english,
      subjects: const [],
      tasks: const [],
    );

    expect(
      data.forFaculty('sci').subjects.map((subject) => subject.courseCode),
      ['PB151'],
    );
  });

  test('a synced calendar can split its courses between faculties', () {
    final parsed = _parse(_muniFeed);
    const moved = 'webcal:fi:ib111';
    final timetable = parsed.copyWith(
      lessons: [
        for (final lesson in parsed.lessons)
          lesson.subjectKey == moved ? lesson.withFaculty('sci') : lesson,
      ],
      subjects: [
        for (final subject in parsed.subjects)
          subject.id == moved ? subject.copyWith(faculty: 'sci') : subject,
      ],
    );
    final data = PlannerData(
      timetable: null,
      timetables: [timetable],
      faculties: const [],
      language: AppLanguage.english,
      subjects: const [],
      tasks: const [],
    );

    final fi = data.forFaculty('fi');
    final sci = data.forFaculty('sci');

    expect(fi.subjects.map((subject) => subject.courseCode), ['PB151']);
    expect(
      fi.timetable!.lessons.every((lesson) => lesson.subjectKey != moved),
      isTrue,
    );
    expect(sci.subjects.map((subject) => subject.courseCode), ['IB111']);
    expect(
      sci.timetable!.lessons.every((lesson) => lesson.subjectKey == moved),
      isTrue,
    );
    expect(data.forFaculty('law').timetable, isNull);
  });

  test('normalizes webcal URLs to HTTPS', () {
    expect(
      WebcalTimetableService.normalizeUrl('webcal://is.muni.cz/calendar.ics'),
      Uri.parse('https://is.muni.cz/calendar.ics'),
    );
  });
}
