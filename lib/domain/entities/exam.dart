class ExamPeriod {
  const ExamPeriod({
    required this.facultyId,
    required this.startDate,
    required this.endDate,
  });

  final String facultyId;
  final DateTime startDate;
  final DateTime endDate;
}

class Exam {
  const Exam({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.facultyId,
    required this.scheduledAt,
    required this.location,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? subjectId;
  final String facultyId;
  final DateTime scheduledAt;
  final String location;
  final String notes;
  final DateTime createdAt;

  Exam copyWith({String? subjectId, bool clearSubject = false}) => Exam(
    id: id,
    title: title,
    subjectId: clearSubject ? null : subjectId ?? this.subjectId,
    facultyId: facultyId,
    scheduledAt: scheduledAt,
    location: location,
    notes: notes,
    createdAt: createdAt,
  );
}
