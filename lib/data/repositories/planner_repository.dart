import '../../domain/entities/planner_task.dart';
import '../../domain/entities/faculty.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/entities/exam.dart';
import '../../domain/entities/important_date.dart';
import '../../domain/entities/timetable.dart';

class PlannerData {
  const PlannerData({
    required this.timetable,
    required this.timetables,
    required this.faculties,
    required this.language,
    this.themeMode = AppThemeMode.system,
    this.lessonStyle = const LessonStyleSettings(),
    this.remindersEnabled = true,
    this.showRoomInSchedule = true,
    this.highlightCurrentDay = true,
    this.exams = const [],
    this.examPeriods = const [],
    List<ImportantDate>? importantDates,
    required this.subjects,
    required this.tasks,
  }) : _importantDates = importantDates ?? const [];

  final Timetable? timetable;
  final List<Timetable> timetables;
  final List<Faculty> faculties;
  final AppLanguage language;
  final AppThemeMode themeMode;
  final LessonStyleSettings lessonStyle;
  final bool remindersEnabled;
  final bool showRoomInSchedule;
  final bool highlightCurrentDay;
  final List<Exam> exams;
  final List<ExamPeriod> examPeriods;
  final List<ImportantDate>? _importantDates;
  List<ImportantDate> get importantDates => _importantDates ?? const [];
  final List<Subject> subjects;
  final List<PlannerTask> tasks;

  PlannerData copyWith({
    Timetable? timetable,
    List<Timetable>? timetables,
    List<Faculty>? faculties,
    AppLanguage? language,
    AppThemeMode? themeMode,
    LessonStyleSettings? lessonStyle,
    bool? remindersEnabled,
    bool? showRoomInSchedule,
    bool? highlightCurrentDay,
    List<Exam>? exams,
    List<ExamPeriod>? examPeriods,
    List<ImportantDate>? importantDates,
    List<Subject>? subjects,
    List<PlannerTask>? tasks,
  }) => PlannerData(
    timetable: timetable ?? this.timetable,
    timetables: timetables ?? this.timetables,
    faculties: faculties ?? this.faculties,
    language: language ?? this.language,
    themeMode: themeMode ?? this.themeMode,
    lessonStyle: lessonStyle ?? this.lessonStyle,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    showRoomInSchedule: showRoomInSchedule ?? this.showRoomInSchedule,
    highlightCurrentDay: highlightCurrentDay ?? this.highlightCurrentDay,
    exams: exams ?? this.exams,
    examPeriods: examPeriods ?? this.examPeriods,
    importantDates: importantDates ?? this.importantDates,
    subjects: subjects ?? this.subjects,
    tasks: tasks ?? this.tasks,
  );

  PlannerData withTimetables(List<Timetable> timetables) {
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
      importantDates: importantDates,
      subjects: subjects,
      tasks: tasks,
    );
  }

  PlannerData forFaculty(String? facultyId) {
    if (facultyId == null) {
      return this;
    }
    final selected = timetables
        .where((timetable) => timetable.assignedFacultyId == facultyId)
        .toList();
    final lessons = selected.expand((timetable) => timetable.lessons).toList()
      ..sort((first, second) => first.startTime.compareTo(second.startTime));
    final subjectsById = <String, Subject>{
      for (final subject in selected.expand((timetable) => timetable.subjects))
        subject.id: subject,
    };
    final selectedSubjects = subjectsById.values.toList()
      ..sort((first, second) => first.courseCode.compareTo(second.courseCode));
    return PlannerData(
      timetable: lessons.isEmpty
          ? null
          : Timetable(
              id: 'faculty-$facultyId',
              name: 'Faculty schedule',
              assignedFacultyId: facultyId,
              semester: null,
              importedAt: DateTime.now(),
              lessons: lessons,
              subjects: selectedSubjects,
            ),
      timetables: selected,
      faculties: faculties,
      language: language,
      themeMode: themeMode,
      lessonStyle: lessonStyle,
      remindersEnabled: remindersEnabled,
      showRoomInSchedule: showRoomInSchedule,
      highlightCurrentDay: highlightCurrentDay,
      exams: exams.where((exam) => exam.facultyId == facultyId).toList(),
      examPeriods: examPeriods
          .where((period) => period.facultyId == facultyId)
          .toList(),
      importantDates: importantDates
          .where(
            (importantDate) =>
                importantDate.facultyId == null ||
                importantDate.facultyId == facultyId,
          )
          .toList(),
      subjects: selectedSubjects,
      tasks: tasks,
    );
  }
}

abstract interface class PlannerRepository {
  Future<PlannerData> load();
  Future<void> saveTimetable(Timetable timetable, String facultyId);
  Future<void> mergeTimetable(String timetableId, Timetable imported);
  Future<void> addLesson(String timetableId, Lesson lesson, Subject subject);
  Future<void> deleteTimetables(List<String> timetableIds);
  Future<void> renameTimetable(String timetableId, String name);
  Future<void> saveFacultyMemberships(List<String> facultyIds);
  Future<void> saveLanguage(AppLanguage language);
  Future<void> saveThemeMode(AppThemeMode mode);
  Future<void> saveLessonStyle(LessonStyleSettings style);
  Future<void> saveRemindersEnabled(bool enabled);
  Future<void> saveShowRoomInSchedule(bool enabled);
  Future<void> saveHighlightCurrentDay(bool enabled);
  Future<void> saveLessonPresentation(Lesson lesson);
  Future<void> saveExam(Exam exam);
  Future<void> deleteExam(String examId);
  Future<void> saveExamPeriod(ExamPeriod period);
  Future<void> saveImportantDate(ImportantDate importantDate);
  Future<void> deleteImportantDate(String importantDateId);
  Future<void> saveSubjectNotes(String subjectId, String notes);
  Future<void> deleteSubject(String subjectId);
  Future<void> saveTask(PlannerTask task);
  Future<void> deleteTask(String taskId);
}
