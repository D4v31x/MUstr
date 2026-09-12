import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muni_timetable/presentation/screens/about_screen.dart';

void main() {
  testWidgets('about page shows project support actions and friday recovery', (
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

    expect(find.text('Friday recovery protocol'), findsOneWidget);
    expect(
      find.text(
        'A hidden timetable scanner has been activated. It can search for a free Friday, but expectations should remain realistic.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Scan Friday'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Result: no empty Friday was found. A protected 20-minute recovery window has been reserved between classes.',
      ),
      findsOneWidget,
    );
  });
}
