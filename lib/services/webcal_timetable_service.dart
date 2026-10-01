import 'dart:convert';
import 'dart:io';

import 'package:firstfloor_calendar/firstfloor_calendar.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../domain/entities/timetable.dart';

class WebcalSyncException implements Exception {
  const WebcalSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WebcalTimetableService {
  WebcalTimetableService({HttpClient Function()? clientFactory})
    : _clientFactory = clientFactory ?? HttpClient.new;

  final HttpClient Function() _clientFactory;

  static Uri normalizeUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.host.isEmpty) {
      throw const WebcalSyncException('Enter a valid webcal calendar URL.');
    }
    if (uri.scheme == 'webcal') {
      return uri.replace(scheme: 'https');
    }
    if (uri.scheme == 'https') {
      return uri;
    }
    throw const WebcalSyncException(
      'Use a webcal:// or https:// calendar URL.',
    );
  }

  Future<Timetable> download(
    String rawUrl, {
    required String facultyId,
    DateTime? syncedAt,
  }) async {
    final url = normalizeUrl(rawUrl);
    final client = _clientFactory();
    client.connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(url);
      request.headers.set(HttpHeaders.acceptHeader, 'text/calendar');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw WebcalSyncException(
          'Calendar server returned HTTP ${response.statusCode}.',
        );
      }
      final source = await utf8.decoder.bind(response).join();
      return parse(
        source,
        facultyId: facultyId,
        webcalUrl: url.toString(),
        syncedAt: syncedAt,
      );
    } on WebcalSyncException {
      rethrow;
    } on SocketException catch (_) {
      throw const WebcalSyncException('Could not reach the calendar server.');
    } on HttpException catch (_) {
      throw const WebcalSyncException('Could not download the calendar.');
    } catch (_) {
      throw const WebcalSyncException('Could not read the calendar feed.');
    } finally {
      client.close(force: true);
    }
  }

  Timetable parse(
    String source, {
    required String facultyId,
    required String webcalUrl,
    DateTime? syncedAt,
  }) {
    tz.initializeTimeZones();
    final Calendar calendar;
    try {
      calendar = CalendarParser().parseFromString(source);
    } catch (_) {
      throw const WebcalSyncException(
        'This URL does not contain a valid calendar.',
      );
    }

    final now = syncedAt ?? DateTime.now();
    final rangeStart = DateTime(now.year - 1, 1, 1);
    final rangeEnd = DateTime(now.year + 2, 1, 1);
    final occurrenceStart = CalDateTime.local(
      rangeStart.year,
      rangeStart.month,
      rangeStart.day,
    );
    final occurrenceEnd = CalDateTime.local(
      rangeEnd.year,
      rangeEnd.month,
      rangeEnd.day,
    );
    final lessons = <Lesson>[];
    final seen = <String>{};

    for (final event in calendar.events) {
      final eventStart = event.dtstart?.native;
      if (eventStart == null || event.isAllDay) {
        continue;
      }
      final eventEnd = event.dtend?.native;
      final duration = eventEnd == null || !eventEnd.isAfter(eventStart)
          ? const Duration(hours: 1)
          : eventEnd.difference(eventStart);
      for (final occurrence in event.occurrences(
        start: occurrenceStart,
        end: occurrenceEnd,
      )) {
        final start = occurrence.native;
        final end = start.add(duration);
        final summary = event.summary?.trim() ?? '';
        if (summary.isEmpty || !end.isAfter(start)) {
          continue;
        }
        final subject = _subjectFor(summary, facultyId);
        final signature = '${event.uid}#${start.toIso8601String()}';
        if (!seen.add(signature)) {
          continue;
        }
        lessons.add(
          Lesson(
            id: 'webcal:$signature',
            date: DateTime(start.year, start.month, start.day),
            startTime: start,
            endTime: end,
            subjectKey: subject.id,
            courseCode: subject.courseCode,
            seminarGroup: _seminarGroup(summary),
            kind: _isSeminar(summary) ? LessonKind.seminar : LessonKind.lecture,
            priority: LessonPriority.normal,
            customColorValue: null,
            courseName: subject.name,
            subjectId: null,
            faculty: facultyId,
            timetableFacultyId: facultyId,
            semester: null,
            rooms: event.location?.trim().isEmpty ?? true
                ? const []
                : [Room(id: null, name: event.location!.trim())],
            teachers: const [],
          ),
        );
      }
    }
    lessons.sort(
      (first, second) => first.startTime.compareTo(second.startTime),
    );
    if (lessons.isEmpty) {
      throw const WebcalSyncException(
        'No timed classes were found in this calendar.',
      );
    }
    final subjects =
        <String, Subject>{
          for (final lesson in lessons)
            lesson.subjectKey: Subject(
              id: lesson.subjectKey,
              courseCode: lesson.courseCode,
              name: lesson.courseName,
              subjectId: null,
              faculty: facultyId,
            ),
        }.values.toList()..sort(
          (first, second) => first.courseCode.compareTo(second.courseCode),
        );
    return Timetable(
      id: 'webcal:${webcalUrl.hashCode}',
      name: 'Synced calendar',
      assignedFacultyId: facultyId,
      semester: null,
      importedAt: now,
      lessons: List.unmodifiable(lessons),
      subjects: List.unmodifiable(subjects),
      webcalUrl: webcalUrl,
      lastSyncedAt: now,
    );
  }

  Subject _subjectFor(String summary, String facultyId) {
    final code = RegExp(
      r'\b[A-Z]{2,}[0-9]{2,}\b',
    ).firstMatch(summary)?.group(0);
    final courseCode = code ?? summary;
    final name = code == null
        ? summary
        : summary
              .replaceFirst(code, '')
              .replaceFirst(RegExp(r'^\s*[-:|]\s*'), '')
              .trim();
    return Subject(
      id: 'webcal:$facultyId:${courseCode.toLowerCase()}',
      courseCode: courseCode,
      name: name.isEmpty ? courseCode : name,
      subjectId: null,
      faculty: facultyId,
    );
  }

  bool _isSeminar(String summary) =>
      RegExp(r'semin[aá]ř|seminar', caseSensitive: false).hasMatch(summary);

  String? _seminarGroup(String summary) {
    final match = RegExp(
      r'(?:semin[aá]ř|seminar)\s*[-:]?\s*([^|,]+)',
      caseSensitive: false,
    ).firstMatch(summary);
    final group = match?.group(1)?.trim();
    return group == null || group.isEmpty ? null : group;
  }
}
