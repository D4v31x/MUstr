enum TaskPriority { low, normal, high }

class PlannerTask {
  const PlannerTask({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectId,
    required this.dueDate,
    required this.dueMinute,
    required this.reminderAt,
    required this.priority,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String? subjectId;
  final DateTime dueDate;
  final int? dueMinute;
  final DateTime? reminderAt;
  final TaskPriority priority;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  DateTime get dueAt => DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        dueMinute == null ? 23 : dueMinute! ~/ 60,
        dueMinute == null ? 59 : dueMinute! % 60,
      );

  bool get isOverdue => !isCompleted && dueAt.isBefore(DateTime.now());

  PlannerTask copyWith({
    String? title,
    String? description,
    String? subjectId,
    bool clearSubject = false,
    DateTime? dueDate,
    int? dueMinute,
    bool clearDueMinute = false,
    DateTime? reminderAt,
    bool clearReminder = false,
    TaskPriority? priority,
    bool? isCompleted,
    DateTime? updatedAt,
  }) =>
      PlannerTask(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        subjectId: clearSubject ? null : subjectId ?? this.subjectId,
        dueDate: dueDate ?? this.dueDate,
        dueMinute: clearDueMinute ? null : dueMinute ?? this.dueMinute,
        reminderAt: clearReminder ? null : reminderAt ?? this.reminderAt,
        priority: priority ?? this.priority,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}