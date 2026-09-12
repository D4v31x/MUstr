import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muni_timetable/data/repositories/planner_repository.dart';
import 'package:muni_timetable/domain/entities/planner_task.dart';
import 'package:muni_timetable/domain/entities/faculty.dart';
import 'package:muni_timetable/domain/entities/app_language.dart';
import 'package:muni_timetable/domain/entities/app_theme_mode.dart';
import 'package:muni_timetable/domain/entities/exam.dart';
import 'package:muni_timetable/domain/entities/timetable.dart';
import 'package:muni_timetable/presentation/providers/planner_providers.dart';
import 'package:muni_timetable/services/notification_service.dart';

void main() {
  test(
    'tasks retain assignments, completion state, reminders, and subject notes',
    () async {
      final repository = _FakeRepository();
      final scheduler = _FakeScheduler();
      final container = ProviderContainer(
        overrides: [
          plannerRepositoryProvider.overrideWithValue(repository),
          reminderSchedulerProvider.overrideWithValue(scheduler),
        ],
      );
      addTearDown(container.dispose);
      await container.read(plannerProvider.future);
      final controller = container.read(plannerProvider.notifier);

      final task = controller.newTask(
        title: 'Prepare lab report',
        description: 'Bring printed notes',
        subjectId: '1726907',
        dueDate: DateTime(2026, 9, 24),
        dueMinute: 23 * 60 + 59,
        reminderAt: DateTime(2026, 9, 23, 18),
        priority: TaskPriority.high,
      );
      await controller.saveTask(task);
      expect(repository.data.tasks.single.subjectId, '1726907');
      expect(scheduler.scheduled.single.id, task.id);

      await controller.toggleTask(task);
      expect(repository.data.tasks.single.isCompleted, isTrue);
      await controller.saveSubjectNotes('1726907', 'Exam covers chapters 1-5.');
      expect(
        repository.data.subjects.single.notes,
        'Exam covers chapters 1-5.',
      );

      await controller.saveLanguage(AppLanguage.czech);
      expect(repository.data.language, AppLanguage.czech);
      await controller.saveLessonStyle(
        const LessonStyleSettings(
          lectureColorValue: 0xff0f766e,
          seminarColorValue: 0xffbe123c,
        ),
      );
      expect(repository.data.lessonStyle.lectureColorValue, 0xff0f766e);
      expect(repository.data.lessonStyle.seminarColorValue, 0xffbe123c);

      final exam = controller.newExam(
        title: 'Programming final',
        subjectId: '1726907',
        facultyId: 'fi',
        scheduledAt: DateTime(2026, 12, 18, 9),
        location: 'A318',
        notes: 'Bring student card.',
      );
      await controller.saveExam(exam);
      expect(repository.data.exams.single.title, 'Programming final');
      await controller.saveExamPeriod(
        ExamPeriod(
          facultyId: 'fi',
          startDate: DateTime(2026, 12, 14),
          endDate: DateTime(2027, 1, 29),
        ),
      );
      expect(repository.data.examPeriods.single.endDate, DateTime(2027, 1, 29));
      await controller.deleteExam(exam.id);
      expect(repository.data.exams, isEmpty);

      await controller.deleteTask(task.id);
      expect(repository.data.tasks, isEmpty);
      expect(scheduler.cancelled, contains(task.id));
    },
  );

  test('settings updates are published before persistence completes', () async {
    final repository = _FakeRepository()
      ..lessonStyleSaveCompleter = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        plannerRepositoryProvider.overrideWithValue(repository),
        reminderSchedulerProvider.overrideWithValue(_FakeScheduler()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(plannerProvider.future);

    final style = const LessonStyleSettings(
      lectureColorValue: 0xff0f766e,
      seminarColorValue: 0xffbe123c,
    );
    final saving = container
        .read(plannerProvider.notifier)
        .saveLessonStyle(style);

    expect(
      container
          .read(plannerProvider)
          .requireValue
          .lessonStyle
          .lectureColorValue,
      style.lectureColorValue,
    );
    expect(
      repository.data.lessonStyle.lectureColorValue,
      isNot(style.lectureColorValue),
    );
    repository.lessonStyleSaveCompleter!.complete();
    await saving;
  });

  test('selected imported timetables are removed from planner data', () async {
    final repository = _FakeRepository();
    final timetable = Timetable(
      id: 'fall-2026-fi',
      name: 'Fall 2026',
      assignedFacultyId: 'fi',
      semester: 'Fall 2026',
      importedAt: DateTime(2026, 9, 1),
      lessons: const [],
      subjects: const [],
    );
    repository.data = repository.data.withTimetables([timetable]);
    final container = ProviderContainer(
      overrides: [
        plannerRepositoryProvider.overrideWithValue(repository),
        reminderSchedulerProvider.overrideWithValue(_FakeScheduler()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(plannerProvider.future);

    await container.read(plannerProvider.notifier).deleteTimetables([
      timetable.id,
    ]);

    expect(repository.data.timetables, isEmpty);
    expect(container.read(plannerProvider).requireValue.timetables, isEmpty);
  });

  test('deleting a subject retains its tasks as unassigned', () async {
    final repository = _FakeRepository();
    final task = PlannerTask(
      id: 'task-1',
      title: 'Review notes',
      description: '',
      subjectId: '1726907',
      dueDate: DateTime(2026, 9, 20),
      dueMinute: null,
      reminderAt: null,
      priority: TaskPriority.normal,
      isCompleted: false,
      createdAt: DateTime(2026, 9, 11),
      updatedAt: DateTime(2026, 9, 11),
    );
    repository.data = repository.data.copyWith(tasks: [task]);
    final container = ProviderContainer(
      overrides: [
        plannerRepositoryProvider.overrideWithValue(repository),
        reminderSchedulerProvider.overrideWithValue(_FakeScheduler()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(plannerProvider.future);

    await container.read(plannerProvider.notifier).deleteSubject('1726907');

    final result = container.read(plannerProvider).requireValue;
    expect(result.subjects, isEmpty);
    expect(result.tasks.single.subjectId, isNull);
  });
}

class _FakeRepository implements PlannerRepository {
  Completer<void>? lessonStyleSaveCompleter;

  PlannerData data = PlannerData(
    timetable: null,
    timetables: const [],
    faculties: const [
      Faculty(
        id: 'fi',
        name: 'Faculty of Informatics',
        nameEn: 'Faculty of Informatics',
        nameSk: 'Fakulta informatiky',
        shortName: 'FI',
        color: Color(0xff0073b5),
      ),
    ],
    language: AppLanguage.english,
    subjects: const [
      Subject(
        id: '1726907',
        courseCode: 'PB151',
        name: 'Výpočetní systémy',
        subjectId: '1726907',
        faculty: 'fi',
      ),
    ],
    tasks: const [],
  );

  @override
  Future<void> deleteTask(String taskId) async => data = PlannerData(
    timetable: data.timetable,
    timetables: data.timetables,
    faculties: data.faculties,
    language: data.language,
    subjects: data.subjects,
    tasks: data.tasks.where((task) => task.id != taskId).toList(),
  );

  @override
  Future<void> deleteExam(String examId) async => data = _copy(
    exams: data.exams.where((exam) => exam.id != examId).toList(),
  );

  @override
  Future<PlannerData> load() async => data;

  @override
  Future<void> saveTimetable(Timetable timetable, String facultyId) async =>
      data = PlannerData(
        timetable: timetable,
        timetables: [...data.timetables, timetable],
        faculties: data.faculties,
        language: data.language,
        subjects: timetable.subjects,
        tasks: data.tasks,
      );

  @override
  Future<void> deleteTimetables(List<String> timetableIds) async =>
      data = data.withTimetables(
        data.timetables
            .where((timetable) => !timetableIds.contains(timetable.id))
            .toList(),
      );

  @override
  Future<void> renameTimetable(String timetableId, String name) async =>
      data = data.withTimetables(
        data.timetables
            .map(
              (timetable) => timetable.id == timetableId
                  ? timetable.copyWith(name: name)
                  : timetable,
            )
            .toList(),
      );

  @override
  Future<void> saveFacultyMemberships(List<String> facultyIds) async =>
      data = PlannerData(
        timetable: data.timetable,
        timetables: data.timetables,
        faculties: MuniFaculties.all
            .where((faculty) => facultyIds.contains(faculty.id))
            .toList(),
        language: data.language,
        subjects: data.subjects,
        tasks: data.tasks,
      );

  @override
  Future<void> saveLanguage(AppLanguage language) async => data = PlannerData(
    timetable: data.timetable,
    timetables: data.timetables,
    faculties: data.faculties,
    language: language,
    subjects: data.subjects,
    tasks: data.tasks,
  );

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async =>
      data = _copy(themeMode: mode);

  @override
  Future<void> saveRemindersEnabled(bool enabled) async =>
      data = _copy(remindersEnabled: enabled);

  @override
  Future<void> saveShowRoomInSchedule(bool enabled) async =>
      data = _copy(showRoomInSchedule: enabled);

  @override
  Future<void> saveHighlightCurrentDay(bool enabled) async =>
      data = _copy(highlightCurrentDay: enabled);

  @override
  Future<void> saveLessonStyle(LessonStyleSettings style) async {
    await lessonStyleSaveCompleter?.future;
    data = _copy(lessonStyle: style);
  }

  @override
  Future<void> saveLessonPresentation(Lesson lesson) async {}

  @override
  Future<void> saveExam(Exam exam) async => data = _copy(
    exams: [...data.exams.where((item) => item.id != exam.id), exam],
  );

  @override
  Future<void> saveExamPeriod(ExamPeriod period) async => data = _copy(
    examPeriods: [
      ...data.examPeriods.where((item) => item.facultyId != period.facultyId),
      period,
    ],
  );

  @override
  Future<void> saveSubjectNotes(String subjectId, String notes) async =>
      data = PlannerData(
        timetable: data.timetable,
        timetables: data.timetables,
        faculties: data.faculties,
        language: data.language,
        subjects: data.subjects
            .map(
              (subject) => subject.id == subjectId
                  ? subject.copyWith(notes: notes)
                  : subject,
            )
            .toList(),
        tasks: data.tasks,
      );

  @override
  Future<void> deleteSubject(String subjectId) async => data = data.copyWith(
    subjects: data.subjects
        .where((subject) => subject.id != subjectId)
        .toList(),
    tasks: data.tasks
        .map(
          (task) => task.subjectId == subjectId
              ? task.copyWith(clearSubject: true)
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
  );

  @override
  Future<void> saveTask(PlannerTask task) async => data = PlannerData(
    timetable: data.timetable,
    timetables: data.timetables,
    faculties: data.faculties,
    language: data.language,
    subjects: data.subjects,
    tasks: [...data.tasks.where((item) => item.id != task.id), task],
  );

  PlannerData _copy({
    List<Exam>? exams,
    List<ExamPeriod>? examPeriods,
    LessonStyleSettings? lessonStyle,
    AppThemeMode? themeMode,
    bool? remindersEnabled,
    bool? showRoomInSchedule,
    bool? highlightCurrentDay,
  }) => PlannerData(
    timetable: data.timetable,
    timetables: data.timetables,
    faculties: data.faculties,
    language: data.language,
    subjects: data.subjects,
    tasks: data.tasks,
    exams: exams ?? data.exams,
    examPeriods: examPeriods ?? data.examPeriods,
    lessonStyle: lessonStyle ?? data.lessonStyle,
    themeMode: themeMode ?? data.themeMode,
    remindersEnabled: remindersEnabled ?? data.remindersEnabled,
    showRoomInSchedule: showRoomInSchedule ?? data.showRoomInSchedule,
    highlightCurrentDay: highlightCurrentDay ?? data.highlightCurrentDay,
  );
}

class _FakeScheduler implements ReminderScheduler {
  final scheduled = <PlannerTask>[];
  final cancelled = <String>[];

  @override
  Future<void> cancel(String taskId) async => cancelled.add(taskId);

  @override
  Future<void> initialize() async {}

  @override
  Future<void> schedule(PlannerTask task) async => scheduled.add(task);
}
