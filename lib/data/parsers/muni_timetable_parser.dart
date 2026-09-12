import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import '../../domain/entities/timetable.dart';

class TimetableParseException implements Exception {
  const TimetableParseException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MuniTimetableParser {
  MuniTimetableParser({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Timetable parse(String source, {DateTime? importedAt, String? assignedFacultyId}) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(source);
    } on XmlException catch (error) {
      throw TimetableParseException('The XML is not valid: ${error.message}');
    }

    if (document.rootElement.name.local != 'rozvrh') {
      throw const TimetableParseException(
        'This XML does not contain a MUNI timetable (<rozvrh>).',
      );
    }

    final slots = document.findAllElements('slot').toList();
    final semester = _findSemester(slots);
    final resolver = _SemesterDateResolver(semester);
    final seen = <String>{};
    final lessons = <Lesson>[];

    for (final day in document.findAllElements('den')) {
      final date = resolver.parseDay(day.getAttribute('id'));
      for (final slot in day.findAllElements('slot')) {
        final lesson = _parseLesson(slot, date, semester, assignedFacultyId);
        final signature = [
          lesson.date.toIso8601String(),
          lesson.startTime.toIso8601String(),
          lesson.endTime.toIso8601String(),
          lesson.subjectKey,
          lesson.rooms.map((room) => room.id ?? room.name).join('|'),
        ].join('#');
        if (seen.add(signature)) {
          lessons.add(lesson);
        }
      }
    }

    lessons.sort((first, second) => first.startTime.compareTo(second.startTime));
    if (lessons.isEmpty) {
      throw const TimetableParseException('No timetable events were found in this XML.');
    }

    final subjects = _buildSubjects(lessons);
    final now = importedAt ?? DateTime.now();
    return Timetable(
      id: _uuid.v4(),
      name: semester ?? 'Imported timetable',
      assignedFacultyId: assignedFacultyId,
      semester: semester,
      importedAt: now,
      lessons: List.unmodifiable(lessons),
      subjects: List.unmodifiable(subjects),
    );
  }

  Lesson _parseLesson(XmlElement slot, DateTime date, String? semester, String? assignedFacultyId) {
    final action = slot.getElement('akce');
    if (action == null) {
      throw const TimetableParseException('A timetable event is missing <akce> data.');
    }
    final courseCode = _text(action, 'kod');
    final courseName = _text(action, 'nazev');
    if (courseCode.isEmpty && courseName.isEmpty) {
      throw const TimetableParseException('A timetable event has no course code or name.');
    }

    final start = _dateTime(date, slot.getAttribute('odcas'), 'start');
    final end = _dateTime(date, slot.getAttribute('docas'), 'end');
    if (!end.isAfter(start)) {
      throw TimetableParseException('Event $courseCode has an invalid time range.');
    }

    final subjectId = _nullableText(action, 'predmetid');
    final faculty = _nullableText(action, 'fakulta_url');
    final courseParts = courseCode.split('/');
    final baseCourseCode = courseParts.first;
    final seminarGroup = _firstOptionalText(
          [action, slot],
          ['seminarGroup', 'seminar_group', 'seminarni_skupina'],
        ) ??
        (courseParts.length > 1 ? courseParts.sublist(1).join('/') : null);
    final kind = subjectId == null
      ? LessonKind.event
      : seminarGroup == null
        ? LessonKind.lecture
        : LessonKind.seminar;
    final subjectKey = subjectId ?? '${faculty ?? 'unknown'}:$courseCode';
    final rooms = slot
        .findAllElements('mistnost')
        .map(
          (room) => Room(
            id: _nullableText(room, 'mistnostid'),
            name: _text(room, 'mistnostozn'),
          ),
        )
        .where((room) => room.name.isNotEmpty)
        .toList();
    final teachers = slot
        .findAllElements('ucitel')
        .map(
          (teacher) => Teacher(
            id: _nullableText(teacher, 'ucitelid'),
            name: _text(teacher, 'uciteljmeno'),
          ),
        )
        .where((teacher) => teacher.name.isNotEmpty)
        .toList();

    return Lesson(
      id: _uuid.v4(),
      date: date,
      startTime: start,
      endTime: end,
      subjectKey: subjectKey,
      courseCode: baseCourseCode.isEmpty ? courseName : baseCourseCode,
      seminarGroup: seminarGroup,
      kind: kind,
      priority: kind == LessonKind.seminar ? LessonPriority.high : LessonPriority.normal,
      customColorValue: null,
      courseName: courseName.isEmpty ? courseCode : courseName,
      subjectId: subjectId,
      faculty: faculty,
      timetableFacultyId: assignedFacultyId,
      semester: _nullableText(action, 'obdobi_url') ?? semester,
      rooms: List.unmodifiable(rooms),
      teachers: List.unmodifiable(teachers),
    );
  }

  List<Subject> _buildSubjects(List<Lesson> lessons) {
    final byKey = <String, List<Lesson>>{};
    for (final lesson in lessons) {
      byKey.putIfAbsent(lesson.subjectKey, () => []).add(lesson);
    }
    return byKey.entries
        .map(
          (entry) => Subject(
            id: entry.key,
            courseCode: entry.value.first.courseCode,
            name: entry.value.first.courseName,
            subjectId: entry.value.first.subjectId,
            faculty: entry.value.first.faculty,
          ),
        )
        .toList()
      ..sort((first, second) => first.courseCode.compareTo(second.courseCode));
  }

  String? _findSemester(List<XmlElement> slots) {
    for (final slot in slots) {
      final semester = _nullableText(slot.getElement('akce'), 'obdobi_url');
      if (semester != null) {
        return semester;
      }
    }
    return null;
  }

  String _text(XmlElement? parent, String name) =>
      parent?.getElement(name)?.innerText.trim() ?? '';

  String? _nullableText(XmlElement? parent, String name) {
    final value = _text(parent, name);
    return value.isEmpty ? null : value;
  }

  String? _firstOptionalText(List<XmlElement?> parents, List<String> names) {
    for (final parent in parents) {
      for (final name in names) {
        final value = _nullableText(parent, name);
        if (value != null) return value;
      }
    }
    return null;
  }

  DateTime _dateTime(DateTime day, String? rawTime, String label) {
    final match = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*$').firstMatch(rawTime ?? '');
    if (match == null) {
      throw TimetableParseException('An event has an invalid $label time.');
    }
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) {
      throw TimetableParseException('An event has an invalid $label time.');
    }
    return DateTime(day.year, day.month, day.day, hour, minute);
  }
}

