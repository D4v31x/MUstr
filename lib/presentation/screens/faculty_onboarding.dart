import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/faculty.dart';
import '../providers/planner_providers.dart';
import '../widgets/faculty_badge.dart';
import '../localization/app_strings.dart';

class FacultyOnboarding extends ConsumerStatefulWidget {
  const FacultyOnboarding({
    super.key,
    required this.selectedFacultyIds,
    this.isEditing = false,
  });

  final List<String> selectedFacultyIds;
  final bool isEditing;

  @override
  ConsumerState<FacultyOnboarding> createState() => _FacultyOnboardingState();
}

class _FacultyOnboardingState extends ConsumerState<FacultyOnboarding> {
  late final Set<String> _selected = widget.selectedFacultyIds.toSet();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strings = context.strings;
    return Scaffold(
      appBar: widget.isEditing
          ? AppBar(title: Text(strings.yourFaculties))
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isEditing) ...[
                Text(
                  'MUNI',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontFamily: 'MuniBold',
                    color: const Color(0xff005ca9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.whereStudying,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(strings.selectFaculties),
              ],
              if (widget.isEditing) Text(strings.selectFaculties),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: MuniFaculties.all.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final faculty = MuniFaculties.all[index];
                    final selected = _selected.contains(faculty.id);
                    return Material(
                      color: selected
                          ? faculty.color.withValues(alpha: 0.20)
                          : scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      child: CheckboxListTile(
                        value: selected,
                        activeColor: faculty.color,
                        onChanged: (value) => setState(
                          () => value == true
                              ? _selected.add(faculty.id)
                              : _selected.remove(faculty.id),
                        ),
                        title: Text(
                          faculty.localizedName(strings.languageCode),
                        ),
                        subtitle: Text(strings.muniFaculty),
                        secondary: FacultyBadge(facultyId: faculty.id),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selected.isEmpty ? null : _save,
                  child: Text(
                    widget.isEditing
                        ? strings.saveFaculties
                        : strings.continueLabel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    await ref
        .read(plannerProvider.notifier)
        .saveFacultyMemberships(_selected.toList());
    if (mounted && widget.isEditing) Navigator.pop(context);
  }
}

Future<void> showFacultyEditor(
  BuildContext context,
  List<String> selectedFacultyIds,
) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => FacultyOnboarding(
      selectedFacultyIds: selectedFacultyIds,
      isEditing: true,
    ),
  ),
);
