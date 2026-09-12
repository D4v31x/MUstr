import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/repositories/planner_repository.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/entities/timetable.dart';
import '../localization/app_strings.dart';
import '../providers/planner_providers.dart';
import '../widgets/app_update_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.data});

  final PlannerData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentData = switch (ref.watch(plannerProvider)) {
      AsyncData(:final value) => value,
      _ => data,
    };
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.preferences,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            strings.settings,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _SectionTitle(
                  icon: Icons.palette_outlined,
                  title: strings.classAppearance,
                ),
                const SizedBox(height: 12),
                _TimetableKey(style: currentData.lessonStyle),
                const SizedBox(height: 12),
                _AppearanceEditor(
                  style: currentData.lessonStyle,
                  lectureLabel: strings.lecture,
                  seminarLabel: strings.seminar,
                  subtitle: strings.classAppearanceSubtitle,
                  onStyleChanged: (style) =>
                      ref.read(plannerProvider.notifier).saveLessonStyle(style),
                ),
                const SizedBox(height: 32),
                _SectionTitle(
                  icon: Icons.language_rounded,
                  title: strings.language,
                ),
                const SizedBox(height: 12),
                _LanguageEditor(
                  selected: currentData.language,
                  subtitle: strings.languageSubtitle,
                  onChanged: (language) =>
                      ref.read(plannerProvider.notifier).saveLanguage(language),
                ),
                const SizedBox(height: 32),
                _SectionTitle(
                  icon: Icons.dark_mode_outlined,
                  title: strings.theme,
                ),
                const SizedBox(height: 12),
                _ThemeModeEditor(
                  selected: currentData.themeMode,
                  subtitle: strings.themeSubtitle,
                  onChanged: (mode) =>
                      ref.read(plannerProvider.notifier).saveThemeMode(mode),
                ),
                const SizedBox(height: 32),
                _SectionTitle(icon: Icons.tune_rounded, title: strings.general),
                const SizedBox(height: 12),
                _GeneralSettings(
                  remindersEnabled: currentData.remindersEnabled,
                  showRoomInSchedule: currentData.showRoomInSchedule,
                  highlightCurrentDay: currentData.highlightCurrentDay,
                  onRemindersEnabledChanged: (value) => ref
                      .read(plannerProvider.notifier)
                      .saveRemindersEnabled(value),
                  onShowRoomInScheduleChanged: (value) => ref
                      .read(plannerProvider.notifier)
                      .saveShowRoomInSchedule(value),
                  onHighlightCurrentDayChanged: (value) => ref
                      .read(plannerProvider.notifier)
                      .saveHighlightCurrentDay(value),
                ),
                const SizedBox(height: 32),
                _SectionTitle(
                  icon: Icons.calendar_month_outlined,
                  title: strings.manageTimetables,
                ),
                const SizedBox(height: 12),
                _TimetableManager(
                  timetableCount: currentData.timetables.length,
                  subtitle: strings.manageTimetablesSubtitle,
                  onPressed: () => _showTimetableManager(context),
                ),
                const SizedBox(height: 32),
                _SectionTitle(
                  icon: Icons.info_outline_rounded,
                  title: strings.about,
                ),
                const SizedBox(height: 12),
                _AboutPanel(
                  subtitle: strings.aboutSubtitle,
                  onCheckForUpdates: () => checkForAppUpdate(context),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

const _colorChoices = <int>[
  0xff2563eb,
  0xff0f766e,
  0xffc2410c,
  0xffbe123c,
  0xff7e22ce,
  0xff475569,
];

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _TimetableKey extends StatelessWidget {
  const _TimetableKey({required this.style});

  final LessonStyleSettings style;

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
            child: _PreviewLesson(
              color: Color(style.lectureColorValue),
              title: context.strings.lecture,
              time: '08:00',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PreviewLesson(
              color: Color(style.seminarColorValue),
              title: context.strings.seminar,
              time: '10:00',
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewLesson extends StatelessWidget {
  const _PreviewLesson({
    required this.color,
    required this.title,
    required this.time,
  });

  final Color color;
  final String title;
  final String time;

  @override
  Widget build(BuildContext context) => Container(
    height: 100,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.22),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: Colors.white70),
        ),
        const Spacer(),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: Colors.white),
        ),
      ],
    ),
  );
}

