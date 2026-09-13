import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muni_timetable/presentation/widgets/planner_formatters.dart';

void main() {
  testWidgets('shared date formatting follows the selected app locale', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('cs'),
        supportedLocales: [Locale('en'), Locale('cs'), Locale('sk')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: _LocalizedDate(),
      ),
    );

    final czechLabel = tester.widget<Text>(find.byType(Text)).data!;
    expect(czechLabel, isNot(contains('Sep')));

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('sk'),
        supportedLocales: [Locale('en'), Locale('cs'), Locale('sk')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: _LocalizedDate(),
      ),
    );
    final slovakLabel = tester.widget<Text>(find.byType(Text)).data!;
    expect(slovakLabel, isNot(contains('Sep')));
  });
}

class _LocalizedDate extends StatelessWidget {
  const _LocalizedDate();

  @override
  Widget build(BuildContext context) =>
      Text(compactDate(context, DateTime(2026, 9, 14)));
}
