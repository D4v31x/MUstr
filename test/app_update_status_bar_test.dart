import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muni_timetable/presentation/widgets/app_update_dialog.dart';
import 'package:muni_timetable/services/app_update_service.dart';

void main() {
  tearDown(() {
    appUpdateController
      ..phase = AppUpdatePhase.idle
      ..release = null
      ..apk = null
      ..error = null
      ..progress = 0
      ..notifyListeners();
  });

  testWidgets('visible update bar has an overlay and bounded layout', (
    tester,
  ) async {
    appUpdateController
      ..phase = AppUpdatePhase.available
      ..release = AppRelease(
        version: '9.9.9',
        notes: '',
        apkUrl: Uri.parse('https://example.invalid/MUstr.apk'),
      );

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppUpdateHost(child: child!),
        home: const Scaffold(body: Center(child: Text('Schedule'))),
      ),
    );
    await tester.pump();

    expect(find.text('MUstr 9.9.9 is ready to install.'), findsOneWidget);
    expect(find.byType(Overlay), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
