import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muni_timetable/presentation/widgets/faculty_badge.dart';

void main() {
  testWidgets('faculty badge keeps its intrinsic width inside a checkbox tile', (tester) async {
    await tester.binding.setSurfaceSize(const Size(411, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CheckboxListTile(
            value: false,
            onChanged: (_) {},
            title: const Text('Fakulta informatiky'),
            secondary: const FacultyBadge(facultyId: 'fi'),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(FacultyBadge)), const Size(48, 48));
  });
}