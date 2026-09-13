import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../domain/entities/planner_task.dart';
import '../domain/entities/important_date.dart';
import '../domain/entities/timetable.dart';

abstract interface class ReminderScheduler {
  Future<void> initialize();
  Future<void> schedule(PlannerTask task);
  Future<void> cancel(String taskId);
  Future<void> scheduleImportantDate(ImportantDate importantDate);
  Future<void> cancelImportantDate(String importantDateId);
  Future<void> scheduleLesson(Lesson lesson);
  Future<void> cancelLesson(String lessonId);
}

class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler({FlutterLocalNotificationsPlugin? notifications})
    : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _notifications;

  @override
  Future<void> initialize() async {
    timezone_data.initializeTimeZones();
    final localZone = await FlutterTimezone.getLocalTimezone();
    timezone.setLocalLocation(timezone.getLocation(localZone.identifier));
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  @override
  Future<void> schedule(PlannerTask task) async {
    await cancel(task.id);
    final reminder = task.reminderAt;
    if (reminder == null ||
        task.isCompleted ||
        !reminder.isAfter(DateTime.now())) {
      return;
    }
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await _notifications.zonedSchedule(
      id: _idFor(task.id),
      title: 'Homework reminder',
      body: 'Due ${_dueLabel(task)}: ${task.title}',
      scheduledDate: timezone.TZDateTime.from(reminder, timezone.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'homework_reminders',
          'Homework reminders',
          channelDescription: 'Reminders for upcoming coursework deadlines.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: task.id,
    );
  }

  @override
  Future<void> cancel(String taskId) =>
      _notifications.cancel(id: _idFor(taskId));

  @override
  Future<void> scheduleImportantDate(ImportantDate importantDate) async {
    await cancelImportantDate(importantDate.id);
    final reminder = importantDate.reminderAt;
    if (reminder == null || !reminder.isAfter(DateTime.now())) return;
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await _notifications.zonedSchedule(
      id: _idFor('important-date:${importantDate.id}'),
      title: 'Important date',
      body: importantDate.title,
      scheduledDate: timezone.TZDateTime.from(reminder, timezone.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'important_date_reminders',
          'Important date reminders',
          channelDescription: 'Reminders for important academic dates.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: importantDate.id,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancelImportantDate(String importantDateId) =>
      _notifications.cancel(id: _idFor('important-date:$importantDateId'));

  @override
  Future<void> scheduleLesson(Lesson lesson) async {
    await cancelLesson(lesson.id);
    final reminder = lesson.reminderAt;
    if (reminder == null || !reminder.isAfter(DateTime.now())) return;
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await _notifications.zonedSchedule(
      id: _idFor('lesson:${lesson.id}'),
      title: 'Class reminder',
      body: '${lesson.courseCode}: ${lesson.courseName}',
      scheduledDate: timezone.TZDateTime.from(reminder, timezone.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'class_reminders',
          'Class reminders',
          channelDescription: 'Reminders for upcoming classes and seminars.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: lesson.id,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancelLesson(String lessonId) =>
      _notifications.cancel(id: _idFor('lesson:$lessonId'));

  int _idFor(String taskId) => taskId.hashCode & 0x7fffffff;

  String _dueLabel(PlannerTask task) =>
      '${task.dueDate.day}.${task.dueDate.month}.${task.dueDate.year}';
}
