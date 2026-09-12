import 'package:flutter/material.dart';

import '../../domain/entities/faculty.dart';

class FacultyBadge extends StatelessWidget {
  const FacultyBadge({super.key, required this.facultyId, this.compact = false});

  final String facultyId;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final faculty = MuniFaculties.byId(facultyId);
    final color = faculty?.color ?? const Color(0xff005ca9);
    final size = compact ? 34.0 : 48.0;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            faculty?.shortName ?? facultyId.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              color: faculty?.id == 'fi' ? Colors.black : Colors.white,
              fontFamily: 'MuniBold',
              fontSize: compact ? 12 : 14,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}