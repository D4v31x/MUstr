import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:muni_timetable/data/repositories/planner_repository.dart';
import 'package:muni_timetable/domain/entities/app_language.dart';
import 'package:muni_timetable/domain/entities/exam.dart';
import 'package:muni_timetable/domain/entities/faculty.dart';
import 'package:muni_timetable/domain/entities/important_date.dart';
import 'package:muni_timetable/domain/entities/planner_task.dart';
import 'package:muni_timetable/domain/entities/timetable.dart';
import 'package:muni_timetable/services/backup_service.dart';

void main() {
  test('backups include schedules, settings, and personal planner data', () {
    final data = PlannerData(
      timetable: null,
      timetables: [
        Timetable(
          id: 'webcal-fi',
          name: 'FI schedule',
          assignedFacultyId: 'fi',
          semester: 'podzim2026',
          importedAt: DateTime(2026, 9, 1),
          webcalUrl: 'https://example.invalid/private.ics',
          lastSyncedAt: DateTime(2026, 9, 2),
          subjects: const [
            Subject(
              id: 'pb123',
              courseCode: 'PB123',
              name: 'Programming',
              subjectId: '123',
              faculty: 'fi',
              notes: 'Bring notes.',
            ),
          ],
          lessons: [
            Lesson(
              id: 'lesson-1',
              date: DateTime(2026, 9, 21),
              startTime: DateTime(2026, 9, 21, 9),
              endTime: DateTime(2026, 9, 21, 10),
              subjectKey: 'pb123',
              courseCode: 'PB123',
              seminarGroup: null,
              kind: LessonKind.lecture,
              priority: LessonPriority.high,
              customColorValue: 0xff2563eb,
              courseName: 'Programming',
              subjectId: '123',
              faculty: 'fi',
              timetableFacultyId: 'fi',
              semester: 'podzim2026',
              rooms: const [Room(id: 'A1', name: 'A1')],
              teachers: const [Teacher(id: '1', name: 'Ada')],
              reminderAt: DateTime(2026, 9, 21, 8, 45),
            ),
          ],
        ),
      ],
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
      analyticsConsent: true,
      analyticsInstallationId: 'installation-id',
      tasks: [
        PlannerTask(
          id: 'task-1',
          title: 'Homework',
          description: 'Finish it.',
          subjectId: 'pb123',
          dueDate: DateTime(2026, 9, 22),
          dueMinute: 9 * 60,
          reminderAt: DateTime(2026, 9, 21, 18),
          priority: TaskPriority.high,
          isCompleted: false,
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 2),
        ),
      ],
      exams: [
        Exam(
          id: 'exam-1',
          title: 'Final',
          subjectId: 'pb123',
          facultyId: 'fi',
          scheduledAt: DateTime(2026, 12, 1, 9),
          location: 'A1',
          notes: 'ID required',
          createdAt: DateTime(2026, 9, 1),
        ),
      ],
      examPeriods: [
        ExamPeriod(
          facultyId: 'fi',
          startDate: DateTime(2026, 12, 1),
          endDate: DateTime(2027, 1, 31),
        ),
      ],
      importantDates: [
        ImportantDate(
          id: 'date-1',
          title: 'Registration',
          date: DateTime(2026, 11, 1),
          timeMinute: 9 * 60,
          reminderAt: DateTime(2026, 10, 31, 9),
          facultyId: 'fi',
          createdAt: DateTime(2026, 9, 1),
        ),
      ],
      subjects: const [],
    );

    final document =
        jsonDecode(
              utf8.decode(
                const BackupService().createBytes(
                  data,
                  createdAt: DateTime(2026, 9, 16),
                ),
              ),
            )
            as Map<String, dynamic>;

    expect(document['format'], 'mustr-backup');
    expect(document['version'], 1);
    expect(document['settings']['analyticsInstallationId'], 'installation-id');
    expect(document['timetables'].single['webcalUrl'], isNotNull);
    expect(
      document['timetables'].single['lessons'].single['reminderAt'],
      isNotNull,
    );
    expect(document['tasks'].single['title'], 'Homework');
    expect(document['exams'].single['title'], 'Final');
    expect(document['importantDates'].single['title'], 'Registration');
  });
}
