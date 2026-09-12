import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/planner_repository.dart';
import '../providers/planner_providers.dart';
import '../widgets/faculty_badge.dart';
import '../widgets/lesson_detail_sheet.dart';
import '../widgets/planner_formatters.dart';
import 'exam_editor_sheet.dart';
import '../localization/app_strings.dart';

class SemesterScreen extends StatefulWidget {
  const SemesterScreen({super.key, required this.data});

  final PlannerData data;

  @override
  State<SemesterScreen> createState() => _SemesterScreenState();
}

class _SemesterScreenState extends State<SemesterScreen> {
  DateTime? _selectedWeek;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final timetable = widget.data.timetable!;
    final weeks = <DateTime>{for (final lesson in timetable.lessons) mondayFor(lesson.date)}.toList()..sort();
    final selected = _selectedWeek ?? weeks.first;
    final lessons = timetable.lessons.where((lesson) => !lesson.date.isBefore(selected) && lesson.date.isBefore(selected.add(const Duration(days: 7)))).toList();
    final tasks = widget.data.tasks.where((task) => !task.isCompleted && !task.dueDate.isBefore(selected) && task.dueDate.isBefore(selected.add(const Duration(days: 7)))).toList();
    final defaultFacultyId = widget.data.timetable!.assignedFacultyId ?? widget.data.faculties.first.id;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(strings.semesterLabel, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 4),
        Text(timetable.semester ?? strings.importedTimetable, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('${compactDate(context, timetable.firstDate!)} - ${compactDate(context, timetable.lastDate!)}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        Wrap(spacing: 10, runSpacing: 8, children: [
          FilledButton.icon(onPressed: () => showExamEditor(context, data: widget.data, initialFacultyId: defaultFacultyId), icon: const Icon(Icons.school_outlined), label: Text(strings.addExam)),
          OutlinedButton.icon(onPressed: () => showExamPeriodEditor(context, data: widget.data, initialFacultyId: defaultFacultyId), icon: const Icon(Icons.date_range_outlined), label: Text(strings.examPeriod)),
        ]),
        const SizedBox(height: 32),
        _AssessmentSection(data: widget.data),
        const SizedBox(height: 32),
        DropdownButtonFormField<DateTime>(
          initialValue: selected,
          decoration: InputDecoration(labelText: strings.jumpToWeek),
          items: weeks.map((week) => DropdownMenuItem(value: week, child: Text('${compactDate(context, week)} - ${compactDate(context, week.add(const Duration(days: 6)))}'))).toList(),
          onChanged: (value) => setState(() => _selectedWeek = value),
        ),
        const SizedBox(height: 32),
        Text('${lessons.length} ${strings.scheduledEvents}', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...lessons.map(
          (lesson) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: () => showLessonDetails(context, lesson, style: widget.data.lessonStyle),
                leading: Container(
                  width: 8,
                  height: 44,
                  decoration: BoxDecoration(
                    color: lessonColor(Theme.of(context).colorScheme, lesson, widget.data.lessonStyle),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                title: Text(lesson.courseName, style: Theme.of(context).textTheme.titleMedium),
                subtitle: Text('${compactDate(context, lesson.date)} | ${timeLabel(lesson.startTime)} - ${timeLabel(lesson.endTime)}'),
                trailing: Text(timetableCodeLabel(lesson), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(strings.deadlines, style: Theme.of(context).textTheme.titleLarge),
        if (tasks.isEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(strings.noDeadlines)),
        ...tasks.map((task) => ListTile(leading: const Icon(Icons.assignment_outlined), title: Text(task.title), subtitle: Text(dueLabel(context, task)))),
      ],
    );
  }
}

class _AssessmentSection extends ConsumerWidget {
  const _AssessmentSection({required this.data});

  final PlannerData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final now = DateTime.now();
    final exams = data.exams.where((exam) => !exam.scheduledAt.isBefore(DateTime(now.year, now.month, now.day))).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(strings.assessments, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      ...data.examPeriods.map(
        (period) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: FacultyBadge(facultyId: period.facultyId, compact: true),
              title: Text(strings.examPeriod),
              subtitle: Text('${compactDate(context, period.startDate)} - ${compactDate(context, period.endDate)}'),
            ),
          ),
        ),
      ),
      if (exams.isEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(strings.noExams)),
      ...exams.map((exam) {
        final subject = exam.subjectId == null ? null : data.subjects.where((item) => item.id == exam.subjectId).firstOrNull;
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: Card(child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: FacultyBadge(facultyId: exam.facultyId, compact: true),
          title: Text(exam.title),
          subtitle: Text('${subject?.courseCode ?? strings.independentExam} | ${compactDate(context, exam.scheduledAt)} ${strings.at} ${timeLabel(exam.scheduledAt)}${exam.location.isEmpty ? '' : ' | ${exam.location}'}'),
          trailing: IconButton(tooltip: strings.deleteExam, icon: const Icon(Icons.delete_outline), onPressed: () => ref.read(plannerProvider.notifier).deleteExam(exam.id)),
        )));
      }),
    ]);
  }
}