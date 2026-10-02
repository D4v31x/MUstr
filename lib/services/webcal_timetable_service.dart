import 'dart:convert';
import 'dart:io';

import 'package:firstfloor_calendar/firstfloor_calendar.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../domain/entities/faculty.dart';
import '../domain/entities/timetable.dart';

class WebcalSyncException implements Exception {
  const WebcalSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

enum WebcalImportStage { downloading, reading, saving }

class WebcalImportProgress {
  const WebcalImportProgress(
    this.stage, {
    this.receivedBytes,
    this.totalBytes,
    this.eventCount,
  });

  final WebcalImportStage stage;
  final int? receivedBytes;
  final int? totalBytes;
  final int? eventCount;
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
    void Function(WebcalImportProgress progress)? onProgress,
  }) async {
    final url = normalizeUrl(rawUrl);
    final client = _clientFactory();
    client.connectionTimeout = const Duration(seconds: 15);
    try {
      onProgress?.call(
        const WebcalImportProgress(WebcalImportStage.downloading),
      );
      final request = await client.getUrl(url);
      request.headers.set(HttpHeaders.acceptHeader, 'text/calendar');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw WebcalSyncException(
          'Calendar server returned HTTP ${response.statusCode}.',
        );
      }
      var received = 0;
      final total = response.contentLength > 0 ? response.contentLength : null;
      final chunks = response.map((chunk) {
        received += chunk.length;
        onProgress?.call(
          WebcalImportProgress(
            WebcalImportStage.downloading,
            receivedBytes: received,
            totalBytes: total,
          ),
        );
        return chunk;
      });
      final source = await utf8.decoder.bind(chunks).join();
      onProgress?.call(const WebcalImportProgress(WebcalImportStage.reading));
      // Let the progress UI repaint before the synchronous parse.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final timetable = parse(
        source,
        facultyId: facultyId,
        webcalUrl: url.toString(),
        syncedAt: syncedAt,
      );
      onProgress?.call(
        WebcalImportProgress(
          WebcalImportStage.reading,
          eventCount: timetable.lessons.length,
        ),
      );
      return timetable;
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
    final entries = <_FeedEntry>[];
    final seen = <String>{};

    for (final event in calendar.events) {
      final eventStart = event.dtstart?.native;
      if (eventStart == null || event.isAllDay) {
        continue;
      }
      final summary = event.summary?.trim() ?? '';
      if (summary.isEmpty) {
        continue;
      }
      final info = _classify(summary);
      final eventEnd = event.dtend?.native;
      // Quizzes, deadlines and exam terms mark a moment, not a time span.
      final duration = eventEnd == null || !eventEnd.isAfter(eventStart)
          ? (info.isClass ? const Duration(hours: 1) : Duration.zero)
          : eventEnd.difference(eventStart);
      for (final occurrence in event.occurrences(
        start: occurrenceStart,
        end: occurrenceEnd,
      )) {
        final start = _wallClock(occurrence.native);
        final signature = '${event.uid}#${start.toIso8601String()}';
        if (!seen.add(signature)) {
          continue;
        }
        entries.add(
          _FeedEntry(
            id: 'webcal:$signature',
            start: start,
            end: start.add(duration),
            location: event.location?.trim() ?? '',
            info: info,
          ),
        );
      }
    }
    if (entries.isEmpty) {
      throw const WebcalSyncException(
        'No timed classes were found in this calendar.',
      );
    }

    // Quizzes and deadlines name only a course code, so reuse the class names.
    final classNames = <String, _CourseRef>{
      for (final entry in entries.where((item) => item.info.isClass))
        entry.info.code.toLowerCase(): _CourseRef(
          entry.info.code,
          entry.info.name ?? entry.info.code,
        ),
    };
    final subjects = <String, Subject>{};
    final lessons = <Lesson>[];
    entries.sort((first, second) => first.start.compareTo(second.start));
    for (final entry in entries) {
      final info = entry.info;
      final known = _knownCourse(info.code, classNames);
      final code = known?.code ?? info.code;
      final name = known?.name ?? info.name ?? code;
      final subjectId = 'webcal:$facultyId:${code.toLowerCase()}';
      final courseFaculty = _courseFaculty(code) ?? facultyId;
      subjects.putIfAbsent(
        subjectId,
        () => Subject(
          id: subjectId,
          courseCode: code,
          name: name,
          subjectId: null,
          faculty: courseFaculty,
        ),
      );
      lessons.add(
        Lesson(
          id: entry.id,
          date: DateTime(entry.start.year, entry.start.month, entry.start.day),
          startTime: entry.start,
          endTime: entry.end,
          subjectKey: subjectId,
          courseCode: code,
          seminarGroup: info.group,
          kind: info.kind,
          priority: LessonPriority.normal,
          customColorValue: null,
          courseName: info.isClass ? name : info.title,
          subjectId: null,
          faculty: courseFaculty,
          timetableFacultyId: courseFaculty,
          semester: null,
          rooms: entry.location.isEmpty
              ? const []
              : [Room(id: null, name: entry.location)],
          teachers: const [],
          feedCategory: info.category,
        ),
      );
    }
    final sortedSubjects = subjects.values.toList()
      ..sort((first, second) => first.courseCode.compareTo(second.courseCode));
    return Timetable(
      id: 'webcal:${webcalUrl.hashCode}',
      name: 'Synced calendar',
      assignedFacultyId: facultyId,
      semester: null,
      importedAt: now,
      lessons: List.unmodifiable(lessons),
      subjects: List.unmodifiable(sortedSubjects),
      webcalUrl: webcalUrl,
      lastSyncedAt: now,
    );
  }

  // Course-code prefixes known to belong to one faculty or the whole university.
  static final _courseFaculties = <RegExp, String>{
    RegExp(r'^BSS', caseSensitive: false): 'fss',
    RegExp(r'^AUT_', caseSensitive: false): MuniFaculties.universityWideId,
  };

  static String? _courseFaculty(String code) => _courseFaculties.entries
      .where((rule) => rule.key.hasMatch(code))
      .map((rule) => rule.value)
      .firstOrNull;

  // The calendar package yields Prague-zone values; the app stores wall-clock
  // time, like the XML import, so an offset suffix never shifts the hour.
  static DateTime _wallClock(DateTime value) => value.isUtc
      ? value.toLocal()
      : DateTime(
          value.year,
          value.month,
          value.day,
          value.hour,
          value.minute,
          value.second,
        );

  static _CourseRef? _knownCourse(String code, Map<String, _CourseRef> known) {
    final lower = code.toLowerCase();
    final exact = known[lower];
    if (exact != null) {
      return exact;
    }
    _CourseRef? best;
    for (final entry in known.entries) {
      if (lower.startsWith(entry.key) &&
          (best == null || entry.value.code.length > best.code.length)) {
        best = entry.value;
      }
    }
    return best;
  }

  // "Name – CODE/group (seminář v A219)"
  static final _classPattern = RegExp(
    r'^(.+)\s+[–-]\s+([^\s/()]+)(?:/([^\s(]+))?\s*\(([^)]*)\)$',
  );
  // "Zkušební termín (CODE – Name)" and "Odpovědník otevřen (CODE: detail)"
  static final _eventPattern = RegExp(
    r'^(.+?)\s*\(([^\s:–()-]+)\s*(?::|[–-])\s*(.+)\)$',
  );
  static final _codePattern = RegExp(r'\b[A-Z]{2,}[0-9]{2,}\b');

  _FeedInfo _classify(String summary) {
    final classMatch = _classPattern.firstMatch(summary);
    if (classMatch != null) {
      final seminar = _isSeminar(classMatch.group(4)!);
      return _FeedInfo(
        code: classMatch.group(2)!,
        name: classMatch.group(1)!.trim(),
        title: summary,
        group: classMatch.group(3),
        kind: seminar ? LessonKind.seminar : LessonKind.lecture,
        category: seminar ? FeedCategory.seminar : FeedCategory.lecture,
        isClass: true,
      );
    }
    final eventMatch = _eventPattern.firstMatch(summary);
    if (eventMatch != null) {
      final prefix = eventMatch.group(1)!.trim();
      final detail = eventMatch.group(3)!.trim();
      final category = _eventCategory(prefix);
      final detailIsName =
          category == FeedCategory.exam || category == FeedCategory.deadline;
      return _FeedInfo(
        code: eventMatch.group(2)!,
        name: detailIsName ? detail : null,
        title: detailIsName ? prefix : '$prefix: $detail',
        group: null,
        kind: LessonKind.event,
        category: category,
        isClass: false,
      );
    }
    final code = _codePattern.firstMatch(summary)?.group(0);
    if (code == null) {
      return _FeedInfo(
        code: summary,
        name: summary,
        title: summary,
        group: null,
        kind: LessonKind.event,
        category: FeedCategory.other,
        isClass: false,
      );
    }
    final name = summary
        .replaceFirst(code, '')
        .replaceFirst(RegExp(r'^\s*[-:|]\s*'), '')
        .trim();
    final seminar = _isSeminar(summary);
    return _FeedInfo(
      code: code,
      name: name.isEmpty ? code : name,
      title: summary,
      group: _seminarGroup(summary),
      kind: seminar ? LessonKind.seminar : LessonKind.lecture,
      category: seminar ? FeedCategory.seminar : FeedCategory.lecture,
      isClass: true,
    );
  }

  static FeedCategory _eventCategory(String prefix) {
    final text = prefix.toLowerCase();
    if (RegExp(r'odhlašov|deregist|unregist').hasMatch(text)) {
      return FeedCategory.deadline;
    }
    if (RegExp(r'zkušební termín|exam').hasMatch(text)) {
      return FeedCategory.exam;
    }
    if (RegExp(r'odpovědník|quiz').hasMatch(text)) {
      return FeedCategory.quiz;
    }
    return FeedCategory.other;
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

class _CourseRef {
  const _CourseRef(this.code, this.name);

  final String code;
  final String name;
}

class _FeedInfo {
  const _FeedInfo({
    required this.code,
    required this.name,
    required this.title,
    required this.group,
    required this.kind,
    required this.category,
    required this.isClass,
  });

  final String code;
  final String? name;
  final String title;
  final String? group;
  final LessonKind kind;
  final FeedCategory category;
  final bool isClass;
}

class _FeedEntry {
  const _FeedEntry({
    required this.id,
    required this.start,
    required this.end,
    required this.location,
    required this.info,
  });

  final String id;
  final DateTime start;
  final DateTime end;
  final String location;
  final _FeedInfo info;
}