class _AppearanceEditor extends StatelessWidget {
  const _AppearanceEditor({
    required this.style,
    required this.lectureLabel,
    required this.seminarLabel,
    required this.subtitle,
    required this.onStyleChanged,
  });

  final LessonStyleSettings style;
  final String lectureLabel;
  final String seminarLabel;
  final String subtitle;
  final ValueChanged<LessonStyleSettings> onStyleChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        _ColorRow(
          icon: Icons.auto_stories_outlined,
          label: lectureLabel,
          colorValue: style.lectureColorValue,
          onChanged: (colorValue) => onStyleChanged(
            LessonStyleSettings(
              lectureColorValue: colorValue,
              seminarColorValue: style.seminarColorValue,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Divider(),
        ),
        _ColorRow(
          icon: Icons.groups_2_outlined,
          label: seminarLabel,
          colorValue: style.seminarColorValue,
          onChanged: (colorValue) => onStyleChanged(
            LessonStyleSettings(
              lectureColorValue: style.lectureColorValue,
              seminarColorValue: colorValue,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.icon,
    required this.label,
    required this.colorValue,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final int colorValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(colorValue).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(colorValue)),
          ),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _colorChoices
            .map(
              (value) => _ColorSwatch(
                colorValue: value,
                selected: colorValue == value,
                label: label,
                onTap: () => onChanged(value),
              ),
            )
            .toList(),
      ),
    ],
  );
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.colorValue,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final int colorValue;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: Tooltip(
      message: label,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(colorValue),
              shape: BoxShape.circle,
            ),
            child: selected
                ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                : null,
          ),
        ),
      ),
    ),
  );
}

class _LanguageEditor extends StatelessWidget {
  const _LanguageEditor({
    required this.selected,
    required this.subtitle,
    required this.onChanged,
  });

  final AppLanguage selected;
  final String subtitle;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<AppLanguage>(
            segments: AppLanguage.values
                .map(
                  (language) => ButtonSegment(
                    value: language,
                    label: Text(language.label),
                  ),
                )
                .toList(),
            selected: {selected},
            showSelectedIcon: false,
            onSelectionChanged: (value) => onChanged(value.single),
          ),
        ),
      ],
    ),
  );
}

class _ThemeModeEditor extends StatelessWidget {
  const _ThemeModeEditor({
    required this.selected,
    required this.subtitle,
    required this.onChanged,
  });

  final AppThemeMode selected;
  final String subtitle;
  final ValueChanged<AppThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final labels = <AppThemeMode, String>{
      AppThemeMode.system: strings.themeSystem,
      AppThemeMode.light: strings.themeLight,
      AppThemeMode.dark: strings.themeDark,
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AppThemeMode>(
              segments: AppThemeMode.values
                  .map(
                    (mode) =>
                        ButtonSegment(value: mode, label: Text(labels[mode]!)),
                  )
                  .toList(),
              selected: {selected},
              showSelectedIcon: false,
              onSelectionChanged: (value) => onChanged(value.single),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneralSettings extends StatelessWidget {
  const _GeneralSettings({
    required this.remindersEnabled,
    required this.showRoomInSchedule,
    required this.highlightCurrentDay,
    required this.onRemindersEnabledChanged,
    required this.onShowRoomInScheduleChanged,
    required this.onHighlightCurrentDayChanged,
  });

  final bool remindersEnabled;
  final bool showRoomInSchedule;
  final bool highlightCurrentDay;
  final ValueChanged<bool> onRemindersEnabledChanged;
  final ValueChanged<bool> onShowRoomInScheduleChanged;
  final ValueChanged<bool> onHighlightCurrentDayChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: remindersEnabled,
            onChanged: onRemindersEnabledChanged,
            title: Text(strings.remindersEnabled),
            subtitle: Text(strings.remindersEnabledSubtitle),
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: showRoomInSchedule,
            onChanged: onShowRoomInScheduleChanged,
            title: Text(strings.showRoomInSchedule),
            subtitle: Text(strings.showRoomInScheduleSubtitle),
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: highlightCurrentDay,
            onChanged: onHighlightCurrentDayChanged,
            title: Text(strings.highlightCurrentDay),
            subtitle: Text(strings.highlightCurrentDaySubtitle),
          ),
        ],
      ),
    );
  }
}

