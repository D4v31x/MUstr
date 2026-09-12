import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muni_timetable/presentation/widgets/planner_formatters.dart';

void main() {
  test('uses the most readable text color on a lesson background', () {
    expect(readableTextColor(const Color(0xff005ca9)), Colors.white);
    expect(readableTextColor(const Color(0xffffefb0)), Colors.black);
  });

  test('adjusts an unreadable accent toward the supplied foreground', () {
    final color = readableAccentColor(
      const Color(0xff102030),
      const Color(0xff005ca9),
      fallback: Colors.white,
    );

    expect(
      _contrastRatio(color, const Color(0xff005ca9)),
      greaterThanOrEqualTo(4.5),
    );
  });
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
