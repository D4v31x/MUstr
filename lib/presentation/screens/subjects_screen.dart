import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/planner_repository.dart';
import '../../domain/entities/timetable.dart';
import '../providers/planner_providers.dart';
import '../widgets/planner_formatters.dart';
import '../widgets/faculty_badge.dart';
import '../localization/app_strings.dart';
import 'task_editor_sheet.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key, required this.data});

  final PlannerData data;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: data.subjects.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.yourCourses,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.subjectsInTimetable(data.subjects.length),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          );
        }
        final subject = data.subjects[index - 1];
        final lessons = data.timetable!.lessons
            .where((lesson) => lesson.subjectKey == subject.id)
            .toList();
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) =>
                  SubjectSheet(subject: subject, lessons: lessons, data: data),
            ),
            title: Row(
              children: [
                Text(
                  subject.courseCode,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Color(
                      data.lessonStyle.colorForSubject(subject.id) ??
                          eventColor(
                            Theme.of(context).colorScheme,
                            subject.faculty,
                            subject.id,
                          ).toARGB32(),
                    ),
                  ),
                ),
                if (subject.faculty != null) ...[
                  const SizedBox(width: 16),
                  FacultyBadge(facultyId: subject.faculty!, compact: true),
                ],
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${subject.name}\n${strings.scheduledClasses(lessons.length)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

class SubjectSheet extends ConsumerWidget {
  const SubjectSheet({
    super.key,
    required this.subject,
    required this.lessons,
    required this.data,
  });

  final Subject subject;
  final List<Lesson> lessons;
  final PlannerData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final teachers = lessons
        .expand((lesson) => lesson.teachers)
        .map((teacher) => teacher.name)
        .toSet()
        .join(', ');
    final rooms = lessons
        .expand((lesson) => lesson.rooms)
        .map((room) => room.name)
        .toSet()
        .join(', ');
    final tasks = data.tasks
        .where((task) => task.subjectId == subject.id)
        .toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    subject.courseCode,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  if (subject.faculty != null) ...[
                    const SizedBox(width: 16),
                    FacultyBadge(facultyId: subject.faculty!, compact: true),
                  ],
                  const Spacer(),
                  IconButton(
                    tooltip: strings.deleteSubject,
                    icon: const Icon(Icons.delete_outline),
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () => _confirmDeleteSubject(context, ref),
                  ),
                ],
              ),
              Text(
                subject.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              if (teachers.isNotEmpty)
                _Info(
                  icon: Icons.person_outline,
                  title: strings.teachers,
                  value: teachers,
                ),
              if (rooms.isNotEmpty)
                _Info(
                  icon: Icons.place_outlined,
                  title: strings.rooms,
                  value: rooms,
                ),
              _Info(
                icon: Icons.calendar_today_outlined,
                title: strings.schedule,
                value: strings.scheduledClasses(lessons.length),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    strings.notes,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: strings.newTask,
                    icon: const Icon(Icons.add_task_outlined),
                    onPressed: () => showTaskEditor(
                      context,
                      subjects: data.subjects,
                      lessons: data.timetable?.lessons ?? const [],
                      initialSubjectId: subject.id,
                    ),
                  ),
                  IconButton(
                    tooltip: strings.editNotes,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editNotes(context, ref),
                  ),
                ],
              ),
              Text(
                subject.notes.isEmpty ? '${strings.notes} -' : subject.notes,
              ),
              const SizedBox(height: 22),
              Text(
                strings.homework,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (tasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(strings.noSubjectTasks),
                ),
              ...tasks.map(
                (task) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    task.isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(task.title),
                  subtitle: Text(dueLabel(context, task)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editNotes(BuildContext context, WidgetRef ref) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (_) => _NotesEditorDialog(
        courseCode: subject.courseCode,
        initialNotes: subject.notes,
      ),
    );
    if (notes != null) {
      await ref
          .read(plannerProvider.notifier)
          .saveSubjectNotes(subject.id, notes.trim());
    }
  }

  Future<void> _confirmDeleteSubject(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: Text(context.strings.deleteSubject),
        content: Text(context.strings.deleteSubjectMessage(subject.courseCode)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.strings.deleteSubject),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref.read(plannerProvider.notifier).deleteSubject(subject.id);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _NotesEditorDialog extends StatefulWidget {
  const _NotesEditorDialog({
    required this.courseCode,
    required this.initialNotes,
  });

  final String courseCode;
  final String initialNotes;

  @override
  State<_NotesEditorDialog> createState() => _NotesEditorDialogState();
}

class _NotesEditorDialogState extends State<_NotesEditorDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialNotes,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.strings.notesFor(widget.courseCode)),
    content: TextField(
      controller: _controller,
      minLines: 5,
      maxLines: 10,
      autofocus: true,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.strings.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_controller.text),
        child: Text(context.strings.save),
      ),
    ],
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              Text(value),
            ],
          ),
        ),
      ],
    ),
  );
}
