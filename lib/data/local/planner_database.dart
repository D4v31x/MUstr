import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/planner_task.dart';
import '../../domain/entities/faculty.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/entities/timetable.dart';
import '../../domain/entities/exam.dart';
import '../repositories/planner_repository.dart';

class SqlitePlannerRepository implements PlannerRepository {
  Database? _database;

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }
    final directory = await getApplicationDocumentsDirectory();
    final database = await openDatabase(
      path.join(directory.path, 'muni_planner.db'),
      version: 7,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE timetables (
            id TEXT PRIMARY KEY, name TEXT NOT NULL, semester TEXT,
            imported_at TEXT NOT NULL, is_active INTEGER NOT NULL,
            faculty_id TEXT
          )
        ''');
        await db.execute(
          'CREATE TABLE faculty_memberships (faculty_id TEXT PRIMARY KEY)',
        );
        await db.execute(
          'CREATE TABLE app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
        );
        await db.execute('''
          CREATE TABLE subjects (
            id TEXT PRIMARY KEY, course_code TEXT NOT NULL, name TEXT NOT NULL,
            subject_id TEXT, faculty TEXT, notes TEXT NOT NULL DEFAULT ''
          )
        ''');
        await db.execute('''
          CREATE TABLE timetable_subjects (
            timetable_id TEXT NOT NULL, subject_id TEXT NOT NULL,
            PRIMARY KEY (timetable_id, subject_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE lessons (
            id TEXT PRIMARY KEY, timetable_id TEXT NOT NULL, date TEXT NOT NULL,
            start_at TEXT NOT NULL, end_at TEXT NOT NULL, subject_key TEXT NOT NULL,
            course_code TEXT NOT NULL, course_name TEXT NOT NULL, subject_id TEXT,
            faculty TEXT, timetable_faculty_id TEXT, semester TEXT, seminar_group TEXT, lesson_kind INTEGER NOT NULL DEFAULT 0, rooms TEXT NOT NULL, teachers TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT NOT NULL,
            subject_id TEXT, due_date TEXT NOT NULL, due_minute INTEGER,
            reminder_at TEXT, priority INTEGER NOT NULL, completed INTEGER NOT NULL,
            created_at TEXT NOT NULL, updated_at TEXT NOT NULL
          )
        ''');
        await _createExamTables(db);
        await db.execute('''
          CREATE TABLE lesson_preferences (
            lesson_id TEXT PRIMARY KEY, priority INTEGER NOT NULL, color_value INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE timetables ADD COLUMN faculty_id TEXT');
          await db.execute(
            'CREATE TABLE faculty_memberships (faculty_id TEXT PRIMARY KEY)',
          );
          await db.execute('''
            UPDATE timetables SET faculty_id = COALESCE(
              (SELECT faculty FROM lessons WHERE lessons.timetable_id = timetables.id AND faculty IS NOT NULL LIMIT 1),
              'fi'
            )
          ''');
          await db.execute('''
            INSERT OR IGNORE INTO faculty_memberships (faculty_id)
            SELECT DISTINCT faculty_id FROM timetables WHERE faculty_id IS NOT NULL
          ''');
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE lessons ADD COLUMN timetable_faculty_id TEXT',
          );
          await db.execute('''
            UPDATE lessons SET timetable_faculty_id = (
              SELECT faculty_id FROM timetables WHERE timetables.id = lessons.timetable_id
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute(
            'CREATE TABLE app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
          );
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE lessons ADD COLUMN seminar_group TEXT');
          await db.execute(
            'ALTER TABLE lessons ADD COLUMN lesson_kind INTEGER NOT NULL DEFAULT 0',
          );
          await db.execute('''
            UPDATE lessons
            SET seminar_group = CASE WHEN instr(course_code, '/') > 0 THEN substr(course_code, instr(course_code, '/') + 1) END,
                lesson_kind = CASE WHEN subject_id IS NULL THEN 2 WHEN instr(course_code, '/') > 0 THEN 1 ELSE 0 END,
                course_code = CASE WHEN instr(course_code, '/') > 0 THEN substr(course_code, 1, instr(course_code, '/') - 1) ELSE course_code END
          ''');
        }
        if (oldVersion < 6) {
          await _createExamTables(db);
        }
        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE lesson_preferences (
              lesson_id TEXT PRIMARY KEY, priority INTEGER NOT NULL, color_value INTEGER
            )
          ''');
        }
      },
    );
    _database = database;
    return database;
  }

  @override
  Future<PlannerData> load() async {
    final db = await _db;
    final lessonStyle = await _readLessonStyle(db);
    final lessonPreferences = await _readLessonPreferences(db);
    final languageRows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['language'],
    );
    final language = AppLanguage.fromCode(
      languageRows.isEmpty ? null : languageRows.single['value'] as String,
    );
    final themeModeRows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['theme_mode'],
    );
    final themeMode = AppThemeMode.fromCode(
      themeModeRows.isEmpty ? null : themeModeRows.single['value'] as String,
    );
    final remindersEnabled = await _readFlag(db, 'reminders_enabled');
    final showRoomInSchedule = await _readFlag(db, 'show_room_in_schedule');
    final highlightCurrentDay = await _readFlag(db, 'highlight_current_day');
    final membershipRows = await db.query(
      'faculty_memberships',
      orderBy: 'faculty_id',
    );
    final faculties = membershipRows
        .map((row) => MuniFaculties.byId(row['faculty_id'] as String))
        .whereType<Faculty>()
        .toList();
    final timetableRows = await db.query(
      'timetables',
      where: 'is_active = 1',
      orderBy: 'imported_at DESC',
    );
    final timetables = <Timetable>[];
    for (final row in timetableRows) {
      final timetableId = row['id']! as String;
      final lessonRows = await db.query(
        'lessons',
        where: 'timetable_id = ?',
        whereArgs: [timetableId],
        orderBy: 'start_at',
      );
      final subjects = await _readSubjects(db, timetableId);
      timetables.add(
        Timetable(
          id: timetableId,
          name: row['name']! as String,
          assignedFacultyId: row['faculty_id'] as String?,
          semester: row['semester'] as String?,
          importedAt: DateTime.parse(row['imported_at']! as String),
          lessons: lessonRows
              .map(
                (row) =>
                    _lessonFromRow(row, lessonPreferences[row['id'] as String]),
              )
              .toList(),
          subjects: subjects,
        ),
      );
    }
    final tasks = await _readTasks(db);
    final exams = await _readExams(db);
    final examPeriods = await _readExamPeriods(db);
    final lessons = timetables.expand((timetable) => timetable.lessons).toList()
      ..sort((first, second) => first.startTime.compareTo(second.startTime));
    final subjectsById = <String, Subject>{
      for (final subject in timetables.expand(
        (timetable) => timetable.subjects,
      ))
        subject.id: subject,
    };
    final subjects = subjectsById.values.toList()
      ..sort((first, second) => first.courseCode.compareTo(second.courseCode));
    return PlannerData(
      timetable: lessons.isEmpty
          ? null
          : Timetable(
              id: 'combined',
              name: 'My schedule',
              assignedFacultyId: null,
              semester: null,
              importedAt: DateTime.now(),
              lessons: lessons,
              subjects: subjects,
            ),
      timetables: timetables,
      faculties: faculties,
      language: language,
      themeMode: themeMode,
      lessonStyle: lessonStyle,
      remindersEnabled: remindersEnabled,
      showRoomInSchedule: showRoomInSchedule,
      highlightCurrentDay: highlightCurrentDay,
      exams: exams,
      examPeriods: examPeriods,
      subjects: subjects,
      tasks: tasks,
    );
  }

  @override
  Future<void> saveTimetable(Timetable timetable, String facultyId) async {
    final db = await _db;
    await db.transaction((transaction) async {
      await transaction.insert('timetables', {
        'id': timetable.id,
        'name': timetable.name,
        'semester': timetable.semester,
        'imported_at': timetable.importedAt.toIso8601String(),
        'is_active': 1,
        'faculty_id': facultyId,
      });
      for (final subject in timetable.subjects) {
        await transaction.insert('subjects', {
          'id': subject.id,
          'course_code': subject.courseCode,
          'name': subject.name,
          'subject_id': subject.subjectId,
          'faculty': subject.faculty,
          'notes': subject.notes,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        await transaction.update(
          'subjects',
          {
            'course_code': subject.courseCode,
            'name': subject.name,
            'subject_id': subject.subjectId,
            'faculty': subject.faculty,
          },
          where: 'id = ?',
          whereArgs: [subject.id],
        );
        await transaction.insert('timetable_subjects', {
          'timetable_id': timetable.id,
          'subject_id': subject.id,
        });
      }
      for (final lesson in timetable.lessons) {
        await transaction.insert('lessons', _lessonToRow(lesson, timetable.id));
      }
    });
  }

  @override
  Future<void> addLesson(
    String timetableId,
    Lesson lesson,
    Subject subject,
  ) async {
    final db = await _db;
    await db.transaction((transaction) async {
      final timetable = await transaction.query(
        'timetables',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [timetableId],
        limit: 1,
      );
      if (timetable.isEmpty) {
        throw StateError('The selected timetable no longer exists.');
      }
      await transaction.insert('subjects', {
        'id': subject.id,
        'course_code': subject.courseCode,
        'name': subject.name,
        'subject_id': subject.subjectId,
        'faculty': subject.faculty,
        'notes': subject.notes,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await transaction.insert('timetable_subjects', {
        'timetable_id': timetableId,
        'subject_id': subject.id,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await transaction.insert('lessons', _lessonToRow(lesson, timetableId));
    });
  }

  @override
  Future<void> deleteTimetables(List<String> timetableIds) async {
    if (timetableIds.isEmpty) {
      return;
    }
    final db = await _db;
    final placeholders = List.filled(timetableIds.length, '?').join(', ');
    await db.transaction((transaction) async {
      await transaction.delete(
        'lesson_preferences',
        where:
            'lesson_id IN (SELECT id FROM lessons WHERE timetable_id IN ($placeholders))',
        whereArgs: timetableIds,
      );
      await transaction.delete(
        'lessons',
        where: 'timetable_id IN ($placeholders)',
        whereArgs: timetableIds,
      );
      await transaction.delete(
        'timetable_subjects',
        where: 'timetable_id IN ($placeholders)',
        whereArgs: timetableIds,
      );
      await transaction.delete(
        'timetables',
        where: 'id IN ($placeholders)',
        whereArgs: timetableIds,
      );
    });
  }

  @override
  Future<void> renameTimetable(String timetableId, String name) async {
    final db = await _db;
    await db.update(
      'timetables',
      {'name': name},
      where: 'id = ?',
      whereArgs: [timetableId],
    );
  }

  @override
  Future<void> saveFacultyMemberships(List<String> facultyIds) async {
    final db = await _db;
    await db.transaction((transaction) async {
      await transaction.delete('faculty_memberships');
      for (final facultyId in facultyIds) {
        await transaction.insert('faculty_memberships', {
          'faculty_id': facultyId,
        });
      }
    });
  }

  @override
  Future<void> saveLanguage(AppLanguage language) async {
    final db = await _db;
    await db.insert('app_settings', {
      'key': 'language',
      'value': language.code,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {
    final db = await _db;
    await db.insert('app_settings', {
      'key': 'theme_mode',
      'value': mode.code,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> saveRemindersEnabled(bool enabled) async =>
      _saveFlag('reminders_enabled', enabled);

  @override
  Future<void> saveShowRoomInSchedule(bool enabled) async =>
      _saveFlag('show_room_in_schedule', enabled);

  @override
  Future<void> saveHighlightCurrentDay(bool enabled) async =>
      _saveFlag('highlight_current_day', enabled);

  Future<void> _saveFlag(String key, bool value) async {
    final db = await _db;
    await db.insert('app_settings', {
      'key': key,
      'value': value ? '1' : '0',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> _readFlag(Database db, String key) async {
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? true : rows.single['value'] == '1';
  }

  @override
  Future<void> saveLessonStyle(LessonStyleSettings style) async {
    final db = await _db;
    await db.transaction((transaction) async {
      await transaction.insert('app_settings', {
        'key': 'lecture_color',
        'value': '${style.lectureColorValue}',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await transaction.insert('app_settings', {
        'key': 'seminar_color',
        'value': '${style.seminarColorValue}',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<void> saveLessonPresentation(Lesson lesson) async {
    final db = await _db;
    await db.insert('lesson_preferences', {
      'lesson_id': lesson.id,
      'priority': lesson.priority.index,
      'color_value': lesson.customColorValue,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> saveExam(Exam exam) async {
    final db = await _db;
    await db.insert('exams', {
      'id': exam.id,
      'title': exam.title,
      'subject_id': exam.subjectId,
      'faculty_id': exam.facultyId,
      'scheduled_at': exam.scheduledAt.toIso8601String(),
      'location': exam.location,
      'notes': exam.notes,
      'created_at': exam.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteExam(String examId) async {
    final db = await _db;
    await db.delete('exams', where: 'id = ?', whereArgs: [examId]);
  }

  @override
  Future<void> saveExamPeriod(ExamPeriod period) async {
    final db = await _db;
    await db.insert('exam_periods', {
      'faculty_id': period.facultyId,
      'start_date': _date(period.startDate),
      'end_date': _date(period.endDate),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> saveSubjectNotes(String subjectId, String notes) async {
    final db = await _db;
    await db.update(
      'subjects',
      {'notes': notes},
      where: 'id = ?',
      whereArgs: [subjectId],
    );
  }

  @override
  Future<void> deleteSubject(String subjectId) async {
    final db = await _db;
    await db.transaction((transaction) async {
      await transaction.delete(
        'lesson_preferences',
        where: 'lesson_id IN (SELECT id FROM lessons WHERE subject_key = ?)',
        whereArgs: [subjectId],
      );
      await transaction.delete(
        'lessons',
        where: 'subject_key = ?',
        whereArgs: [subjectId],
      );
      await transaction.delete(
        'timetable_subjects',
        where: 'subject_id = ?',
        whereArgs: [subjectId],
      );
      await transaction.delete(
        'subjects',
        where: 'id = ?',
        whereArgs: [subjectId],
      );
      await transaction.update(
        'tasks',
        {'subject_id': null},
        where: 'subject_id = ?',
        whereArgs: [subjectId],
      );
      await transaction.update(
        'exams',
        {'subject_id': null},
        where: 'subject_id = ?',
        whereArgs: [subjectId],
      );
    });
  }

  @override
  Future<void> saveTask(PlannerTask task) async {
    final db = await _db;
    await db.insert(
      'tasks',
      _taskToRow(task),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteTask(String taskId) async {
    final db = await _db;
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  Future<List<Subject>> _readSubjects(Database db, String timetableId) async {
    final rows = await db.rawQuery(
      '''
      SELECT subjects.* FROM subjects
      INNER JOIN timetable_subjects ON timetable_subjects.subject_id = subjects.id
      WHERE timetable_subjects.timetable_id = ? ORDER BY course_code
    ''',
      [timetableId],
    );
    return rows
        .map(
          (row) => Subject(
            id: row['id']! as String,
            courseCode: row['course_code']! as String,
            name: row['name']! as String,
            subjectId: row['subject_id'] as String?,
            faculty: row['faculty'] as String?,
            notes: row['notes']! as String,
          ),
        )
        .toList();
  }

  Future<List<PlannerTask>> _readTasks(Database db) async {
    final rows = await db.query(
      'tasks',
      orderBy: 'completed, due_date, due_minute',
    );
    return rows.map(_taskFromRow).toList();
  }

  Map<String, Object?> _lessonToRow(Lesson lesson, String timetableId) => {
    'id': lesson.id,
    'timetable_id': timetableId,
    'date': _date(lesson.date),
    'start_at': lesson.startTime.toIso8601String(),
    'end_at': lesson.endTime.toIso8601String(),
    'subject_key': lesson.subjectKey,
    'course_code': lesson.courseCode,
    'course_name': lesson.courseName,
    'subject_id': lesson.subjectId,
    'faculty': lesson.faculty,
    'timetable_faculty_id': lesson.timetableFacultyId,
    'semester': lesson.semester,
    'seminar_group': lesson.seminarGroup,
    'lesson_kind': lesson.kind.index,
    'rooms': jsonEncode(
      lesson.rooms.map((room) => {'id': room.id, 'name': room.name}).toList(),
    ),
    'teachers': jsonEncode(
      lesson.teachers
          .map((teacher) => {'id': teacher.id, 'name': teacher.name})
          .toList(),
    ),
  };

  Lesson _lessonFromRow(
    Map<String, Object?> row,
    _LessonPreference? preference,
  ) {
    final rooms = (jsonDecode(row['rooms']! as String) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (room) =>
              Room(id: room['id'] as String?, name: room['name']! as String),
        )
        .toList();
    final teachers = (jsonDecode(row['teachers']! as String) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (teacher) => Teacher(
            id: teacher['id'] as String?,
            name: teacher['name']! as String,
          ),
        )
        .toList();
    return Lesson(
      id: row['id']! as String,
      date: DateTime.parse(row['date']! as String),
      startTime: DateTime.parse(row['start_at']! as String),
      endTime: DateTime.parse(row['end_at']! as String),
      subjectKey: row['subject_key']! as String,
      courseCode: row['course_code']! as String,
      courseName: row['course_name']! as String,
      subjectId: row['subject_id'] as String?,
      faculty: row['faculty'] as String?,
      timetableFacultyId: row['timetable_faculty_id'] as String?,
      semester: row['semester'] as String?,
      seminarGroup: row['seminar_group'] as String?,
      kind: LessonKind.values[row['lesson_kind'] as int? ?? 0],
      priority:
          preference?.priority ??
          ((row['lesson_kind'] as int? ?? 0) == LessonKind.seminar.index
              ? LessonPriority.high
              : LessonPriority.normal),
      customColorValue: preference?.colorValue,
      rooms: rooms,
      teachers: teachers,
    );
  }

  Map<String, Object?> _taskToRow(PlannerTask task) => {
    'id': task.id,
    'title': task.title,
    'description': task.description,
    'subject_id': task.subjectId,
    'due_date': _date(task.dueDate),
    'due_minute': task.dueMinute,
    'reminder_at': task.reminderAt?.toIso8601String(),
    'priority': task.priority.index,
    'completed': task.isCompleted ? 1 : 0,
    'created_at': task.createdAt.toIso8601String(),
    'updated_at': task.updatedAt.toIso8601String(),
  };

  PlannerTask _taskFromRow(Map<String, Object?> row) => PlannerTask(
    id: row['id']! as String,
    title: row['title']! as String,
    description: row['description']! as String,
    subjectId: row['subject_id'] as String?,
    dueDate: DateTime.parse(row['due_date']! as String),
    dueMinute: row['due_minute'] as int?,
    reminderAt: row['reminder_at'] == null
        ? null
        : DateTime.parse(row['reminder_at']! as String),
    priority: TaskPriority.values[row['priority']! as int],
    isCompleted: (row['completed']! as int) == 1,
    createdAt: DateTime.parse(row['created_at']! as String),
    updatedAt: DateTime.parse(row['updated_at']! as String),
  );

  Future<LessonStyleSettings> _readLessonStyle(Database db) async {
    final rows = await db.query(
      'app_settings',
      where: 'key IN (?, ?)',
      whereArgs: ['lecture_color', 'seminar_color'],
    );
    final values = {
      for (final row in rows)
        row['key']! as String: int.tryParse(row['value']! as String),
    };
    return LessonStyleSettings(
      lectureColorValue: values['lecture_color'] ?? 0xff2563eb,
      seminarColorValue: values['seminar_color'] ?? 0xffd04a02,
    );
  }

  Future<Map<String, _LessonPreference>> _readLessonPreferences(
    Database db,
  ) async {
    final rows = await db.query('lesson_preferences');
    return {
      for (final row in rows)
        row['lesson_id']! as String: _LessonPreference(
          priority: LessonPriority.values[row['priority']! as int],
          colorValue: row['color_value'] as int?,
        ),
    };
  }

  Future<List<Exam>> _readExams(Database db) async {
    final rows = await db.query('exams', orderBy: 'scheduled_at');
    return rows
        .map(
          (row) => Exam(
            id: row['id']! as String,
            title: row['title']! as String,
            subjectId: row['subject_id'] as String?,
            facultyId: row['faculty_id']! as String,
            scheduledAt: DateTime.parse(row['scheduled_at']! as String),
            location: row['location']! as String,
            notes: row['notes']! as String,
            createdAt: DateTime.parse(row['created_at']! as String),
          ),
        )
        .toList();
  }

  Future<List<ExamPeriod>> _readExamPeriods(Database db) async {
    final rows = await db.query('exam_periods', orderBy: 'start_date');
    return rows
        .map(
          (row) => ExamPeriod(
            facultyId: row['faculty_id']! as String,
            startDate: DateTime.parse(row['start_date']! as String),
            endDate: DateTime.parse(row['end_date']! as String),
          ),
        )
        .toList();
  }

  Future<void> _createExamTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE exam_periods (
        faculty_id TEXT PRIMARY KEY, start_date TEXT NOT NULL, end_date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE exams (
        id TEXT PRIMARY KEY, title TEXT NOT NULL, subject_id TEXT, faculty_id TEXT NOT NULL,
        scheduled_at TEXT NOT NULL, location TEXT NOT NULL, notes TEXT NOT NULL, created_at TEXT NOT NULL
      )
    ''');
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _LessonPreference {
  const _LessonPreference({required this.priority, required this.colorValue});

  final LessonPriority priority;
  final int? colorValue;
}