class _AboutPanel extends StatelessWidget {
  const _AboutPanel({required this.subtitle, required this.onCheckForUpdates});

  final String subtitle;
  final VoidCallback onCheckForUpdates;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/MUNI_Time_icon.png',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MUstr',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) => Text(
                        context.strings.version(
                          snapshot.data?.version ?? '...',
                        ),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: scheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onCheckForUpdates,
            icon: const Icon(Icons.system_update_alt_rounded),
            label: Text(context.strings.checkForUpdates),
          ),
        ],
      ),
    );
  }
}

class _TimetableManager extends StatelessWidget {
  const _TimetableManager({
    required this.timetableCount,
    required this.subtitle,
    required this.onPressed,
  });

  final int timetableCount;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.calendar_month_outlined, color: scheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.strings.importedTimetables} ($timetableCount)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onPressed,
            tooltip: context.strings.manageTimetables,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

Future<void> _showTimetableManager(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _TimetableManagerSheet(),
    );

class _RenameTimetableDialog extends StatefulWidget {
  const _RenameTimetableDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameTimetableDialog> createState() => _RenameTimetableDialogState();
}

class _RenameTimetableDialogState extends State<_RenameTimetableDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name = widget.initialName;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return AlertDialog(
      title: Text(strings.renameTimetableTitle),
      content: Form(
        key: _formKey,
        child: TextFormField(
          initialValue: widget.initialName,
          autofocus: true,
          decoration: InputDecoration(labelText: strings.timetableName),
          onChanged: (value) => _name = value,
          validator: (value) => (value == null || value.trim().isEmpty)
              ? strings.timetableNameRequired
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_name.trim());
            }
          },
          child: Text(strings.save),
        ),
      ],
    );
  }
}

class _TimetableManagerSheet extends ConsumerStatefulWidget {
  const _TimetableManagerSheet();

  @override
  ConsumerState<_TimetableManagerSheet> createState() =>
      _TimetableManagerSheetState();
}

class _TimetableManagerSheetState
    extends ConsumerState<_TimetableManagerSheet> {
  final _selectedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final planner = ref.watch(plannerProvider);
    final data = switch (planner) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final strings = context.strings;
    final timetables = data?.timetables ?? const <Timetable>[];
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.82,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.importedTimetables,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                strings.manageTimetablesSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: timetables.isEmpty
                    ? Center(child: Text(strings.noImportedTimetables))
                    : ListView.separated(
                        itemCount: timetables.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final timetable = timetables[index];
                          final isSelected = _selectedIds.contains(
                            timetable.id,
                          );
                          return CheckboxListTile(
                            value: isSelected,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (selected) => setState(() {
                              if (selected ?? false) {
                                _selectedIds.add(timetable.id);
                              } else {
                                _selectedIds.remove(timetable.id);
                              }
                            }),
                            title: Text(timetable.name),
                            subtitle: Text(
                              '${timetable.semester ?? strings.importedTimetable} | ${strings.scheduledClasses(timetable.lessons.length)}',
                            ),
                            secondary: IconButton(
                              tooltip: strings.renameTimetable,
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _renameTimetable(timetable),
                            ),
                          );
                        },
                      ),
              ),
              if (_selectedIds.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: _confirmRemoval,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(
                      '${strings.removeTimetables} (${strings.selectedTimetables(_selectedIds.length)})',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _renameTimetable(Timetable timetable) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _RenameTimetableDialog(initialName: timetable.name),
    );
    if (name == null || !mounted) {
      return;
    }
    await ref
        .read(plannerProvider.notifier)
        .renameTimetable(timetable.id, name);
  }

  Future<void> _confirmRemoval() async {
    final strings = context.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: Text(strings.removeTimetables),
        content: Text(strings.removeTimetablesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.removeTimetables),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await ref
        .read(plannerProvider.notifier)
        .deleteTimetables(_selectedIds.toList());
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
