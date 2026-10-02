enum LessonKind { lecture, seminar, event }

enum LessonPriority { low, normal, high }

enum FeedCategory { lecture, seminar, exam, quiz, deadline, other }

class FeedFilter {
  const FeedFilter({
    this.hiddenCategories = const {},
    this.hiddenSubjectIds = const {},
  });

  final Set<FeedCategory> hiddenCategories;
  final Set<String> hiddenSubjectIds;

  bool get isEmpty => hiddenCategories.isEmpty && hiddenSubjectIds.isEmpty;

  // Manually added classes carry no feed category and are never hidden.
  bool hides(Lesson lesson) {
    final category = lesson.feedCategory;
    return category != null &&
        (hiddenCategories.contains(category) ||
            hiddenSubjectIds.contains(lesson.subjectKey));
  }

  FeedFilter withCategory(FeedCategory category, {required bool visible}) =>
      FeedFilter(
        hiddenCategories: {...hiddenCategories}
          ..remove(category)
          ..addAll(visible ? const [] : [category]),
        hiddenSubjectIds: hiddenSubjectIds,
      );

  FeedFilter withSubject(String subjectId, {required bool visible}) =>
      FeedFilter(
        hiddenCategories: hiddenCategories,
        hiddenSubjectIds: {...hiddenSubjectIds}
          ..remove(subjectId)
          ..addAll(visible ? const [] : [subjectId]),
      );
}

class LessonStyleSettings {
  const LessonStyleSettings({
    this.lectureColorValue = 0xff2563eb,
    this.seminarColorValue = 0xffd04a02,
    this.examColorValue = 0xffba1a1a,
    this.importantDateColorValue = 0xff6750a4,
    this.examPeriodColorValue = 0xff006c65,
  });

  final int lectureColorValue;
  final int seminarColorValue;
  final int examColorValue;
  final int importantDateColorValue;
  final int examPeriodColorValue;

  int? colorFor(LessonKind kind) => switch (kind) {
    LessonKind.lecture => lectureColorValue,
    LessonKind.seminar => seminarColorValue,
    LessonKind.event => null,
  };

  LessonStyleSettings copyWith({
    int? lectureColorValue,
    int? seminarColorValue,
    int? examColorValue,
    int? importantDateColorValue,
    int? examPeriodColorValue,
  }) => LessonStyleSettings(
    lectureColorValue: lectureColorValue ?? this.lectureColorValue,
    seminarColorValue: seminarColorValue ?? this.seminarColorValue,
    examColorValue: examColorValue ?? this.examColorValue,
    importantDateColorValue:
        importantDateColorValue ?? this.importantDateColorValue,
    examPeriodColorValue: examPeriodColorValue ?? this.examPeriodColorValue,
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
    this.feedCategory,
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
  final FeedCategory? feedCategory;

  Duration get duration => endTime.difference(startTime);
  bool get isInstant => !endTime.isAfter(startTime);
  bool get isMandatory => kind == LessonKind.seminar;
  String get attendanceImportance => switch (kind) {
    LessonKind.seminar => 'Mandatory',
    LessonKind.lecture => 'Recommended',
    LessonKind.event => 'Informational',
  };

  Lesson withFaculty(String facultyId) => Lesson(
    id: id,
    date: date,
    startTime: startTime,
    endTime: endTime,
    subjectKey: subjectKey,
    courseCode: courseCode,
    seminarGroup: seminarGroup,
    kind: kind,
    priority: priority,
    customColorValue: customColorValue,
    courseName: courseName,
    subjectId: subjectId,
    faculty: facultyId,
    timetableFacultyId: facultyId,
    semester: semester,
    rooms: rooms,
    teachers: teachers,
    reminderAt: reminderAt,
    feedCategory: feedCategory,
  );

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
    feedCategory: feedCategory,
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

  Subject copyWith({String? notes, String? faculty}) => Subject(
    id: id,
    courseCode: courseCode,
    name: name,
    subjectId: subjectId,
    faculty: faculty ?? this.faculty,
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
    this.webcalUrl,
    this.lastSyncedAt,
  });

  final String id;
  final String name;
  final String? assignedFacultyId;
  final String? semester;
  final DateTime importedAt;
  final List<Lesson> lessons;
  final List<Subject> subjects;
  final String? webcalUrl;
  final DateTime? lastSyncedAt;

  bool get isWebcalSynced => webcalUrl != null;

  DateTime? get firstDate => lessons.isEmpty ? null : lessons.first.date;
  DateTime? get lastDate => lessons.isEmpty ? null : lessons.last.date;

  Timetable copyWith({
    String? name,
    List<Lesson>? lessons,
    List<Subject>? subjects,
  }) => Timetable(
    id: id,
    name: name ?? this.name,
    assignedFacultyId: assignedFacultyId,
    semester: semester,
    importedAt: importedAt,
    lessons: lessons ?? this.lessons,
    subjects: subjects ?? this.subjects,
    webcalUrl: webcalUrl,
    lastSyncedAt: lastSyncedAt,
  );
}
