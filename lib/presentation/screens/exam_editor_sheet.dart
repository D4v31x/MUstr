import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/planner_repository.dart';
import '../../domain/entities/exam.dart';
import '../providers/planner_providers.dart';
import '../widgets/faculty_badge.dart';
import '../widgets/planner_formatters.dart';
import '../localization/app_strings.dart';

Future<void> showExamEditor(
  BuildContext context, {
  required PlannerData data,
  required String initialFacultyId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _ExamEditor(data: data, initialFacultyId: initialFacultyId),
);

Future<void> showExamPeriodEditor(
  BuildContext context, {
  required PlannerData data,
  required String initialFacultyId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) =>
      _ExamPeriodEditor(data: data, initialFacultyId: initialFacultyId),
);

class _ExamEditor extends ConsumerStatefulWidget {
  const _ExamEditor({required this.data, required this.initialFacultyId});

  final PlannerData data;
  final String initialFacultyId;

  @override
  ConsumerState<_ExamEditor> createState() => _ExamEditorState();
}

class _ExamEditorState extends ConsumerState<_ExamEditor> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _notes = TextEditingController();
  late String _facultyId = widget.initialFacultyId;
  String? _subjectId;
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _notes.dispose();
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
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.addExamTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                autofocus: true,
                decoration: InputDecoration(labelText: strings.examTitle),
                validator: (value) => value == null || value.trim().isEmpty
                    ? strings.examTitleRequired
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _facultyId,
                decoration: InputDecoration(labelText: strings.faculty),
                items: widget.data.faculties
                    .map(
                      (faculty) => DropdownMenuItem(
                        value: faculty.id,
                        child: Row(
                          children: [
                            FacultyBadge(facultyId: faculty.id, compact: true),
                            const SizedBox(width: 16),
                            Text(faculty.localizedName(strings.languageCode)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _facultyId = value!;
                  _subjectId = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _subjectId,
                decoration: InputDecoration(labelText: strings.subjectOptional),
                items: [
                  DropdownMenuItem(value: null, child: Text(strings.noSubject)),
                  ...widget.data.subjects.map(
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.event_outlined),
                      label: Text(compactDate(context, _date)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text(_time.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _location,
                decoration: InputDecoration(
                  labelText: strings.roomOrOnlineLocation,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: strings.notesOptional),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(strings.saveExam),
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

  Future<void> _pickTime() async {
    final value = await showTimePicker(context: context, initialTime: _time);
    if (value != null) setState(() => _time = value);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final exam = ref
        .read(plannerProvider.notifier)
        .newExam(
          title: _title.text.trim(),
          subjectId: _subjectId,
          facultyId: _facultyId,
          scheduledAt: DateTime(
            _date.year,
            _date.month,
            _date.day,
            _time.hour,
            _time.minute,
          ),
          location: _location.text.trim(),
          notes: _notes.text.trim(),
        );
    await ref.read(plannerProvider.notifier).saveExam(exam);
    if (mounted) Navigator.pop(context);
  }
}

class _ExamPeriodEditor extends ConsumerStatefulWidget {
  const _ExamPeriodEditor({required this.data, required this.initialFacultyId});

  final PlannerData data;
  final String initialFacultyId;

  @override
  ConsumerState<_ExamPeriodEditor> createState() => _ExamPeriodEditorState();
}

class _ExamPeriodEditorState extends ConsumerState<_ExamPeriodEditor> {
  late String _facultyId = widget.initialFacultyId;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 21));

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.examPeriod,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _facultyId,
            decoration: InputDecoration(labelText: strings.faculty),
            items: widget.data.faculties
                .map(
                  (faculty) => DropdownMenuItem(
                    value: faculty.id,
                    child: Row(
                      children: [
                        FacultyBadge(facultyId: faculty.id, compact: true),
                        const SizedBox(width: 16),
                        Text(faculty.localizedName(strings.languageCode)),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _facultyId = value!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(true),
                  icon: const Icon(Icons.event_available_outlined),
                  label: Text(
                    '${strings.starts} ${compactDate(context, _start)}',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(false),
                  icon: const Icon(Icons.event_busy_outlined),
                  label: Text('${strings.ends} ${compactDate(context, _end)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: Text(strings.saveExamPeriod),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final value = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value != null) setState(() => isStart ? _start = value : _end = value);
  }

  Future<void> _save() async {
    if (_end.isBefore(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.strings.invalidExamPeriod)),
      );
      return;
    }
    await ref
        .read(plannerProvider.notifier)
        .saveExamPeriod(
          ExamPeriod(facultyId: _facultyId, startDate: _start, endDate: _end),
        );
    if (mounted) Navigator.pop(context);
  }
}
