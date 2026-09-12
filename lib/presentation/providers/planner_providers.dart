import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/planner_database.dart';
import '../../data/parsers/muni_timetable_parser.dart';
import '../../data/repositories/planner_repository.dart';
import '../../domain/entities/planner_task.dart';
import '../../domain/entities/timetable.dart';
import '../../domain/entities/faculty.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/entities/exam.dart';
import '../../domain/entities/important_date.dart';
import '../../services/home_widget_service.dart';
import '../../services/notification_service.dart';

final plannerRepositoryProvider = Provider<PlannerRepository>(
  (ref) => SqlitePlannerRepository(),
);
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => LocalReminderScheduler(),
);
final plannerProvider = AsyncNotifierProvider<PlannerController, PlannerData>(
  PlannerController.new,
);

class PlannerController extends AsyncNotifier<PlannerData> {
  final _parser = MuniTimetableParser();
  final _uuid = const Uuid();

  PlannerRepository get _repository => ref.read(plannerRepositoryProvider);
  ReminderScheduler get _scheduler => ref.read(reminderSchedulerProvider);

  @override
  Future<PlannerData> build() async {
    try {
      await _scheduler.initialize();
    } catch (_) {
      // The planner remains usable if a platform has no notification support.
    }
    final data = await _repository.load();
    if (data.remindersEnabled) {
      for (final importantDate in data.importantDates) {
        unawaited(_scheduler.scheduleImportantDate(importantDate));
      }
    }
    unawaited(updateScheduleWidget(data));
    return data;
  }

  Future<PlannerData> importXml(
    String xml,
    String facultyId, {
    String? mergeIntoTimetableId,
  }) async {
    final timetable = _parser.parse(xml, assignedFacultyId: facultyId);
    if (mergeIntoTimetableId == null) {
      await _repository.saveTimetable(timetable, facultyId);
    } else {
      await _repository.mergeTimetable(mergeIntoTimetableId, timetable);
    }
    return _refresh();
  }

  Future<void> addManualLesson({
    required String timetableId,
    required String? existingSubjectId,
    required LessonKind kind,
    required String courseCode,
    required String courseName,
    required String? seminarGroup,
    required DateTime startTime,
    required DateTime endTime,
    required String room,
    required String teacher,
  }) async {
    final timetable = _currentData.timetables.firstWhere(
      (item) => item.id == timetableId,
    );
    final facultyId = timetable.assignedFacultyId;
    final existingSubject = existingSubjectId == null
        ? null
        : timetable.subjects.firstWhere((item) => item.id == existingSubjectId);
    final normalizedCode =
        existingSubject?.courseCode ??
        (courseCode.trim().isEmpty ? courseName.trim() : courseCode.trim());
    final subjectKey =
        existingSubject?.id ??
        'manual:$timetableId:${normalizedCode.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}';
    final subject =
        existingSubject ??
        Subject(
          id: subjectKey,
          courseCode: normalizedCode,
          name: courseName.trim(),
          subjectId: null,
          faculty: facultyId,
        );
    final lesson = Lesson(
      id: _uuid.v4(),
      date: DateTime(startTime.year, startTime.month, startTime.day),
      startTime: startTime,
      endTime: endTime,
      subjectKey: subjectKey,
      courseCode: normalizedCode,
      seminarGroup:
          kind == LessonKind.seminar && seminarGroup?.trim().isNotEmpty == true
          ? seminarGroup!.trim()
          : null,
      kind: kind,
      priority: kind == LessonKind.seminar
          ? LessonPriority.high
          : LessonPriority.normal,
      customColorValue: null,
      courseName: subject.name,
      subjectId: subject.subjectId,
      faculty: subject.faculty ?? facultyId,
      timetableFacultyId: facultyId,
      semester: timetable.semester,
      rooms: room.trim().isEmpty
          ? const []
          : [Room(id: null, name: room.trim())],
      teachers: teacher.trim().isEmpty
          ? const []
          : [Teacher(id: null, name: teacher.trim())],
    );
    await _repository.addLesson(timetableId, lesson, subject);
    await _refresh();
  }

  Future<void> deleteTimetables(List<String> timetableIds) async {
    if (timetableIds.isEmpty) {
      return;
    }
    final removedIds = timetableIds.toSet();
    _publish(
      _currentData.withTimetables(
        _currentData.timetables
            .where((timetable) => !removedIds.contains(timetable.id))
            .toList(),
      ),
    );
    await _repository.deleteTimetables(timetableIds);
    await _refresh();
  }

