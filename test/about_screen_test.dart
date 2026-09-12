import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muni_timetable/presentation/screens/about_screen.dart';

void main() {
  testWidgets('about page shows project support actions and easter egg', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Source code'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget);
    expect(find.text('Share feedback or an idea'), findsOneWidget);
    expect(find.text('Open-source licenses'), findsOneWidget);

    final logo = find.byKey(const ValueKey('about-logo'));
    expect(logo, findsOneWidget);
    for (var tap = 0; tap < 7; tap++) {
      await tester.tap(logo);
    }
    await tester.pumpAndSettle();

    expect(find.text('Schedule diagnostics'), findsOneWidget);
    expect(
      find.text(
        'Seven taps detected. Unfortunately, no free Friday was found.',
      ),
      findsOneWidget,
    );
  });
}
