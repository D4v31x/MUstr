import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/planner_repository.dart';
import '../../domain/entities/timetable.dart';
import '../localization/app_strings.dart';
import '../providers/planner_providers.dart';
import '../widgets/planner_formatters.dart';

Future<void> showLessonEditor(
  BuildContext context, {
  required PlannerData data,
  String? initialTimetableId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) =>
      _LessonEditor(data: data, initialTimetableId: initialTimetableId),
);

class _LessonEditor extends ConsumerStatefulWidget {
  const _LessonEditor({required this.data, required this.initialTimetableId});

  final PlannerData data;
  final String? initialTimetableId;

  @override
  ConsumerState<_LessonEditor> createState() => _LessonEditorState();
}

class _LessonEditorState extends ConsumerState<_LessonEditor> {
  static const _newSubject = '__new_subject__';
  final _formKey = GlobalKey<FormState>();
  late String _timetableId;
  String _subjectChoice = _newSubject;
  LessonKind _kind = LessonKind.lecture;
  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 40);
  String _courseName = '';
  String _courseCode = '';
  String _seminarGroup = '';
  String _room = '';
  String _teacher = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final requested = widget.initialTimetableId;
    _timetableId =
        requested != null &&
            widget.data.timetables.any((item) => item.id == requested)
        ? requested
        : widget.data.timetables.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final timetable = widget.data.timetables.firstWhere(
      (item) => item.id == _timetableId,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.addClassTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                strings.classType,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<LessonKind>(
                  segments: [
                    ButtonSegment(
                      value: LessonKind.lecture,
                      icon: const Icon(Icons.auto_stories_outlined),
                      label: Text(strings.lecture),
                    ),
                    ButtonSegment(
                      value: LessonKind.seminar,
                      icon: const Icon(Icons.groups_outlined),
                      label: Text(strings.seminar),
                    ),
                  ],
                  selected: {_kind},
                  showSelectedIcon: false,
                  onSelectionChanged: (values) =>
                      setState(() => _kind = values.single),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _timetableId,
                menuMaxHeight: 320,
                decoration: InputDecoration(labelText: strings.targetTimetable),
                items: widget.data.timetables
                    .map(
                      (timetable) => DropdownMenuItem(
                        value: timetable.id,
                        child: Text(
                          timetable.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _timetableId = value!;
                  _subjectChoice = _newSubject;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_timetableId),
                initialValue: _subjectChoice,
                menuMaxHeight: 320,
                decoration: InputDecoration(labelText: strings.subject),
                items: [
                  DropdownMenuItem(
                    value: _newSubject,
                    child: Text(strings.createNewSubject),
                  ),
                  ...timetable.subjects.map(
                    (subject) => DropdownMenuItem(
                      value: subject.id,
                      child: Text(
                        '${subject.courseCode} - ${subject.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _subjectChoice = value!),
              ),
              if (_subjectChoice == _newSubject) ...[
                const SizedBox(height: 12),
                TextFormField(
                  autofocus: true,
                  decoration: InputDecoration(labelText: strings.courseName),
                  onChanged: (value) => _courseName = value,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? strings.courseNameRequired
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: strings.courseCodeOptional,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) => _courseCode = value,
                ),
              ],
              if (_kind == LessonKind.seminar) ...[
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: strings.seminarGroupOptional,
                  ),
                  onChanged: (value) => _seminarGroup = value,
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  '${strings.classDate}: ${compactDate(context, _date)}',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(start: true),
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text(
                        '${strings.startTime}: ${_start.format(context)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(start: false),
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text(
                        '${strings.endTime}: ${_end.format(context)}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(labelText: strings.roomOptional),
                onChanged: (value) => _room = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(labelText: strings.teacherOptional),
                textCapitalization: TextCapitalization.words,
                onChanged: (value) => _teacher = value,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(strings.saveClass),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value != null) setState(() => _date = value);
  }

  Future<void> _pickTime({required bool start}) async {
    final value = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (value == null) return;
    setState(() {
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final startTime = _atTime(_date, _start);
    final endTime = _atTime(_date, _end);
    if (!endTime.isAfter(startTime)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.strings.invalidClassTime)));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(plannerProvider.notifier)
          .addManualLesson(
            timetableId: _timetableId,
            existingSubjectId: _subjectChoice == _newSubject
                ? null
                : _subjectChoice,
            kind: _kind,
            courseCode: _courseCode,
            courseName: _courseName,
            seminarGroup: _seminarGroup,
            startTime: startTime,
            endTime: endTime,
            room: _room,
            teacher: _teacher,
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  DateTime _atTime(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
