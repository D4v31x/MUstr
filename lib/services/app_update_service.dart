import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

const _latestReleaseUri =
    'https://api.github.com/repos/d4v31x/MUstr/releases/latest';
const _installerChannel = MethodChannel('cz.muni.planner/updater');

class AppRelease {
  const AppRelease({
    required this.version,
    required this.notes,
    required this.apkUrl,
    this.sha256Digest,
  });

  final String version;
  final String notes;
  final Uri apkUrl;
  final String? sha256Digest;
}

enum ApkInstallResult { started, permissionRequired }

class AppUpdateException implements Exception {
  const AppUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppUpdateService {
  const AppUpdateService();

  Future<AppRelease?> check() async {
    if (!Platform.isAndroid) return null;

    final packageInfo = await PackageInfo.fromPlatform();
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(_latestReleaseUri));
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
        ..set(HttpHeaders.userAgentHeader, 'MUstr/${packageInfo.version}')
        ..set('X-GitHub-Api-Version', '2022-11-28');
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != HttpStatus.ok) {
        throw AppUpdateException(
          'GitHub returned HTTP ${response.statusCode}.',
        );
      }

      final payload = jsonDecode(body) as Map<String, dynamic>;
      final version = (payload['tag_name'] as String? ?? '').replaceFirst(
        RegExp(r'^[vV]'),
        '',
      );
      if (version.isEmpty || !isVersionNewer(version, packageInfo.version)) {
        return null;
      }

      final assets = (payload['assets'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final apk = assets.cast<Map<String, dynamic>?>().firstWhere(
        (asset) =>
            (asset?['name'] as String? ?? '').toLowerCase().endsWith('.apk'),
        orElse: () => null,
      );
      if (apk == null) {
        throw const AppUpdateException(
          'The latest release does not contain an APK.',
        );
      }

      final rawUrl = apk['browser_download_url'] as String?;
      if (rawUrl == null || !rawUrl.startsWith('https://')) {
        throw const AppUpdateException('The release APK URL is invalid.');
      }
      final rawDigest = apk['digest'] as String?;
      return AppRelease(
        version: version,
        notes: payload['body'] as String? ?? '',
        apkUrl: Uri.parse(rawUrl),
        sha256Digest: rawDigest?.startsWith('sha256:') == true
            ? rawDigest!.substring('sha256:'.length).toLowerCase()
            : null,
      );
    } on AppUpdateException {
      rethrow;
    } catch (error) {
      throw AppUpdateException('Could not check for updates: $error');
    } finally {
      client.close(force: true);
    }
  }

  Future<File> download(
    AppRelease release, {
    required void Function(double progress) onProgress,
  }) async {
    final client = HttpClient();
    IOSink? sink;
    try {
      final request = await client.getUrl(release.apkUrl);
      request.headers.set(HttpHeaders.userAgentHeader, 'MUstr updater');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw AppUpdateException(
          'APK download returned HTTP ${response.statusCode}.',
        );
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/mustr-${release.version}.apk');
      sink = file.openWrite();
      var received = 0;
      final total = response.contentLength;
      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress(received / total);
      }
      await sink.flush();
      await sink.close();
      sink = null;

      if (release.sha256Digest case final expected?) {
        final actual = (await sha256.bind(file.openRead()).first).toString();
        if (actual.toLowerCase() != expected) {
          await file.delete();
          throw const AppUpdateException(
            'The downloaded APK failed its SHA-256 verification.',
          );
        }
      }
      onProgress(1);
      return file;
    } on AppUpdateException {
      rethrow;
    } catch (error) {
      throw AppUpdateException('Could not download the update: $error');
    } finally {
      await sink?.close();
      client.close(force: true);
    }
  }

  Future<ApkInstallResult> install(File apk) async {
    final result = await _installerChannel.invokeMethod<String>('installApk', {
      'path': apk.path,
    });
    return result == 'permission_required'
        ? ApkInstallResult.permissionRequired
        : ApkInstallResult.started;
  }
}

bool isVersionNewer(String candidate, String current) {
  final candidateParts = _versionParts(candidate);
  final currentParts = _versionParts(current);
  final length = candidateParts.length > currentParts.length
      ? candidateParts.length
      : currentParts.length;
  for (var index = 0; index < length; index++) {
    final candidatePart = index < candidateParts.length
        ? candidateParts[index]
        : 0;
    final currentPart = index < currentParts.length ? currentParts[index] : 0;
    if (candidatePart != currentPart) return candidatePart > currentPart;
  }
  return false;
}

List<int> _versionParts(String value) => value
    .replaceFirst(RegExp(r'^[vV]'), '')
    .split('+')
    .first
    .split('-')
    .first
    .split('.')
    .map((part) => int.tryParse(part) ?? 0)
    .toList();
