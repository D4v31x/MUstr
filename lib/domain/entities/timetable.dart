enum LessonKind { lecture, seminar, event }

enum LessonPriority { low, normal, high }

class LessonStyleSettings {
  const LessonStyleSettings({
    this.lectureColorValue = 0xff2563eb,
    this.seminarColorValue = 0xffd04a02,
    this.examColorValue = 0xffba1a1a,
    this.importantDateColorValue = 0xff6750a4,
    this.examPeriodColorValue = 0xff006c65,
    this.subjectColorValues = const {},
  });

  final int lectureColorValue;
  final int seminarColorValue;
  final int examColorValue;
  final int importantDateColorValue;
  final int examPeriodColorValue;
  final Map<String, int> subjectColorValues;

  int? colorFor(LessonKind kind) => switch (kind) {
    LessonKind.lecture => lectureColorValue,
    LessonKind.seminar => seminarColorValue,
    LessonKind.event => null,
  };

  int? colorForSubject(String subjectId) => subjectColorValues[subjectId];

  LessonStyleSettings copyWith({
    int? lectureColorValue,
    int? seminarColorValue,
    int? examColorValue,
    int? importantDateColorValue,
    int? examPeriodColorValue,
    Map<String, int>? subjectColorValues,
  }) => LessonStyleSettings(
    lectureColorValue: lectureColorValue ?? this.lectureColorValue,
    seminarColorValue: seminarColorValue ?? this.seminarColorValue,
    examColorValue: examColorValue ?? this.examColorValue,
    importantDateColorValue:
        importantDateColorValue ?? this.importantDateColorValue,
    examPeriodColorValue: examPeriodColorValue ?? this.examPeriodColorValue,
    subjectColorValues: subjectColorValues ?? this.subjectColorValues,
  );
}

class Teacher {
  const Teacher({required this.id, required this.name});

  final String? id;
  final String name;
}

class Room {
  const Room({required this.id, required this.name});

  final String? id;
  final String name;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.subjectKey,
    required this.courseCode,
    required this.seminarGroup,
    required this.kind,
    required this.priority,
    required this.customColorValue,
    required this.courseName,
    required this.subjectId,
    required this.faculty,
    required this.timetableFacultyId,
    required this.semester,
    required this.rooms,
    required this.teachers,
    this.reminderAt,
  });

  final String id;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String subjectKey;
  final String courseCode;
  final String? seminarGroup;
  final LessonKind kind;
  final LessonPriority priority;
  final int? customColorValue;
  final String courseName;
  final String? subjectId;
  final String? faculty;
  final String? timetableFacultyId;
  final String? semester;
  final List<Room> rooms;
  final List<Teacher> teachers;
  final DateTime? reminderAt;

  Duration get duration => endTime.difference(startTime);
  bool get isMandatory => kind == LessonKind.seminar;
  String get attendanceImportance => switch (kind) {
    LessonKind.seminar => 'Mandatory',
    LessonKind.lecture => 'Recommended',
    LessonKind.event => 'Informational',
  };

  Lesson copyWithPresentation({
    LessonPriority? priority,
    int? customColorValue,
    bool clearCustomColor = false,
    DateTime? reminderAt,
    bool clearReminder = false,
  }) => Lesson(
    id: id,
    date: date,
    startTime: startTime,
    endTime: endTime,
    subjectKey: subjectKey,
    courseCode: courseCode,
    seminarGroup: seminarGroup,
    kind: kind,
    priority: priority ?? this.priority,
    customColorValue: clearCustomColor
        ? null
        : customColorValue ?? this.customColorValue,
    courseName: courseName,
    subjectId: subjectId,
    faculty: faculty,
    timetableFacultyId: timetableFacultyId,
    semester: semester,
    rooms: rooms,
    teachers: teachers,
    reminderAt: clearReminder ? null : reminderAt ?? this.reminderAt,
  );
}

class Subject {
  const Subject({
    required this.id,
    required this.courseCode,
    required this.name,
    required this.subjectId,
    required this.faculty,
    this.notes = '',
  });

  final String id;
  final String courseCode;
  final String name;
  final String? subjectId;
  final String? faculty;
  final String notes;

  Subject copyWith({String? notes}) => Subject(
    id: id,
    courseCode: courseCode,
    name: name,
    subjectId: subjectId,
    faculty: faculty,
    notes: notes ?? this.notes,
  );
}

class Timetable {
  const Timetable({
    required this.id,
    required this.name,
    required this.assignedFacultyId,
    required this.semester,
    required this.importedAt,
    required this.lessons,
    required this.subjects,
  });

  final String id;
  final String name;
  final String? assignedFacultyId;
  final String? semester;
  final DateTime importedAt;
  final List<Lesson> lessons;
  final List<Subject> subjects;

  DateTime? get firstDate => lessons.isEmpty ? null : lessons.first.date;
  DateTime? get lastDate => lessons.isEmpty ? null : lessons.last.date;

  Timetable copyWith({String? name}) => Timetable(
    id: id,
    name: name ?? this.name,
    assignedFacultyId: assignedFacultyId,
    semester: semester,
    importedAt: importedAt,
    lessons: lessons,
    subjects: subjects,
  );
}
