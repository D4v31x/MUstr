import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../data/repositories/planner_repository.dart';
import '../../domain/entities/planner_task.dart';
import '../providers/planner_providers.dart';
import '../localization/app_strings.dart';
import '../widgets/planner_formatters.dart';
import 'task_editor_sheet.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key, required this.data});

  final PlannerData data;

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  bool? _completed = false;
  TaskPriority? _priority;
  String? _subjectId;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final tasks =
        widget.data.tasks
            .where(
              (task) =>
                  (_completed == null || task.isCompleted == _completed) &&
                  (_priority == null || task.priority == _priority) &&
                  (_subjectId == null || task.subjectId == _subjectId),
            )
            .toList()
          ..sort((first, second) => first.dueAt.compareTo(second.dueAt));
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 112),
          children: [
            Text(
              strings.keepMoving,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              strings.tasksInView(
                tasks.length,
                _completed == true
                    ? strings.completed.toLowerCase()
                    : strings.open.toLowerCase(),
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(strings.open),
                    selected: _completed == false,
                    onSelected: (_) => setState(() => _completed = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(strings.all),
                    selected: _completed == null,
                    onSelected: (_) => setState(() => _completed = null),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(strings.completed),
                    selected: _completed == true,
                    onSelected: (_) => setState(() => _completed = true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TaskPriority?>(
                    initialValue: _priority,
                    decoration: InputDecoration(
                      labelText: strings.priority,
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(strings.anyPriority),
                      ),
                      ...TaskPriority.values.map(
                        (priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(_priorityLabel(strings, priority)),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _priority = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _subjectId,
                    decoration: InputDecoration(
                      labelText: strings.subject,
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(strings.allSubjects),
                      ),
                      ...widget.data.subjects.map(
                        (subject) => DropdownMenuItem(
                          value: subject.id,
                          child: Text(subject.courseCode),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _subjectId = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (tasks.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      _completed == false
                          ? strings.noOpenTasks
                          : strings.noMatchingTasks,
                    ),
                  ),
                ),
              ),
            ...tasks.map((task) => _TaskCard(task: task, data: widget.data)),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: M3EExtendedFab(
            label: strings.newTask,
            icon: const Icon(Icons.add),
            onPressed: () => showTaskEditor(
              context,
              subjects: widget.data.subjects,
              lessons: widget.data.timetable?.lessons ?? const [],
            ),
          ),
        ),
      ],
    );
  }

  String _priorityLabel(AppStrings strings, TaskPriority priority) =>
      switch (priority) {
        TaskPriority.low => strings.low,
        TaskPriority.normal => strings.normal,
        TaskPriority.high => strings.high,
      };
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task, required this.data});

  final PlannerTask task;
  final PlannerData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subject = task.subjectId == null
        ? null
        : data.subjects
              .where((subject) => subject.id == task.subjectId)
              .firstOrNull;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: task.isCompleted ? 0.58 : 1,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          onTap: () => showTaskEditor(
            context,
            task: task,
            subjects: data.subjects,
            lessons: data.timetable?.lessons ?? const [],
          ),
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (_) =>
                ref.read(plannerProvider.notifier).toggleTask(task),
          ),
          title: Text(
            task.title,
            style: task.isCompleted
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            '${subject?.courseCode ?? context.strings.unassigned} | ${dueLabel(context, task)}',
            style: TextStyle(color: task.isOverdue ? scheme.error : null),
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete' && await _confirmDelete(context)) {
                await ref.read(plannerProvider.notifier).deleteTask(task.id);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete',
                child: Text(context.strings.delete),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.strings.deleteTask),
          content: Text(context.strings.deleteTaskMessage(task.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.strings.delete),
            ),
          ],
        ),
      ) ??
      false;
}