class _SemesterDateResolver {
  _SemesterDateResolver(this.semester);

  final String? semester;

  static const _weekdays = {
    'Po': DateTime.monday,
    'Út': DateTime.tuesday,
    'St': DateTime.wednesday,
    'Čt': DateTime.thursday,
    'Pá': DateTime.friday,
    'So': DateTime.saturday,
    'Ne': DateTime.sunday,
  };

  DateTime parseDay(String? rawDay) {
    final match = RegExp(r'^(Po|Út|St|Čt|Pá|So|Ne)\s+(\d{1,2})\.\s*(\d{1,2})\.$')
        .firstMatch(rawDay?.trim() ?? '');
    if (match == null) {
      throw TimetableParseException('Unknown MUNI day format: ${rawDay ?? '(missing)'}.');
    }
    final month = int.parse(match.group(3)!);
    final year = _yearFor(month);
    final date = DateTime(year, month, int.parse(match.group(2)!));
    if (date.month != month || date.weekday != _weekdays[match.group(1)]) {
      throw TimetableParseException('Invalid MUNI date: $rawDay.');
    }
    return date;
  }

  int _yearFor(int month) {
    final match = RegExp(r'^(podzim|jaro)(\d{4})$', caseSensitive: false)
        .firstMatch(semester ?? '');
    if (match == null) {
      return DateTime.now().year;
    }
    final startYear = int.parse(match.group(2)!);
    return match.group(1)!.toLowerCase() == 'podzim' && month <= 6
        ? startYear + 1
        : startYear;
  }
}