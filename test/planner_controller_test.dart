import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muni_timetable/data/repositories/planner_repository.dart';
import 'package:muni_timetable/domain/entities/planner_task.dart';
import 'package:muni_timetable/domain/entities/faculty.dart';
import 'package:muni_timetable/domain/entities/app_language.dart';
import 'package:muni_timetable/domain/entities/app_theme_mode.dart';
import 'package:muni_timetable/domain/entities/exam.dart';
import 'package:muni_timetable/domain/entities/important_date.dart';
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
      await controller.saveColorTheme(AppColorTheme.emerald);
      expect(repository.data.colorTheme, AppColorTheme.emerald);
      await controller.saveAnalyticsConsent(true);
      expect(repository.data.analyticsConsent, isTrue);
      await controller.saveLessonStyle(
        const LessonStyleSettings(
          lectureColorValue: 0xff0f766e,
          seminarColorValue: 0xffbe123c,
          examColorValue: 0xff7e22ce,
          importantDateColorValue: 0xff2563eb,
          examPeriodColorValue: 0xffc2410c,
        ),
      );
      expect(repository.data.lessonStyle.lectureColorValue, 0xff0f766e);
      expect(repository.data.lessonStyle.seminarColorValue, 0xffbe123c);
      expect(repository.data.lessonStyle.examColorValue, 0xff7e22ce);

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

      final registration = controller.newImportantDate(
        title: 'Course registration opens',
        date: DateTime(2026, 11, 1),
        timeMinute: 9 * 60,
        reminderAt: DateTime(2026, 10, 31, 9),
        facultyId: null,
      );
      await controller.saveImportantDate(registration);
      expect(repository.data.importantDates.single.title, registration.title);
      expect(repository.data.importantDates.single.timeMinute, 9 * 60);
      await controller.deleteImportantDate(registration.id);
      expect(repository.data.importantDates, isEmpty);

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

  test('manual seminar is added to the selected timetable', () async {
    final repository = _FakeRepository();
    final scheduler = _FakeScheduler();
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
        reminderSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
    addTearDown(container.dispose);
    await container.read(plannerProvider.future);

    await container
        .read(plannerProvider.notifier)
        .addManualLesson(
          timetableId: timetable.id,
          existingSubjectId: null,
          kind: LessonKind.seminar,
          courseCode: 'PB151',
          courseName: 'Computer Systems',
          seminarGroup: '02',
          startTime: DateTime(2026, 9, 21, 10),
          endTime: DateTime(2026, 9, 21, 11, 40),
          room: 'A318',
          teacher: 'Ada Lovelace',
        );

    final result = container.read(plannerProvider).requireValue;
    final lesson = result.timetables.single.lessons.single;
    expect(lesson.kind, LessonKind.seminar);
    expect(lesson.seminarGroup, '02');
    expect(lesson.rooms.single.name, 'A318');
    expect(lesson.teachers.single.name, 'Ada Lovelace');
    expect(result.timetable!.lessons.single.id, lesson.id);
    expect(result.subjects.single.courseCode, 'PB151');

    final reminderAt = DateTime(2026, 9, 21, 9, 45);
    await container
        .read(plannerProvider.notifier)
        .saveLessonPresentation(
          lesson.copyWithPresentation(reminderAt: reminderAt),
        );
    expect(
      repository.data.timetables.single.lessons.single.reminderAt,
      reminderAt,
    );
    expect(scheduler.lessonReminders.single.id, lesson.id);
  });

  test('manual class can reuse an existing subject', () async {
    final repository = _FakeRepository();
    final timetable = Timetable(
      id: 'fall-2026-fi',
      name: 'Fall 2026',
      assignedFacultyId: 'fi',
      semester: 'Fall 2026',
      importedAt: DateTime(2026, 9, 1),
      lessons: const [],
      subjects: repository.data.subjects,
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

    await container
        .read(plannerProvider.notifier)
        .addManualLesson(
          timetableId: timetable.id,
          existingSubjectId: '1726907',
          kind: LessonKind.lecture,
          courseCode: '',
          courseName: '',
          seminarGroup: null,
          startTime: DateTime(2026, 9, 22, 8),
          endTime: DateTime(2026, 9, 22, 9, 40),
          room: '',
          teacher: '',
        );

    final lesson = container
        .read(plannerProvider)
        .requireValue
        .timetables
        .single
        .lessons
        .single;
    expect(lesson.subjectKey, '1726907');
    expect(lesson.subjectId, '1726907');
    expect(lesson.courseCode, 'PB151');
    expect(lesson.courseName, 'Výpočetní systémy');
  });

  test('merging the same XML twice does not duplicate classes', () async {
    final repository = _FakeRepository();
    final timetable = Timetable(
      id: 'fall-2026-fi',
      name: 'Fall 2026',
      assignedFacultyId: 'fi',
      semester: 'podzim2026',
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
    const xml = '''
<rozvrh><tabulka><den id="Po 14. 9."><radek>
<slot odcas="09:00" docas="10:00"><akce><kod>IB111</kod><nazev>Základy programování</nazev><predmetid>1726815</predmetid><fakulta_url>fi</fakulta_url><obdobi_url>podzim2026</obdobi_url></akce></slot>
</radek></den></tabulka></rozvrh>
''';
    final controller = container.read(plannerProvider.notifier);

    await controller.importXml(xml, 'fi', mergeIntoTimetableId: timetable.id);
    await controller.importXml(xml, 'fi', mergeIntoTimetableId: timetable.id);

    final result = container.read(plannerProvider).requireValue;
    expect(result.timetables.single.lessons, hasLength(1));
    expect(result.timetables.single.subjects, hasLength(1));
    expect(result.timetables.single.lessons.single.courseCode, 'IB111');
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
  Future<void> mergeTimetable(String timetableId, Timetable imported) async {
    data = data.withTimetables(
      data.timetables.map((timetable) {
        if (timetable.id != timetableId) return timetable;
        final signatures = timetable.lessons.map(_lessonSignature).toSet();
        return Timetable(
          id: timetable.id,
          name: timetable.name,
          assignedFacultyId: timetable.assignedFacultyId,
          semester: timetable.semester,
          importedAt: timetable.importedAt,
          lessons: [
            ...timetable.lessons,
            ...imported.lessons.where(
              (lesson) => signatures.add(_lessonSignature(lesson)),
            ),
          ],
          subjects: [
            ...timetable.subjects,
            ...imported.subjects.where(
              (subject) => !timetable.subjects.any(
                (existing) => existing.id == subject.id,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Future<void> addLesson(
    String timetableId,
    Lesson lesson,
    Subject subject,
  ) async {
    data = data.withTimetables(
      data.timetables
          .map(
            (timetable) => timetable.id == timetableId
                ? Timetable(
                    id: timetable.id,
                    name: timetable.name,
                    assignedFacultyId: timetable.assignedFacultyId,
                    semester: timetable.semester,
                    importedAt: timetable.importedAt,
                    lessons: [...timetable.lessons, lesson],
                    subjects: [
                      ...timetable.subjects.where(
                        (item) => item.id != subject.id,
                      ),
                      subject,
                    ],
                  )
                : timetable,
          )
          .toList(),
    );
  }

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
  Future<void> saveColorTheme(AppColorTheme theme) async =>
      data = _copy(colorTheme: theme);

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
  Future<void> saveAnalyticsConsent(bool enabled) async =>
      data = _copy(analyticsConsent: enabled);

  @override
  Future<void> saveLessonStyle(LessonStyleSettings style) async {
    await lessonStyleSaveCompleter?.future;
    data = _copy(lessonStyle: style);
  }

  @override
  Future<void> saveLessonPresentation(Lesson lesson) async {
    data = data.withTimetables(
      data.timetables
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
          .toList(),
    );
  }

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
  Future<void> saveImportantDate(ImportantDate importantDate) async =>
      data = _copy(
        importantDates: [
          ...data.importantDates.where((item) => item.id != importantDate.id),
          importantDate,
        ],
      );

  @override
  Future<void> deleteImportantDate(String importantDateId) async =>
      data = _copy(
        importantDates: data.importantDates
            .where((item) => item.id != importantDateId)
            .toList(),
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
    List<ImportantDate>? importantDates,
    LessonStyleSettings? lessonStyle,
    AppThemeMode? themeMode,
    AppColorTheme? colorTheme,
    bool? remindersEnabled,
    bool? showRoomInSchedule,
    bool? highlightCurrentDay,
    bool? analyticsConsent,
  }) => PlannerData(
    timetable: data.timetable,
    timetables: data.timetables,
    faculties: data.faculties,
    language: data.language,
    subjects: data.subjects,
    tasks: data.tasks,
    exams: exams ?? data.exams,
    examPeriods: examPeriods ?? data.examPeriods,
    importantDates: importantDates ?? data.importantDates,
    lessonStyle: lessonStyle ?? data.lessonStyle,
    themeMode: themeMode ?? data.themeMode,
    colorTheme: colorTheme ?? data.colorTheme,
    remindersEnabled: remindersEnabled ?? data.remindersEnabled,
    showRoomInSchedule: showRoomInSchedule ?? data.showRoomInSchedule,
    highlightCurrentDay: highlightCurrentDay ?? data.highlightCurrentDay,
    analyticsConsent: analyticsConsent ?? data.analyticsConsent,
  );

  String _lessonSignature(Lesson lesson) => [
    lesson.startTime.toIso8601String(),
    lesson.endTime.toIso8601String(),
    lesson.subjectKey,
    lesson.rooms.map((room) => room.id ?? room.name).join('|'),
  ].join('#');
}

class _FakeScheduler implements ReminderScheduler {
  final scheduled = <PlannerTask>[];
  final cancelled = <String>[];
  final importantDates = <ImportantDate>[];
  final cancelledImportantDates = <String>[];
  final lessonReminders = <Lesson>[];
  final cancelledLessonReminders = <String>[];

  @override
  Future<void> cancel(String taskId) async => cancelled.add(taskId);

  @override
  Future<void> initialize() async {}

  @override
  Future<void> schedule(PlannerTask task) async => scheduled.add(task);

  @override
  Future<void> scheduleImportantDate(ImportantDate importantDate) async =>
      importantDates.add(importantDate);

  @override
  Future<void> cancelImportantDate(String importantDateId) async =>
      cancelledImportantDates.add(importantDateId);

  @override
  Future<void> scheduleLesson(Lesson lesson) async =>
      lessonReminders.add(lesson);

  @override
  Future<void> cancelLesson(String lessonId) async =>
      cancelledLessonReminders.add(lessonId);
}
