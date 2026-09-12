import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../data/repositories/planner_repository.dart';
import '../providers/planner_providers.dart';
import '../localization/app_strings.dart';
import 'faculty_onboarding.dart';
import 'lesson_editor_sheet.dart';
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
  static const _newTimetableDestination = '__new_timetable__';
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

  String _defaultTimetableId(PlannerData data) {
    final matching = _facultyFilter == null
        ? data.timetables
        : data.timetables
              .where(
                (timetable) => timetable.assignedFacultyId == _facultyFilter,
              )
              .toList();
    return matching.isEmpty ? data.timetables.first.id : matching.first.id;
  }

  Future<void> _showOptionsSheet(PlannerData data) =>
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        sheetAnimationStyle: const AnimationStyle(
          duration: Duration(milliseconds: 340),
          reverseDuration: Duration(milliseconds: 220),
        ),
        builder: (sheetContext) => _ScheduleOptionsSheet(
          data: data,
          selectedFacultyId: _facultyFilter,
          onFacultySelected: (facultyId) {
            Navigator.of(sheetContext).pop();
            setState(() => _facultyFilter = facultyId);
          },
          onAddClass: () {
            Navigator.of(sheetContext).pop();
            showLessonEditor(
              context,
              data: data,
              initialTimetableId: _defaultTimetableId(data),
            );
          },
          onImport: () {
            Navigator.of(sheetContext).pop();
            _importFile();
          },
          onManageFaculties: () {
            Navigator.of(sheetContext).pop();
            showFacultyEditor(
              context,
              data.faculties.map((faculty) => faculty.id).toList(),
            );
          },
          onSettings: () {
            Navigator.of(sheetContext).pop();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(data: data),
              ),
            );
          },
        ),
      );

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
              IconButton(
                tooltip: strings.moreOptions,
                onPressed: () => _showOptionsSheet(data),
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
          body: _AnimatedTabStack(
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
    var pastedXml = '';
    final xml = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.strings.pasteTimetableXml),
        content: TextField(
          minLines: 8,
          maxLines: 14,
          autofocus: true,
          onChanged: (value) => pastedXml = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, pastedXml),
            child: Text(context.strings.import),
          ),
        ],
      ),
    );
    if (xml != null && xml.trim().isNotEmpty) await _importXml(xml);
  }

  Future<void> _importXml(String xml) async {
    try {
      final destination = await _chooseImportDestination();
      if (destination == null) return;
      final mergeIntoTimetableId = destination == _newTimetableDestination
          ? null
          : destination;
      final planner = ref.read(plannerProvider).value;
      final target = mergeIntoTimetableId == null
          ? null
          : planner?.timetables.firstWhere(
              (timetable) => timetable.id == mergeIntoTimetableId,
            );
      final facultyId = target?.assignedFacultyId ?? await _chooseFaculty();
      if (facultyId == null) return;
      final data = await ref
          .read(plannerProvider.notifier)
          .importXml(
            xml,
            facultyId,
            mergeIntoTimetableId: mergeIntoTimetableId,
          );
      if (!mounted) return;
      final imported = mergeIntoTimetableId == null
          ? data.timetables.first
          : data.timetables.firstWhere(
              (timetable) => timetable.id == mergeIntoTimetableId,
            );
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.task_alt),
          title: Text(
            mergeIntoTimetableId == null
                ? context.strings.timetableImported
                : context.strings.timetableMerged,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.strings.importSummary(
                  imported.lessons.length,
                  imported.subjects.length,
                  imported.semester ?? context.strings.importedTimetable,
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

  Future<String?> _chooseImportDestination() async {
    final data = ref.read(plannerProvider).value;
    final timetables = data?.timetables ?? const [];
    if (timetables.isEmpty) return _newTimetableDestination;
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.strings.importDestination),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, _newTimetableDestination),
            child: Row(
              children: [
                const Icon(Icons.add_rounded),
                const SizedBox(width: 16),
                Expanded(child: Text(context.strings.importAsNewTimetable)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              context.strings.mergeWithTimetable,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          ...timetables.map(
            (timetable) => SimpleDialogOption(
              onPressed: () => Navigator.pop(context, timetable.id),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      timetable.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

class _AnimatedTabStack extends StatefulWidget {
  const _AnimatedTabStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_AnimatedTabStack> createState() => _AnimatedTabStackState();
}

class _AnimatedTabStackState extends State<_AnimatedTabStack>
    with SingleTickerProviderStateMixin {
  static const _transitionDuration = Duration(milliseconds: 280);
  late final AnimationController _controller;
  late int _activeIndex;
  int? _exitingIndex;
  var _direction = 1;

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: _transitionDuration,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _AnimatedTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == _activeIndex) return;

    setState(() {
      _exitingIndex = _activeIndex;
      _direction = widget.index > _activeIndex ? 1 : -1;
      _activeIndex = widget.index;
    });
    _controller.forward(from: 0).whenComplete(() {
      if (mounted && _activeIndex == widget.index) {
        setState(() => _exitingIndex = null);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final exiting = _exitingIndex;
      return Stack(
        fit: StackFit.expand,
        children: [
          for (var index = 0; index < widget.children.length; index++)
            if (index == _activeIndex || index == exiting)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  child: RepaintBoundary(child: widget.children[index]),
                  builder: (context, child) {
                    final progress = Curves.easeOutCubic.transform(
                      _controller.value,
                    );
                    final isExiting = index == exiting;
                    final offset = isExiting
                        ? -_direction * constraints.maxWidth * progress
                        : _direction * constraints.maxWidth * (1 - progress);
                    final opacity = isExiting
                        ? 1 - (progress * 0.18)
                        : 0.82 + (progress * 0.18);
                    return IgnorePointer(
                      ignoring: isExiting,
                      child: Transform.translate(
                        offset: Offset(offset, 0),
                        child: Opacity(opacity: opacity, child: child),
                      ),
                    );
                  },
                ),
              )
            else
              Offstage(child: widget.children[index]),
        ],
      );
    },
  );
}

class _ScheduleOptionsSheet extends StatefulWidget {
  const _ScheduleOptionsSheet({
    required this.data,
    required this.selectedFacultyId,
    required this.onFacultySelected,
    required this.onAddClass,
    required this.onImport,
    required this.onManageFaculties,
    required this.onSettings,
  });

  final PlannerData data;
  final String? selectedFacultyId;
  final ValueChanged<String?> onFacultySelected;
  final VoidCallback onAddClass;
  final VoidCallback onImport;
  final VoidCallback onManageFaculties;
  final VoidCallback onSettings;

  @override
  State<_ScheduleOptionsSheet> createState() => _ScheduleOptionsSheetState();
}

class _ScheduleOptionsSheetState extends State<_ScheduleOptionsSheet> {
  var _showFilters = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Material(
        color: scheme.surfaceContainerHigh,
        elevation: 10,
        shadowColor: scheme.shadow.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _showFilters ? _filtersView() : _actionsView(),
        ),
      ),
    );
  }

  Widget _actionsView() {
    final strings = context.strings;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      key: const ValueKey('actions'),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.dashboard_customize_outlined,
                    color: scheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.scheduleLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: strings.cancel,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _PopupAction(
            icon: Icons.filter_alt_outlined,
            title: strings.filterFaculty,
            trailing: widget.selectedFacultyId == null
                ? Text(
                    strings.all,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: scheme.primary),
                  )
                : FacultyBadge(
                    facultyId: widget.selectedFacultyId!,
                    compact: true,
                  ),
            onTap: () => setState(() => _showFilters = true),
          ),
          const Divider(height: 1),
          _PopupAction(
            icon: Icons.add_circle_outline_rounded,
            title: strings.addClass,
            onTap: widget.onAddClass,
          ),
          _PopupAction(
            icon: Icons.upload_file_outlined,
            title: strings.importXml,
            onTap: widget.onImport,
          ),
          const Divider(height: 1),
          _PopupAction(
            icon: Icons.account_balance_outlined,
            title: strings.yourFaculties,
            onTap: widget.onManageFaculties,
          ),
          _PopupAction(
            icon: Icons.settings_outlined,
            title: strings.settings,
            onTap: widget.onSettings,
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }

  Widget _filtersView() {
    final strings = context.strings;
    final maxHeight = (MediaQuery.sizeOf(context).height - 112)
        .clamp(320.0, 520.0)
        .toDouble();
    return SizedBox(
      key: const ValueKey('filters'),
      width: double.infinity,
      height: maxHeight,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: strings.back,
                  onPressed: () => setState(() => _showFilters = false),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    strings.filterFaculty,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _FacultyFilterOption(
                  selected: widget.selectedFacultyId == null,
                  icon: Icons.grid_view_rounded,
                  label: strings.allFaculties,
                  onTap: () => widget.onFacultySelected(null),
                ),
                const Divider(height: 16),
                ...widget.data.faculties.map(
                  (faculty) => _FacultyFilterOption(
                    selected: widget.selectedFacultyId == faculty.id,
                    badge: FacultyBadge(facultyId: faculty.id, compact: true),
                    label: faculty.localizedName(strings.languageCode),
                    onTap: () => widget.onFacultySelected(faculty.id),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PopupAction extends StatelessWidget {
  const _PopupAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(child: Text(title)),
          ?trailing,
        ],
      ),
    ),
  );
}

class _FacultyFilterOption extends StatelessWidget {
  const _FacultyFilterOption({
    required this.selected,
    required this.label,
    required this.onTap,
    this.icon,
    this.badge,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: badge ?? Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
            if (selected)
              Icon(Icons.check_rounded, color: scheme.primary, size: 20),
          ],
        ),
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
