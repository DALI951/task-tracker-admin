import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class AdminUpdateService {
  static const _repoOwner = 'DALI951';
  static const _repoName = 'task-tracker-admin';
  static const _releasesUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  final Dio _dio = Dio();

  Future<PackageInfo> getAppInfo() => PackageInfo.fromPlatform();

  Future<Map<String, dynamic>?> checkForUpdate() async {
    if (kIsWeb) return null;

    try {
      final info = await getAppInfo();
      final currentVersion = info.version;

      final response = await _dio.get(
        _releasesUrl,
        options: Options(headers: {'Accept': 'application/vnd.github.v3+json'}),
      );

      if (response.statusCode != 200) return null;

      final data = response.data as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final latestVersion = tagName.replaceFirst('v', '');
      final body = data['body'] as String? ?? '';

      if (_isNewer(latestVersion, currentVersion)) {
        String? apkUrl;
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
            break;
          }
        }

        return {
          'latestVersion': latestVersion,
          'currentVersion': currentVersion,
          'changelog': body,
          'apkUrl': apkUrl,
        };
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
    return null;
  }

  Future<void> downloadAndInstall(String apkUrl) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/task-tracker-admin-update.apk';

    await _dio.download(apkUrl, filePath);

    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done) {
      debugPrint('Failed to open APK: ${result.message}');
    }
  }

  bool _isNewer(String latest, String current) {
    final lParts = latest.split('.').map(int.tryParse).toList();
    final cParts = current.split('.').map(int.tryParse).toList();

    while (lParts.length < 3) lParts.add(0);
    while (cParts.length < 3) cParts.add(0);

    for (var i = 0; i < 3; i++) {
      final l = lParts[i] ?? 0;
      final c = cParts[i] ?? 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
}
