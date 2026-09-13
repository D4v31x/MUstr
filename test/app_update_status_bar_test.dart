import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muni_timetable/presentation/widgets/app_update_dialog.dart';
import 'package:muni_timetable/presentation/screens/update_check_screen.dart';
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

  testWidgets('available update is shown in the dedicated update screen', (
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
      MaterialApp(home: const UpdateCheckScreen(autoStart: false)),
    );
    await tester.pump();

    expect(find.text('MUstr 9.9.9 is ready to install.'), findsOneWidget);
    expect(find.text('MUstr'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
