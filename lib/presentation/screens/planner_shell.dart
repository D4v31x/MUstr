import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../providers/planner_providers.dart';
import '../localization/app_strings.dart';
import 'faculty_onboarding.dart';
import 'onboarding_screen.dart';
import 'semester_screen.dart';
import 'settings_screen.dart';
import 'subjects_screen.dart';
import 'tasks_screen.dart';
import 'today_screen.dart';
import 'week_screen.dart';
import '../widgets/app_update_dialog.dart';
import '../widgets/faculty_badge.dart';

class PlannerShell extends ConsumerStatefulWidget {
  const PlannerShell({super.key});

  @override
  ConsumerState<PlannerShell> createState() => _PlannerShellState();
}

class _PlannerShellState extends ConsumerState<PlannerShell> {
  int _tab = 0;
  String? _facultyFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        checkForAppUpdate(
          context,
          silentWhenCurrent: true,
          silentOnError: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final planner = ref.watch(plannerProvider);
    return planner.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => _ImportView(
        error: error.toString(),
        onImport: _importFile,
        onPaste: _pasteXml,
      ),
      data: (data) {
        final strings = context.strings;
        if (data.faculties.isEmpty) {
          return OnboardingScreen(language: data.language);
        }
        if (data.timetable == null) {
          return _ImportView(onImport: _importFile, onPaste: _pasteXml);
        }
        final display = data.forFaculty(_facultyFilter);
        final labels = [
          strings.today,
          strings.week,
          strings.semester,
          strings.tasks,
          strings.subjects,
        ];
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MUstr',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontFamily: 'MuniBold',
                    color: const Color(0xff005ca9),
                  ),
                ),
                Text(
                  labels[_tab],
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                tooltip: strings.filterFaculty,
                onSelected: (value) => setState(
                  () => _facultyFilter = value == 'all' ? null : value,
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'all',
                    child: Text(strings.allFaculties),
                  ),
                  ...data.faculties.map(
                    (faculty) => PopupMenuItem(
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
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: _facultyFilter == null
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffe5f0f8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              strings.all.toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontFamily: 'MuniBold',
                                    color: const Color(0xff005ca9),
                                  ),
                            ),
                          )
                        : FacultyBadge(
                            facultyId: _facultyFilter!,
                            compact: true,
                          ),
                  ),
                ),
              ),
              IconButton(
                tooltip: strings.yourFaculties,
                onPressed: () => showFacultyEditor(
                  context,
                  data.faculties.map((faculty) => faculty.id).toList(),
                ),
                icon: const Icon(Icons.account_balance_outlined),
              ),
              IconButton(
                tooltip: strings.settings,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SettingsScreen(data: data),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined),
              ),
              IconButton(
                tooltip: strings.importXml,
                onPressed: _importFile,
                icon: const Icon(Icons.upload_file_outlined),
              ),
            ],
          ),
          body: IndexedStack(
            index: _tab,
            children: [
              if (display.timetable == null)
                _FacultyEmptyView(onImport: _importFile)
              else
                TodayScreen(data: display),
              if (display.timetable == null)
                _FacultyEmptyView(onImport: _importFile)
              else
                WeekScreen(data: display),
              if (display.timetable == null)
                _FacultyEmptyView(onImport: _importFile)
              else
                SemesterScreen(data: display),
              TasksScreen(data: display),
              SubjectsScreen(data: display),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (value) => setState(() => _tab = value),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.today_outlined),
                selectedIcon: const Icon(Icons.today),
                label: strings.today,
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_view_week_outlined),
                selectedIcon: const Icon(Icons.calendar_view_week),
                label: strings.week,
              ),
              NavigationDestination(
                icon: const Icon(Icons.event_note_outlined),
                selectedIcon: const Icon(Icons.event_note),
                label: strings.semester,
              ),
              NavigationDestination(
                icon: const Icon(Icons.checklist_outlined),
                selectedIcon: const Icon(Icons.checklist),
                label: strings.tasks,
              ),
              NavigationDestination(
                icon: const Icon(Icons.auto_stories_outlined),
                selectedIcon: const Icon(Icons.auto_stories),
                label: strings.subjects,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _importFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['xml'],
    );
    if (file == null || !mounted) return;
    await _importXml(utf8.decode(await file.readAsBytes()));
  }

  Future<void> _pasteXml() async {
    final controller = TextEditingController();
    final xml = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.strings.pasteTimetableXml),
        content: TextField(
          controller: controller,
          minLines: 8,
          maxLines: 14,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.strings.import),
          ),
        ],
      ),
    );
    controller.dispose();
    if (xml != null && xml.trim().isNotEmpty) await _importXml(xml);
  }

  Future<void> _importXml(String xml) async {
    try {
      final facultyId = await _chooseFaculty();
      if (facultyId == null) return;
      final data = await ref
          .read(plannerProvider.notifier)
          .importXml(xml, facultyId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.task_alt),
          title: Text(context.strings.timetableImported),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.strings.importSummary(
                  data.timetables.last.lessons.length,
                  data.timetables.last.subjects.length,
                  data.timetables.last.semester ??
                      context.strings.importedTimetable,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(context.strings.assignedTo),
                  const SizedBox(width: 16),
                  FacultyBadge(facultyId: facultyId),
                ],
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.strings.continueLabel),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.strings.importFailed('$error'))),
      );
    }
  }

  Future<String?> _chooseFaculty() async {
    final state = ref.read(plannerProvider);
    final faculties = switch (state) {
      AsyncData(:final value) => value.faculties,
      _ => const [],
    };
    if (faculties.length == 1) return faculties.single.id;
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.strings.chooseFaculty),
        children: faculties
            .map(
              (faculty) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, faculty.id),
                child: Row(
                  children: [
                    FacultyBadge(facultyId: faculty.id),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        faculty.localizedName(context.strings.languageCode),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ImportView extends StatelessWidget {
  const _ImportView({
    required this.onImport,
    required this.onPaste,
    this.error,
  });

  final VoidCallback onImport;
  final VoidCallback onPaste;
  final String? error;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/MUNI_Time_icon.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  semanticLabel: 'MUstr',
                ),
              ),
              const SizedBox(height: 32),
              Text(
                context.strings.timetableEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                context.strings.timetableEmptyDescription,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: M3EButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(context.strings.importXml),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onPaste,
                  child: Text(context.strings.pasteXml),
                ),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => _showHowToGetXml(context),
                icon: const Icon(Icons.help_outline, size: 18),
                label: Text(context.strings.howToGetXml),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _showHowToGetXml(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    icon: const Icon(Icons.help_outline),
    title: Text(context.strings.howToGetXml),
    content: SingleChildScrollView(
      child: Text(context.strings.howToGetXmlSteps),
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.strings.continueLabel),
      ),
    ],
  ),
);

class _FacultyEmptyView extends StatelessWidget {
  const _FacultyEmptyView({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_busy_outlined, size: 48),
          const SizedBox(height: 16),
          Text(
            context.strings.noTimetableForFaculty,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            context.strings.noTimetableForFacultyDescription,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          M3EButton.icon(
            onPressed: onImport,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(context.strings.importXml),
          ),
        ],
      ),
    ),
  );
}
