import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_language.dart';
import '../../domain/entities/faculty.dart';
import '../localization/app_strings.dart';
import '../providers/planner_providers.dart';
import '../widgets/faculty_badge.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.language});

  final AppLanguage language;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _selectedFacultyIds = <String>{};
  var _analyticsConsent = false;
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              _ProgressIndicator(currentPage: _page),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _page = page),
                  children: [
                    _WelcomePage(
                      strings: strings,
                      language: widget.language,
                      onLanguageSelected: _setLanguage,
                    ),
                    _FacultyPage(
                      selectedFacultyIds: _selectedFacultyIds,
                      onChanged: _toggleFaculty,
                    ),
                    _AnalyticsPage(
                      analyticsConsent: _analyticsConsent,
                      onAnalyticsConsentChanged: (value) =>
                          setState(() => _analyticsConsent = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (_page > 0)
                    TextButton.icon(
                      onPressed: _previous,
                      icon: const Icon(Icons.arrow_back),
                      label: Text(strings.back),
                    )
                  else
                    const Spacer(),
                  const Spacer(),
                  FilledButton(
                    onPressed: _page == 1 && _selectedFacultyIds.isEmpty
                        ? null
                        : _next,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _page == 0
                              ? strings.getStarted
                              : strings.continueLabel,
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setLanguage(AppLanguage language) async {
    await ref.read(plannerProvider.notifier).saveLanguage(language);
  }

  void _toggleFaculty(String facultyId, bool selected) => setState(
    () => selected
        ? _selectedFacultyIds.add(facultyId)
        : _selectedFacultyIds.remove(facultyId),
  );

  void _previous() => _pageController.previousPage(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOut,
  );

  Future<void> _next() async {
    if (_page < 2) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return;
    }
    final controller = ref.read(plannerProvider.notifier);
    await controller.saveAnalyticsConsent(_analyticsConsent);
    await controller.saveFacultyMemberships(_selectedFacultyIds.toList());
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.currentPage});

  final int currentPage;

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(
      3,
      (index) => Expanded(
        child: Container(
          height: 4,
          margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
          decoration: BoxDecoration(
            color: index <= currentPage
                ? const Color(0xff005ca9)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    ),
  );
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    required this.strings,
    required this.language,
    required this.onLanguageSelected,
  });

  final AppStrings strings;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageSelected;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/MUNI_Time_icon.png',
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            semanticLabel: 'MUstr',
          ),
        ),
        const SizedBox(height: 32),
        Text(
          strings.welcomeTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 16),
        Text(
          strings.welcomeDescription,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        DropdownButtonFormField<AppLanguage>(
          initialValue: language,
          menuMaxHeight: 320,
          decoration: InputDecoration(
            labelText: strings.language,
            prefixIcon: const Icon(Icons.translate_rounded),
          ),
          items: AppLanguage.values
              .map(
                (item) =>
                    DropdownMenuItem(value: item, child: Text(item.label)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onLanguageSelected(value);
          },
        ),
      ],
    ),
  );
}

class _FacultyPage extends StatelessWidget {
  const _FacultyPage({
    required this.selectedFacultyIds,
    required this.onChanged,
  });

  final Set<String> selectedFacultyIds;
  final void Function(String facultyId, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          strings.whereStudying,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          strings.selectFaculties,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: MuniFaculties.all.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final faculty = MuniFaculties.all[index];
              final selected = selectedFacultyIds.contains(faculty.id);
              return Material(
                color: selected
                    ? faculty.color.withValues(alpha: 0.16)
                    : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(8),
                child: CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  value: selected,
                  onChanged: (value) => onChanged(faculty.id, value ?? false),
                  activeColor: faculty.color,
                  title: Text(
                    faculty.localizedName(strings.languageCode),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  secondary: FacultyBadge(facultyId: faculty.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AnalyticsPage extends StatelessWidget {
  const _AnalyticsPage({
    required this.analyticsConsent,
    required this.onAnalyticsConsentChanged,
  });

  final bool analyticsConsent;
  final ValueChanged<bool> onAnalyticsConsentChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insights_outlined, size: 40, color: scheme.primary),
          const SizedBox(height: 20),
          Text(
            strings.analyticsConsent,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            strings.analyticsConsentDescription,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Material(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            child: CheckboxListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              value: analyticsConsent,
              onChanged: (value) => onAnalyticsConsentChanged(value ?? false),
              title: Text(strings.analyticsConsent),
              subtitle: Text(strings.analyticsConsentSubtitle),
            ),
          ),
        ],
      ),
    );
  }
}
