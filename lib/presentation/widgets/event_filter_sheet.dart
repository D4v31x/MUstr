import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/timetable.dart';
import '../localization/app_strings.dart';
import '../providers/planner_providers.dart';

Future<void> showEventFilterSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _EventFilterSheet(),
    );

class _EventFilterSheet extends ConsumerWidget {
  const _EventFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final data = ref.watch(plannerProvider).value;
    if (data == null) {
      return const SizedBox.shrink();
    }
    final filter = data.eventFilter;
    final notifier = ref.read(plannerProvider.notifier);
    final subjects = <String, Subject>{
      for (final timetable in data.timetables.where(
        (item) => item.isWebcalSynced,
      ))
        for (final subject in timetable.subjects) subject.id: subject,
    }.values.toList()..sort((a, b) => a.courseCode.compareTo(b.courseCode));
    final labels = {
      FeedCategory.lecture: strings.feedLectures,
      FeedCategory.seminar: strings.feedSeminars,
      FeedCategory.exam: strings.feedExams,
      FeedCategory.quiz: strings.feedQuizzes,
      FeedCategory.deadline: strings.feedDeadlines,
      FeedCategory.other: strings.feedOther,
    };
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.82,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.calendarFilters,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (!filter.isEmpty)
                  TextButton(
                    onPressed: () =>
                        notifier.saveEventFilter(const FeedFilter()),
                    child: Text(strings.showAllEvents),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              strings.calendarFiltersSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.calendarEventTypes,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final entry in labels.entries)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.value),
                value: !filter.hiddenCategories.contains(entry.key),
                onChanged: (visible) => notifier.saveEventFilter(
                  filter.withCategory(entry.key, visible: visible),
                ),
              ),
            if (subjects.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                strings.calendarSubjects,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              for (final subject in subjects)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(subject.courseCode),
                  subtitle: Text(subject.name),
                  value: !filter.hiddenSubjectIds.contains(subject.id),
                  onChanged: (visible) => notifier.saveEventFilter(
                    filter.withSubject(subject.id, visible: visible),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
