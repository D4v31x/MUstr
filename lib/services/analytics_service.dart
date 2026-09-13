import 'package:posthog_flutter/posthog_flutter.dart';

class AnalyticsService {
  static const _projectToken =
      'phc_xF79NW2eWHsvouoeadmqaSGJZP2XbP2r4wvvCWmUVZUa';
  static const _host = 'https://eu.i.posthog.com';

  String? _lastProfileSignature;
  var _isInitialized = false;

  Future<void> initialize() async {
    try {
      final config = PostHogConfig(_projectToken)
        ..host = _host
        ..optOut = true
        ..debug = false
        ..captureApplicationLifecycleEvents = false
        ..capturePushNotificationSubscriptions = false
        ..capturePushNotificationOpened = false
        ..preloadFeatureFlags = false
        ..sendFeatureFlagEvents = false
        ..surveys = false;
      await Posthog().setup(config);
      _isInitialized = true;
    } catch (_) {
      _isInitialized = false;
    }
  }

  Future<void> configure({
    required bool consentGranted,
    required String? installationId,
    required Iterable<String> facultyIds,
  }) async {
    if (!_isInitialized) return;
    try {
      if (!consentGranted || installationId == null) {
        _lastProfileSignature = null;
        await Posthog().disable();
        await Posthog().reset();
        return;
      }

      final faculties = facultyIds.toSet().toList()..sort();
      final signature = '$installationId:${faculties.join(',')}';
      await Posthog().enable();
      await Posthog().identify(
        userId: installationId,
        userProperties: {
          'faculty_ids': faculties,
          'faculty_count': faculties.length,
        },
      );
      if (_lastProfileSignature == signature) return;

      await Posthog().capture(
        eventName: 'mustr_profile',
        properties: {
          'faculty_ids': faculties,
          'faculty_count': faculties.length,
        },
      );
      for (final facultyId in faculties) {
        await Posthog().capture(
          eventName: 'mustr_faculty_selected',
          properties: {'faculty_id': facultyId},
        );
      }
      _lastProfileSignature = signature;
    } catch (_) {
      // Analytics must never interrupt the schedule viewer.
    }
  }
}

final analyticsService = AnalyticsService();
