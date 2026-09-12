import 'package:flutter_test/flutter_test.dart';
import 'package:muni_timetable/services/app_update_service.dart';

void main() {
  group('isVersionNewer', () {
    test('detects newer major, minor, and patch versions', () {
      expect(isVersionNewer('2.0.0', '1.9.9'), isTrue);
      expect(isVersionNewer('1.3.0', '1.2.9'), isTrue);
      expect(isVersionNewer('1.2.4', '1.2.3'), isTrue);
    });

    test('rejects equal and older versions', () {
      expect(isVersionNewer('1.2.3', '1.2.3'), isFalse);
      expect(isVersionNewer('1.2.2', '1.2.3'), isFalse);
      expect(isVersionNewer('1.9.9', '2.0.0'), isFalse);
    });

    test('ignores v prefix, build metadata, and prerelease suffixes', () {
      expect(isVersionNewer('v1.2.4', '1.2.3+9'), isTrue);
      expect(isVersionNewer('1.2.3-beta.1', '1.2.3'), isFalse);
    });
  });

  test('AppRelease metadata round-trips for persistent downloads', () {
    final release = AppRelease(
      version: '1.2.3',
      notes: 'Release notes',
      apkUrl: Uri.parse('https://example.invalid/MUstr-1.2.3.apk'),
      sha256Digest: 'abc123',
    );

    final restored = AppRelease.fromJson(release.toJson());

    expect(restored.version, release.version);
    expect(restored.notes, release.notes);
    expect(restored.apkUrl, release.apkUrl);
    expect(restored.sha256Digest, release.sha256Digest);
  });
}