  Future<void> renameTimetable(String timetableId, String name) async {
    _publish(
      _currentData.withTimetables(
        _currentData.timetables
            .map(
              (timetable) => timetable.id == timetableId
                  ? timetable.copyWith(name: name)
                  : timetable,
            )
            .toList(),
      ),
    );
    await _repository.renameTimetable(timetableId, name);
    await _refresh();
  }

  Future<void> saveFacultyMemberships(List<String> facultyIds) async {
    _publish(
      _currentData.copyWith(
        faculties: MuniFaculties.all
            .where((faculty) => facultyIds.contains(faculty.id))
            .toList(),
      ),
    );
    await _repository.saveFacultyMemberships(facultyIds);
    await _refresh();
  }

  Future<void> saveLanguage(AppLanguage language) async {
    _publish(_currentData.copyWith(language: language));
    await _repository.saveLanguage(language);
    await _refresh();
  }

  Future<void> saveThemeMode(AppThemeMode mode) async {
    _publish(_currentData.copyWith(themeMode: mode));
    await _repository.saveThemeMode(mode);
    await _refresh();
  }

  Future<void> saveRemindersEnabled(bool enabled) async {
    _publish(_currentData.copyWith(remindersEnabled: enabled));
    await _repository.saveRemindersEnabled(enabled);
    await _refresh();
  }

  Future<void> saveShowRoomInSchedule(bool enabled) async {
    _publish(_currentData.copyWith(showRoomInSchedule: enabled));
    await _repository.saveShowRoomInSchedule(enabled);
    await _refresh();
  }

  Future<void> saveHighlightCurrentDay(bool enabled) async {
    _publish(_currentData.copyWith(highlightCurrentDay: enabled));
    await _repository.saveHighlightCurrentDay(enabled);
    await _refresh();
  }

  Future<void> saveLessonStyle(LessonStyleSettings style) async {
    _publish(_currentData.copyWith(lessonStyle: style));
    await _repository.saveLessonStyle(style);
    await _refresh();
  }

  Future<void> saveLessonPresentation(Lesson lesson) async {
    _publish(_withLessonPresentation(_currentData, lesson));
    await _repository.saveLessonPresentation(lesson);
    await _refresh();
  }

  Exam newExam({
    required String title,
    required String? subjectId,
    required String facultyId,
    required DateTime scheduledAt,
    required String location,
    required String notes,
  }) => Exam(
    id: _uuid.v4(),
    title: title,
    subjectId: subjectId,
    facultyId: facultyId,
    scheduledAt: scheduledAt,
    location: location,
    notes: notes,
    createdAt: DateTime.now(),
  );

  Future<void> saveExam(Exam exam) async {
    _publish(
      _currentData.copyWith(
        exams: [
          ..._currentData.exams.where((item) => item.id != exam.id),
          exam,
        ],
      ),
    );
    await _repository.saveExam(exam);
    await _refresh();
  }

  Future<void> deleteExam(String examId) async {
    _publish(
      _currentData.copyWith(
        exams: _currentData.exams.where((exam) => exam.id != examId).toList(),
      ),
    );
    await _repository.deleteExam(examId);
    await _refresh();
  }

  Future<void> saveExamPeriod(ExamPeriod period) async {
    _publish(
      _currentData.copyWith(
        examPeriods: [
          ..._currentData.examPeriods.where(
            (item) => item.facultyId != period.facultyId,
          ),
          period,
        ],
      ),
    );
    await _repository.saveExamPeriod(period);
    await _refresh();
  }

  ImportantDate newImportantDate({
    required String title,
    required DateTime date,
    required int? timeMinute,
    required DateTime? reminderAt,
    required String? facultyId,
  }) => ImportantDate(
    id: _uuid.v4(),
    title: title,
    date: DateTime(date.year, date.month, date.day),
    timeMinute: timeMinute,
    reminderAt: reminderAt,
    facultyId: facultyId,
    createdAt: DateTime.now(),
  );

  Future<void> saveImportantDate(ImportantDate importantDate) async {
    _publish(
      _currentData.copyWith(
        importantDates: [
          ..._currentData.importantDates.where(
            (item) => item.id != importantDate.id,
          ),
          importantDate,
        ],
      ),
    );
    await _repository.saveImportantDate(importantDate);
    if (_currentData.remindersEnabled) {
      await _scheduler.scheduleImportantDate(importantDate);
    } else {
      await _scheduler.cancelImportantDate(importantDate.id);
    }
    await _refresh();
  }

