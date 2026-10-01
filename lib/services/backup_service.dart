import 'dart:convert';
import 'dart:typed_data';

import '../data/repositories/planner_repository.dart';
import '../domain/entities/exam.dart';
import '../domain/entities/important_date.dart';
import '../domain/entities/planner_task.dart';
import '../domain/entities/timetable.dart';

class BackupService {
  const BackupService();

  Uint8List createBytes(PlannerData data, {DateTime? createdAt}) =>
      Uint8List.fromList(
        utf8.encode(
          const JsonEncoder.withIndent(
            '  ',
          ).convert(createDocument(data, createdAt: createdAt)),
        ),
      );

  Map<String, Object?> createDocument(
    PlannerData data, {
    DateTime? createdAt,
  }) => {
    'format': 'mustr-backup',
    'version': 1,
    'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    'settings': {
      'language': data.language.code,
      'themeMode': data.themeMode.code,
      'colorTheme': data.colorTheme.code,
      'lessonStyle': {
        'lectureColorValue': data.lessonStyle.lectureColorValue,
        'seminarColorValue': data.lessonStyle.seminarColorValue,
        'examColorValue': data.lessonStyle.examColorValue,
        'importantDateColorValue': data.lessonStyle.importantDateColorValue,
        'examPeriodColorValue': data.lessonStyle.examPeriodColorValue,
      },
      'remindersEnabled': data.remindersEnabled,
      'showRoomInSchedule': data.showRoomInSchedule,
      'highlightCurrentDay': data.highlightCurrentDay,
      'analyticsConsent': data.analyticsConsent,
      'analyticsInstallationId': data.analyticsInstallationId,
    },
    'facultyIds': data.faculties.map((faculty) => faculty.id).toList(),
    'timetables': data.timetables.map(_timetable).toList(),
    'tasks': data.tasks.map(_task).toList(),
    'exams': data.exams.map(_exam).toList(),
    'examPeriods': data.examPeriods.map(_examPeriod).toList(),
    'importantDates': data.importantDates.map(_importantDate).toList(),
  };

  Map<String, Object?> _timetable(Timetable timetable) => {
    'id': timetable.id,
    'name': timetable.name,
    'assignedFacultyId': timetable.assignedFacultyId,
    'semester': timetable.semester,
    'importedAt': timetable.importedAt.toIso8601String(),
    'webcalUrl': timetable.webcalUrl,
    'lastSyncedAt': timetable.lastSyncedAt?.toIso8601String(),
    'subjects': timetable.subjects.map(_subject).toList(),
    'lessons': timetable.lessons.map(_lesson).toList(),
  };

  Map<String, Object?> _subject(Subject subject) => {
    'id': subject.id,
    'courseCode': subject.courseCode,
    'name': subject.name,
    'subjectId': subject.subjectId,
    'faculty': subject.faculty,
    'notes': subject.notes,
  };

  Map<String, Object?> _lesson(Lesson lesson) => {
    'id': lesson.id,
    'date': lesson.date.toIso8601String(),
    'startTime': lesson.startTime.toIso8601String(),
    'endTime': lesson.endTime.toIso8601String(),
    'subjectKey': lesson.subjectKey,
    'courseCode': lesson.courseCode,
    'courseName': lesson.courseName,
    'subjectId': lesson.subjectId,
    'faculty': lesson.faculty,
    'timetableFacultyId': lesson.timetableFacultyId,
    'semester': lesson.semester,
    'seminarGroup': lesson.seminarGroup,
    'kind': lesson.kind.name,
    'priority': lesson.priority.name,
    'customColorValue': lesson.customColorValue,
    'reminderAt': lesson.reminderAt?.toIso8601String(),
    'rooms': lesson.rooms
        .map((room) => {'id': room.id, 'name': room.name})
        .toList(),
    'teachers': lesson.teachers
        .map((teacher) => {'id': teacher.id, 'name': teacher.name})
        .toList(),
  };

  Map<String, Object?> _task(PlannerTask task) => {
    'id': task.id,
    'title': task.title,
    'description': task.description,
    'subjectId': task.subjectId,
    'dueDate': task.dueDate.toIso8601String(),
    'dueMinute': task.dueMinute,
    'reminderAt': task.reminderAt?.toIso8601String(),
    'priority': task.priority.name,
    'isCompleted': task.isCompleted,
    'createdAt': task.createdAt.toIso8601String(),
    'updatedAt': task.updatedAt.toIso8601String(),
  };

  Map<String, Object?> _exam(Exam exam) => {
    'id': exam.id,
    'title': exam.title,
    'subjectId': exam.subjectId,
    'facultyId': exam.facultyId,
    'scheduledAt': exam.scheduledAt.toIso8601String(),
    'location': exam.location,
    'notes': exam.notes,
    'createdAt': exam.createdAt.toIso8601String(),
  };

  Map<String, Object?> _examPeriod(ExamPeriod period) => {
    'facultyId': period.facultyId,
    'startDate': period.startDate.toIso8601String(),
    'endDate': period.endDate.toIso8601String(),
  };

  Map<String, Object?> _importantDate(ImportantDate importantDate) => {
    'id': importantDate.id,
    'title': importantDate.title,
    'date': importantDate.date.toIso8601String(),
    'timeMinute': importantDate.timeMinute,
    'reminderAt': importantDate.reminderAt?.toIso8601String(),
    'facultyId': importantDate.facultyId,
    'createdAt': importantDate.createdAt.toIso8601String(),
  };
}
