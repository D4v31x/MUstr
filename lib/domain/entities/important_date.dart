class ImportantDate {
  const ImportantDate({
    required this.id,
    required this.title,
    required this.date,
    required this.timeMinute,
    required this.reminderAt,
    required this.facultyId,
    required this.createdAt,
  });

  final String id;
  final String title;
  final DateTime date;
  final int? timeMinute;
  final DateTime? reminderAt;
  final String? facultyId;
  final DateTime createdAt;

  DateTime get scheduledAt => timeMinute == null
      ? date
      : DateTime(
          date.year,
          date.month,
          date.day,
          timeMinute! ~/ 60,
          timeMinute! % 60,
        );
}