  Future<void> deleteImportantDate(String importantDateId) async {
    _publish(
      _currentData.copyWith(
        importantDates: _currentData.importantDates
            .where((item) => item.id != importantDateId)
            .toList(),
      ),
    );
    await _scheduler.cancelImportantDate(importantDateId);
    await _repository.deleteImportantDate(importantDateId);
    await _refresh();
  }

  Future<void> saveSubjectNotes(String subjectId, String notes) async {
    _publish(
      _currentData.copyWith(
        subjects: _currentData.subjects
            .map(
              (subject) => subject.id == subjectId
                  ? subject.copyWith(notes: notes)
                  : subject,
            )
            .toList(),
      ),
    );
    await _repository.saveSubjectNotes(subjectId, notes);
    await _refresh();
  }

  Future<void> deleteSubject(String subjectId) async {
    final data = _currentData;
    final timetables = data.timetables
        .map(
          (timetable) => Timetable(
            id: timetable.id,
            name: timetable.name,
            assignedFacultyId: timetable.assignedFacultyId,
            semester: timetable.semester,
            importedAt: timetable.importedAt,
            lessons: timetable.lessons
                .where((lesson) => lesson.subjectKey != subjectId)
                .toList(),
            subjects: timetable.subjects
                .where((subject) => subject.id != subjectId)
                .toList(),
          ),
        )
        .toList();
    _publish(
      data
          .withTimetables(timetables)
          .copyWith(
            tasks: data.tasks
                .map(
                  (task) => task.subjectId == subjectId
                      ? task.copyWith(
                          clearSubject: true,
                          updatedAt: DateTime.now(),
                        )
                      : task,
                )
                .toList(),
            exams: data.exams
                .map(
                  (exam) => exam.subjectId == subjectId
                      ? exam.copyWith(clearSubject: true)
                      : exam,
                )
                .toList(),
          ),
    );
    await _repository.deleteSubject(subjectId);
    await _refresh();
  }

  Future<void> saveTask(PlannerTask task) async {
    _publish(
      _currentData.copyWith(
        tasks: [
          ..._currentData.tasks.where((item) => item.id != task.id),
          task,
        ],
      ),
    );
    await _repository.saveTask(task);
    if (_currentData.remindersEnabled) {
      await _scheduler.schedule(task);
    } else {
      await _scheduler.cancel(task.id);
    }
    await _refresh();
  }

  Future<void> toggleTask(PlannerTask task) => saveTask(
    task.copyWith(isCompleted: !task.isCompleted, updatedAt: DateTime.now()),
  );

  Future<void> deleteTask(String taskId) async {
    _publish(
      _currentData.copyWith(
        tasks: _currentData.tasks.where((task) => task.id != taskId).toList(),
      ),
    );
    await _scheduler.cancel(taskId);
    await _repository.deleteTask(taskId);
    await _refresh();
  }

  PlannerTask newTask({
    required String title,
    required String description,
    required String? subjectId,
    required DateTime dueDate,
    required int? dueMinute,
    required DateTime? reminderAt,
    required TaskPriority priority,
  }) {
    final now = DateTime.now();
    return PlannerTask(
      id: _uuid.v4(),
      title: title,
      description: description,
      subjectId: subjectId,
      dueDate: dueDate,
      dueMinute: dueMinute,
      reminderAt: reminderAt,
      priority: priority,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<PlannerData> _refresh() async {
    final data = await _repository.load();
    state = AsyncData(data);
    unawaited(updateScheduleWidget(data));
    return data;
  }

  PlannerData get _currentData => switch (state) {
    AsyncData(:final value) => value,
    _ => throw StateError('Planner data is not available.'),
  };

  void _publish(PlannerData data) {
    state = AsyncData(data);
    unawaited(updateScheduleWidget(data));
  }

  PlannerData _withLessonPresentation(PlannerData data, Lesson lesson) {
    final timetables = _replaceLesson(data.timetables, lesson);
    final timetable = data.timetable == null
        ? null
        : _replaceLesson([data.timetable!], lesson).single;
    return data.copyWith(timetable: timetable, timetables: timetables);
  }

  List<Timetable> _replaceLesson(List<Timetable> timetables, Lesson lesson) =>
      timetables
          .map(
            (timetable) => Timetable(
              id: timetable.id,
              name: timetable.name,
              assignedFacultyId: timetable.assignedFacultyId,
              semester: timetable.semester,
              importedAt: timetable.importedAt,
              lessons: timetable.lessons
                  .map((item) => item.id == lesson.id ? lesson : item)
                  .toList(),
              subjects: timetable.subjects,
            ),
          )
          .toList();
}
