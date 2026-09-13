import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/planner_task.dart';
import '../../domain/entities/timetable.dart';
import '../providers/planner_providers.dart';
import '../localization/app_strings.dart';
import '../widgets/change_confirmation_dialog.dart';
import '../widgets/planner_formatters.dart';

Future<void> showTaskEditor(
  BuildContext context, {
  PlannerTask? task,
  required List<Subject> subjects,
  required List<Lesson> lessons,
  String? initialSubjectId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => TaskEditorSheet(
    task: task,
    subjects: subjects,
    lessons: lessons,
    initialSubjectId: initialSubjectId,
  ),
);

class TaskEditorSheet extends ConsumerStatefulWidget {
  const TaskEditorSheet({
    super.key,
    required this.task,
    required this.subjects,
    required this.lessons,
    required this.initialSubjectId,
  });

  final PlannerTask? task;
  final List<Subject> subjects;
  final List<Lesson> lessons;
  final String? initialSubjectId;

  @override
  ConsumerState<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends ConsumerState<TaskEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late DateTime _dueDate;
  int? _dueMinute;
  DateTime? _reminder;
  String? _subjectId;
  late TaskPriority _priority;
  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title);
    _description = TextEditingController(text: task?.description);
    _dueDate = task?.dueDate ?? DateTime.now();
    _dueMinute = task?.dueMinute;
    _reminder = task?.reminderAt;
    _subjectId = task?.subjectId ?? widget.initialSubjectId;
    _priority = task?.priority ?? TaskPriority.normal;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.task == null ? strings.newTask : strings.editTask,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                autofocus: true,
                decoration: InputDecoration(labelText: strings.taskTitle),
                validator: (value) => value == null || value.trim().isEmpty
                    ? strings.taskTitleRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: InputDecoration(labelText: strings.notesOptional),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _subjectId,
                menuMaxHeight: 320,
                decoration: InputDecoration(labelText: strings.subject),
                items: [
                  DropdownMenuItem(value: null, child: Text(strings.noSubject)),
                  ...widget.subjects.map(
                    (subject) => DropdownMenuItem(
                      value: subject.id,
                      child: Text(
                        '${subject.courseCode} - ${subject.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _subjectId = value),
              ),
              if (_nextClass != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _useNextClassDueDate,
                    icon: const Icon(Icons.event_available_outlined),
                    label: Text(
                      '${strings.dueOnNextClass}: ${compactDate(context, _nextClass!.startTime)} ${timeLabel(_nextClass!.startTime)}',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDueDate,
                      icon: const Icon(Icons.event_outlined),
                      label: Text(compactDate(context, _dueDate)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDueTime,
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text(
                        _dueMinute == null
                            ? strings.dueTime
                            : '${(_dueMinute! ~/ 60).toString().padLeft(2, '0')}:${(_dueMinute! % 60).toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                strings.priority,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              SegmentedButton<TaskPriority>(
                segments: [
                  ButtonSegment(
                    value: TaskPriority.low,
                    label: Text(strings.low),
                  ),
                  ButtonSegment(
                    value: TaskPriority.normal,
                    label: Text(strings.normal),
                  ),
                  ButtonSegment(
                    value: TaskPriority.high,
                    label: Text(strings.high),
                  ),
                ],
                selected: {_priority},
                onSelectionChanged: (value) =>
                    setState(() => _priority = value.single),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.reminder),
                subtitle: Text(
                  _reminder == null
                      ? strings.noReminder
                      : '${compactDate(context, _reminder!)} ${strings.at} ${timeLabel(_reminder!)}',
                ),
                value: _reminder != null,
                onChanged: (value) => setState(
                  () => _reminder = value
                      ? _dueDate
                            .subtract(const Duration(days: 1))
                            .add(const Duration(hours: 18))
                      : null,
                ),
              ),
              if (_reminder != null)
                OutlinedButton.icon(
                  onPressed: _pickReminder,
                  icon: const Icon(Icons.notifications_outlined),
                  label: Text(strings.changeReminderTime),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(strings.saveTask),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Lesson? get _nextClass {
    final subjectId = _subjectId;
    if (subjectId == null) {
      return null;
    }
    final lessons =
        widget.lessons
            .where(
              (lesson) =>
                  lesson.subjectKey == subjectId &&
                  lesson.kind != LessonKind.event &&
                  lesson.startTime.isAfter(DateTime.now()),
            )
            .toList()
          ..sort(
            (first, second) => first.startTime.compareTo(second.startTime),
          );
    return lessons.firstOrNull;
  }

  void _useNextClassDueDate() {
    final lesson = _nextClass;
    if (lesson == null) {
      return;
    }
    setState(() {
      _dueDate = DateTime(
        lesson.startTime.year,
        lesson.startTime.month,
        lesson.startTime.day,
      );
      _dueMinute = lesson.startTime.hour * 60 + lesson.startTime.minute;
    });
  }

  Future<void> _pickDueDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value != null) {
      setState(() => _dueDate = value);
    }
  }

  Future<void> _pickDueTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _dueMinute == null ? 23 : _dueMinute! ~/ 60,
        minute: _dueMinute == null ? 59 : _dueMinute! % 60,
      ),
    );
    if (value != null) {
      setState(() => _dueMinute = value.hour * 60 + value.minute);
    }
  }

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminder!,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminder!),
    );
    if (time != null) {
      setState(
        () => _reminder = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (widget.task != null && !await confirmEdit(context)) return;
    final controller = ref.read(plannerProvider.notifier);
    final existing = widget.task;
    final task = existing == null
        ? controller.newTask(
            title: _title.text.trim(),
            description: _description.text.trim(),
            subjectId: _subjectId,
            dueDate: _dueDate,
            dueMinute: _dueMinute,
            reminderAt: _reminder,
            priority: _priority,
          )
        : existing.copyWith(
            title: _title.text.trim(),
            description: _description.text.trim(),
            subjectId: _subjectId,
            clearSubject: _subjectId == null,
            dueDate: _dueDate,
            dueMinute: _dueMinute,
            clearDueMinute: _dueMinute == null,
            reminderAt: _reminder,
            clearReminder: _reminder == null,
            priority: _priority,
            updatedAt: DateTime.now(),
          );
    await ref.read(plannerProvider.notifier).saveTask(task);
    if (mounted) Navigator.pop(context);
  }
}
