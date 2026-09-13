import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/planner_repository.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/entities/timetable.dart';
import '../localization/app_strings.dart';
import '../providers/planner_providers.dart';
import 'about_screen.dart';
import 'schedule_colors_screen.dart';

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
                Text(
                  'MUstr',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontFamily: 'MuniBold',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.settings,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  strings.settingsDescription,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                _SectionTitle(
                  icon: Icons.palette_outlined,
                  title: strings.classAppearance,
                ),
                const SizedBox(height: 12),
                _SettingsPanel(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.tune_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(strings.changeColors),
                    subtitle: Text(strings.classAppearanceSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ScheduleColorsScreen(data: currentData),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _SectionTitle(
                  icon: Icons.tune_rounded,
                  title: strings.displaySettings,
                ),
                const SizedBox(height: 12),
                _SettingsPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LanguageEditor(
                        selected: currentData.language,
                        subtitle: strings.languageSubtitle,
                        onChanged: (language) => ref
                            .read(plannerProvider.notifier)
                            .saveLanguage(language),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(),
                      ),
                      _ThemeModeEditor(
                        selected: currentData.themeMode,
                        subtitle: strings.themeSubtitle,
                        onChanged: (mode) => ref
                            .read(plannerProvider.notifier)
                            .saveThemeMode(mode),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(),
                      ),
                      _ColorThemeEditor(
                        selected: currentData.colorTheme,
                        title: strings.colorTheme,
                        subtitle: strings.colorThemeSubtitle,
                        labels: {
                          AppColorTheme.materialYou: strings.materialYou,
                          AppColorTheme.muniBlue: strings.muniBlue,
                          AppColorTheme.emerald: strings.emerald,
                          AppColorTheme.coral: strings.coral,
                        },
                        onChanged: (theme) => ref
                            .read(plannerProvider.notifier)
                            .saveColorTheme(theme),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _SectionTitle(icon: Icons.tune_rounded, title: strings.general),
                const SizedBox(height: 12),
                _GeneralSettings(
                  remindersEnabled: currentData.remindersEnabled,
                  showRoomInSchedule: currentData.showRoomInSchedule,
                  highlightCurrentDay: currentData.highlightCurrentDay,
                  analyticsConsent: currentData.analyticsConsent,
                  onRemindersEnabledChanged: (value) => ref
                      .read(plannerProvider.notifier)
                      .saveRemindersEnabled(value),
                  onShowRoomInScheduleChanged: (value) => ref
                      .read(plannerProvider.notifier)
                      .saveShowRoomInSchedule(value),
                  onHighlightCurrentDayChanged: (value) => ref
                      .read(plannerProvider.notifier)
                      .saveHighlightCurrentDay(value),
                  onAnalyticsConsentChanged: (value) => ref
                      .read(plannerProvider.notifier)
                      .saveAnalyticsConsent(value),
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
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AboutScreen(),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

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

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.child});

  final Widget child;

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
      child: child,
    );
  }
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
  Widget build(BuildContext context) => Column(
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
                (language) =>
                    ButtonSegment(value: language, label: Text(language.label)),
              )
              .toList(),
          selected: {selected},
          showSelectedIcon: false,
          onSelectionChanged: (value) => onChanged(value.single),
        ),
      ),
    ],
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
    return Column(
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
    );
  }
}

class _ColorThemeEditor extends StatelessWidget {
  const _ColorThemeEditor({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.labels,
    required this.onChanged,
  });

  final AppColorTheme selected;
  final String title;
  final String subtitle;
  final Map<AppColorTheme, String> labels;
  final ValueChanged<AppColorTheme> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<AppColorTheme>(
        initialValue: selected,
        isExpanded: true,
        menuMaxHeight: 320,
        decoration: const InputDecoration(),
        items: AppColorTheme.values
            .map(
              (theme) => DropdownMenuItem(
                value: theme,
                child: Row(
                  children: [
                    if (theme.seedColor == null)
                      const Icon(Icons.palette_outlined)
                    else
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.seedColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Text(labels[theme]!),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (theme) {
          if (theme != null) onChanged(theme);
        },
      ),
    ],
  );
}

class _GeneralSettings extends StatelessWidget {
  const _GeneralSettings({
    required this.remindersEnabled,
    required this.showRoomInSchedule,
    required this.highlightCurrentDay,
    required this.analyticsConsent,
    required this.onRemindersEnabledChanged,
    required this.onShowRoomInScheduleChanged,
    required this.onHighlightCurrentDayChanged,
    required this.onAnalyticsConsentChanged,
  });

  final bool remindersEnabled;
  final bool showRoomInSchedule;
  final bool highlightCurrentDay;
  final bool analyticsConsent;
  final ValueChanged<bool> onRemindersEnabledChanged;
  final ValueChanged<bool> onShowRoomInScheduleChanged;
  final ValueChanged<bool> onHighlightCurrentDayChanged;
  final ValueChanged<bool> onAnalyticsConsentChanged;

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
          const Divider(height: 1),
          SwitchListTile(
            value: analyticsConsent,
            onChanged: onAnalyticsConsentChanged,
            title: Text(strings.analyticsConsent),
            subtitle: Text(strings.analyticsConsentSubtitle),
          ),
        ],
      ),
    );
  }
}

class _AboutPanel extends StatelessWidget {
  const _AboutPanel({required this.subtitle, required this.onPressed});

  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
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
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
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
