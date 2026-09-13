import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/planner_repository.dart';
import '../../domain/entities/exam.dart';
import '../../domain/entities/important_date.dart';
import '../../domain/entities/timetable.dart';
import '../localization/app_strings.dart';
import '../providers/planner_providers.dart';
import '../widgets/change_confirmation_dialog.dart';
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
    final importantDates = data.importantDates.toList()
      ..sort((first, second) => first.date.compareTo(second.date));

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
          strings.thisSemester,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _SemesterRange(
          startDate: timetable.firstDate!,
          endDate: timetable.lastDate!,
        ),
        const SizedBox(height: 24),
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
          title: strings.examPeriods,
          icon: Icons.date_range_outlined,
        ),
        const SizedBox(height: 12),
        if (examPeriods.isEmpty)
          Text(
            strings.noExamPeriods,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ...examPeriods.map(
          (period) => _ExamPeriodTile(data: data, examPeriod: period),
        ),
        const SizedBox(height: 32),
        _SectionHeader(
          title: strings.importantDates,
          icon: Icons.bookmark_outline_rounded,
        ),
        const SizedBox(height: 12),
        if (importantDates.isEmpty)
          Text(
            strings.noImportantDates,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ...importantDates.map(
          (importantDate) => _ImportantDateTile(
            data: data,
            importantDate: importantDate,
            onDelete: () async {
              if (!await confirmDelete(
                context,
                title: strings.deleteImportantDate,
                message: strings.deleteImportantDateMessage(
                  importantDate.title,
                ),
              )) {
                return;
              }
              await ref
                  .read(plannerProvider.notifier)
                  .deleteImportantDate(importantDate.id);
            },
          ),
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
            data: data,
            exam: exam,
            subject: exam.subjectId == null
                ? null
                : data.subjects
                      .where((subject) => subject.id == exam.subjectId)
                      .firstOrNull,
            onDelete: () async {
              if (!await confirmDelete(
                context,
                title: strings.deleteExam,
                message: strings.deleteExamMessage(exam.title),
              )) {
                return;
              }
              await ref.read(plannerProvider.notifier).deleteExam(exam.id);
            },
          ),
        ),
      ],
    );
  }
}

