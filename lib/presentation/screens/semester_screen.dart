import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/planner_repository.dart';
import '../../domain/entities/exam.dart';
import '../../domain/entities/timetable.dart';
import '../localization/app_strings.dart';
import '../providers/planner_providers.dart';
import '../widgets/faculty_badge.dart';
import '../widgets/planner_formatters.dart';
import 'exam_editor_sheet.dart';
import 'important_date_editor_sheet.dart';

class SemesterScreen extends ConsumerWidget {
  const SemesterScreen({super.key, required this.data});

  final PlannerData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final timetable = data.timetable!;
    final facultyIds = timetable.assignedFacultyId == null
        ? data.faculties.map((faculty) => faculty.id).toSet()
        : {timetable.assignedFacultyId!};
    final defaultFacultyId =
        timetable.assignedFacultyId ?? data.faculties.first.id;
    final examPeriods =
        data.examPeriods
            .where((period) => facultyIds.contains(period.facultyId))
            .toList()
          ..sort(
            (first, second) => first.startDate.compareTo(second.startDate),
          );
    final exams =
        data.exams.where((exam) => facultyIds.contains(exam.facultyId)).toList()
          ..sort(
            (first, second) => first.scheduledAt.compareTo(second.scheduledAt),
          );
    final importantDates = <_TimelineDate>[
      _TimelineDate(
        icon: Icons.play_circle_outline_rounded,
        title: strings.starts,
        date: timetable.firstDate!,
      ),
      ...data.importantDates.map(
        (importantDate) => _TimelineDate(
          icon: Icons.bookmark_outline_rounded,
          title: importantDate.title,
          date: importantDate.date,
          facultyId: importantDate.facultyId,
          onDelete: () => ref
              .read(plannerProvider.notifier)
              .deleteImportantDate(importantDate.id),
        ),
      ),
      ...examPeriods.map(
        (period) => _TimelineDate(
          icon: Icons.date_range_outlined,
          title: strings.examPeriod,
          date: period.startDate,
          endDate: period.endDate,
          facultyId: period.facultyId,
        ),
      ),
      _TimelineDate(
        icon: Icons.flag_outlined,
        title: strings.ends,
        date: timetable.lastDate!,
      ),
    ]..sort((first, second) => first.date.compareTo(second.date));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          strings.semesterLabel,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          timetable.semester ?? strings.schedule,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '${compactDate(context, timetable.firstDate!)} - ${compactDate(context, timetable.lastDate!)}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: _TermBoundary(
                    icon: Icons.play_circle_outline_rounded,
                    label: strings.starts,
                    date: timetable.firstDate!,
                  ),
                ),
                Container(
                  width: 1,
                  height: 44,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _TermBoundary(
                    icon: Icons.flag_outlined,
                    label: strings.ends,
                    date: timetable.lastDate!,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => showExamEditor(
                context,
                data: data,
                initialFacultyId: defaultFacultyId,
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(strings.addExam),
            ),
            OutlinedButton.icon(
              onPressed: () => showImportantDateEditor(context, data: data),
              icon: const Icon(Icons.bookmark_add_outlined),
              label: Text(strings.addImportantDate),
            ),
            OutlinedButton.icon(
              onPressed: () => showExamPeriodEditor(
                context,
                data: data,
                initialFacultyId: defaultFacultyId,
              ),
              icon: const Icon(Icons.date_range_outlined),
              label: Text(strings.examPeriod),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _SectionHeader(
          title: strings.importantDates,
          icon: Icons.event_note_outlined,
        ),
        const SizedBox(height: 12),
        ...importantDates.map(
          (importantDate) => _ImportantDateTile(importantDate: importantDate),
        ),
        const SizedBox(height: 32),
        _SectionHeader(title: strings.exams, icon: Icons.school_outlined),
        const SizedBox(height: 12),
        if (exams.isEmpty)
          Text(
            strings.noExams,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ...exams.map(
          (exam) => _ExamTile(
            exam: exam,
            subject: exam.subjectId == null
                ? null
                : data.subjects
                      .where((subject) => subject.id == exam.subjectId)
                      .firstOrNull,
            onDelete: () =>
                ref.read(plannerProvider.notifier).deleteExam(exam.id),
          ),
        ),
      ],
    );
  }
}

class _TermBoundary extends StatelessWidget {
  const _TermBoundary({
    required this.icon,
    required this.label,
    required this.date,
  });

  final IconData icon;
  final String label;
  final DateTime date;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 8),
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      Text(
        compactDate(context, date),
        style: Theme.of(context).textTheme.titleSmall,
      ),
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}

class _ImportantDateTile extends StatelessWidget {
  const _ImportantDateTile({required this.importantDate});

  final _TimelineDate importantDate;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          importantDate.icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(importantDate.title),
        subtitle: Text(
          importantDate.endDate == null
              ? compactDate(context, importantDate.date)
              : '${compactDate(context, importantDate.date)} - ${compactDate(context, importantDate.endDate!)}',
        ),
        trailing:
            importantDate.facultyId == null && importantDate.onDelete == null
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (importantDate.facultyId != null)
                    FacultyBadge(
                      facultyId: importantDate.facultyId!,
                      compact: true,
                    ),
                  if (importantDate.onDelete != null)
                    IconButton(
                      tooltip: context.strings.deleteImportantDate,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: importantDate.onDelete,
                    ),
                ],
              ),
      ),
    ),
  );
}

class _TimelineDate {
  const _TimelineDate({
    required this.icon,
    required this.title,
    required this.date,
    this.endDate,
    this.facultyId,
    this.onDelete,
  });

  final IconData icon;
  final String title;
  final DateTime date;
  final DateTime? endDate;
  final String? facultyId;
  final VoidCallback? onDelete;
}

class _ExamTile extends StatelessWidget {
  const _ExamTile({
    required this.exam,
    required this.subject,
    required this.onDelete,
  });

  final Exam exam;
  final Subject? subject;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: FacultyBadge(facultyId: exam.facultyId, compact: true),
        title: Text(exam.title),
        subtitle: Text(
          '${subject?.courseCode ?? context.strings.independentExam} | ${compactDate(context, exam.scheduledAt)} ${context.strings.at} ${timeLabel(exam.scheduledAt)}${exam.location.isEmpty ? '' : ' | ${exam.location}'}',
        ),
        trailing: IconButton(
          tooltip: context.strings.deleteExam,
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    ),
  );
}
