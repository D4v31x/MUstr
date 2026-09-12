import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../domain/entities/planner_task.dart';

abstract interface class ReminderScheduler {
  Future<void> initialize();
  Future<void> schedule(PlannerTask task);
  Future<void> cancel(String taskId);
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
    if (reminder == null || task.isCompleted || !reminder.isAfter(DateTime.now())) {
      return;
    }
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
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
  Future<void> cancel(String taskId) => _notifications.cancel(id: _idFor(taskId));

  int _idFor(String taskId) => taskId.hashCode & 0x7fffffff;

  String _dueLabel(PlannerTask task) =>
      '${task.dueDate.day}.${task.dueDate.month}.${task.dueDate.year}';
}