class _SemesterRange extends StatelessWidget {
  const _SemesterRange({required this.startDate, required this.endDate});

  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RangeEndpoint(
              icon: Icons.play_circle_outline_rounded,
              label: context.strings.semesterStarts,
              date: startDate,
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: scheme.onPrimaryContainer.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _RangeEndpoint(
              icon: Icons.flag_outlined,
              label: context.strings.semesterEnds,
              date: endDate,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeEndpoint extends StatelessWidget {
  const _RangeEndpoint({
    required this.icon,
    required this.label,
    required this.date,
  });

  final IconData icon;
  final String label;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimaryContainer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
        ),
        Text(
          compactDate(context, date),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
        ),
      ],
    );
  }
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
  const _ImportantDateTile({
    required this.data,
    required this.importantDate,
    required this.onDelete,
  });

  final PlannerData data;
  final ImportantDate importantDate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _showImportantDateDetails(context, data, importantDate),
        leading: Icon(
          Icons.bookmark_outline_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(importantDate.title),
        subtitle: Text(
          importantDate.timeMinute == null
              ? compactDate(context, importantDate.date)
              : '${compactDate(context, importantDate.date)} ${timeLabel(importantDate.scheduledAt)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (importantDate.facultyId != null)
              FacultyBadge(facultyId: importantDate.facultyId!, compact: true),
            IconButton(
              tooltip: context.strings.deleteImportantDate,
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ExamPeriodTile extends StatelessWidget {
  const _ExamPeriodTile({required this.data, required this.examPeriod});

  final PlannerData data;
  final ExamPeriod examPeriod;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _showExamPeriodDetails(context, data, examPeriod),
        leading: Icon(
          Icons.date_range_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(context.strings.examPeriod),
        subtitle: Text(
          '${compactDate(context, examPeriod.startDate)} - ${compactDate(context, examPeriod.endDate)}',
        ),
        trailing: FacultyBadge(facultyId: examPeriod.facultyId, compact: true),
      ),
    ),
  );
}

class _ExamTile extends StatelessWidget {
  const _ExamTile({
    required this.data,
    required this.exam,
    required this.subject,
    required this.onDelete,
  });

  final PlannerData data;
  final Exam exam;
  final Subject? subject;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _showExamDetails(context, data, exam, subject),
        leading: Icon(
          Icons.school_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(exam.title),
        subtitle: Text(
          '${subject?.courseCode ?? context.strings.independentExam} | ${compactDate(context, exam.scheduledAt)} ${context.strings.at} ${timeLabel(exam.scheduledAt)}${exam.location.isEmpty ? '' : ' | ${exam.location}'}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FacultyBadge(facultyId: exam.facultyId, compact: true),
            IconButton(
              tooltip: context.strings.deleteExam,
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showImportantDateDetails(
  BuildContext context,
  PlannerData data,
  ImportantDate importantDate,
) => _showSemesterDetails(
  context,
  icon: Icons.bookmark_outline_rounded,
  accent: Color(data.lessonStyle.importantDateColorValue),
  label: context.strings.importantDate,
  title: importantDate.title,
  rows: [
    _SemesterDetailRow(
      icon: Icons.event_outlined,
      value: importantDate.timeMinute == null
          ? '${compactDate(context, importantDate.date)}\n${context.strings.allDay}'
          : '${compactDate(context, importantDate.date)}\n${timeLabel(importantDate.scheduledAt)}',
    ),
    if (importantDate.reminderAt != null)
      _SemesterDetailRow(
        icon: Icons.notifications_outlined,
        value:
            '${context.strings.reminder}\n${compactDate(context, importantDate.reminderAt!)} ${timeLabel(importantDate.reminderAt!)}',
      ),
  ],
  facultyId: importantDate.facultyId,
  onEdit: () => showImportantDateEditor(
    context,
    data: data,
    initialImportantDate: importantDate,
  ),
);

Future<void> _showExamPeriodDetails(
  BuildContext context,
  PlannerData data,
  ExamPeriod examPeriod,
) => _showSemesterDetails(
  context,
  icon: Icons.date_range_outlined,
  accent: Color(data.lessonStyle.examPeriodColorValue),
  label: context.strings.examPeriod,
  title: context.strings.examPeriod,
  rows: [
    _SemesterDetailRow(
      icon: Icons.calendar_month_outlined,
      value:
          '${context.strings.semesterStarts}: ${compactDate(context, examPeriod.startDate)}\n${context.strings.semesterEnds}: ${compactDate(context, examPeriod.endDate)}',
    ),
  ],
  facultyId: examPeriod.facultyId,
  onEdit: () => showExamPeriodEditor(
    context,
    data: data,
    initialFacultyId: examPeriod.facultyId,
    initialExamPeriod: examPeriod,
  ),
);

Future<void> _showExamDetails(
  BuildContext context,
  PlannerData data,
  Exam exam,
  Subject? subject,
) => _showSemesterDetails(
  context,
  icon: Icons.school_outlined,
  accent: Color(data.lessonStyle.examColorValue),
  label: context.strings.exam,
  title: exam.title,
  rows: [
    if (subject != null)
      _SemesterDetailRow(
        icon: Icons.menu_book_outlined,
        value: '${subject.courseCode}\n${subject.name}',
      ),
    _SemesterDetailRow(
      icon: Icons.schedule_outlined,
      value:
          '${compactDate(context, exam.scheduledAt)}\n${timeLabel(exam.scheduledAt)}',
    ),
    if (exam.location.isNotEmpty)
      _SemesterDetailRow(
        icon: Icons.location_on_outlined,
        value: exam.location,
      ),
    if (exam.notes.isNotEmpty)
      _SemesterDetailRow(icon: Icons.notes_outlined, value: exam.notes),
  ],
  facultyId: exam.facultyId,
  onEdit: () => showExamEditor(
    context,
    data: data,
    initialFacultyId: exam.facultyId,
    initialExam: exam,
  ),
);

Future<void> _showSemesterDetails(
  BuildContext context, {
  required IconData icon,
  required Color accent,
  required String label,
  required String title,
  required List<_SemesterDetailRow> rows,
  required String? facultyId,
  required VoidCallback onEdit,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          if (facultyId != null) ...[
            const SizedBox(height: 12),
            FacultyBadge(facultyId: facultyId, compact: true),
          ],
          const SizedBox(height: 24),
          ...rows,
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onEdit();
              },
              icon: const Icon(Icons.edit_outlined),
              label: Text(context.strings.edit),
            ),
          ),
        ],
      ),
    ),
  ),
);

class _SemesterDetailRow extends StatelessWidget {
  const _SemesterDetailRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 16),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    ),
  );
}
