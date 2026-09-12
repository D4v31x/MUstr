import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/planner_repository.dart';
import '../localization/app_strings.dart';
import '../providers/planner_providers.dart';
import '../widgets/faculty_badge.dart';
import '../widgets/planner_formatters.dart';

Future<void> showImportantDateEditor(
  BuildContext context, {
  required PlannerData data,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _ImportantDateEditor(data: data),
);

class _ImportantDateEditor extends ConsumerStatefulWidget {
  const _ImportantDateEditor({required this.data});

  final PlannerData data;

  @override
  ConsumerState<_ImportantDateEditor> createState() =>
      _ImportantDateEditorState();
}

class _ImportantDateEditorState extends ConsumerState<_ImportantDateEditor> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  DateTime _date = DateTime.now();
  var _hasTime = false;
  var _time = const TimeOfDay(hour: 9, minute: 0);
  var _hasReminder = false;
  late DateTime _reminderDate = _date;
  var _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  String? _facultyId;

  @override
  void dispose() {
    _title.dispose();
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
                strings.addImportantDate,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: strings.importantDateTitle,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? strings.importantDateTitleRequired
                    : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(compactDate(context, _date)),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.eventTime),
                value: _hasTime,
                onChanged: (value) => setState(() => _hasTime = value),
              ),
              if (_hasTime)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text(_time.format(context)),
                  ),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _facultyId,
                decoration: InputDecoration(labelText: strings.faculty),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(strings.allFaculties),
                  ),
                  ...widget.data.faculties.map(
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
                  ),
                ],
                onChanged: (value) => setState(() => _facultyId = value),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.reminder),
                subtitle: Text(
                  _hasReminder
                      ? '${compactDate(context, _reminderDate)} ${_reminderTime.format(context)}'
                      : strings.noReminder,
                ),
                value: _hasReminder,
                onChanged: (value) => setState(() {
                  _hasReminder = value;
                  if (value) {
                    _reminderDate = _date;
                    _reminderTime = _hasTime
                        ? _time
                        : const TimeOfDay(hour: 9, minute: 0);
                  }
                }),
              ),
              if (_hasReminder)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _pickReminder,
                    icon: const Icon(Icons.notifications_outlined),
                    label: Text(strings.changeReminderTime),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(strings.saveImportantDate),
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

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (time != null) {
      setState(() {
        _reminderDate = date;
        _reminderTime = time;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final importantDate = ref
        .read(plannerProvider.notifier)
        .newImportantDate(
          title: _title.text.trim(),
          date: _date,
          timeMinute: _hasTime ? _time.hour * 60 + _time.minute : null,
          reminderAt: _hasReminder
              ? DateTime(
                  _reminderDate.year,
                  _reminderDate.month,
                  _reminderDate.day,
                  _reminderTime.hour,
                  _reminderTime.minute,
                )
              : null,
          facultyId: _facultyId,
        );
    await ref.read(plannerProvider.notifier).saveImportantDate(importantDate);
    if (mounted) Navigator.pop(context);
  }
}
