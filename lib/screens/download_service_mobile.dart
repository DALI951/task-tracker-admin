import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

Future<void> downloadAndInstallApk(
  String apkUrl, {
  void Function(int received, int total)? onProgress,
}) async {
  final dio = Dio();
  final dir = await getTemporaryDirectory();
  final filePath = '${dir.path}/task-tracker-admin-update.apk';

  await dio.download(
    apkUrl,
    filePath,
    onReceiveProgress: (received, total) {
      if (onProgress != null) {
        onProgress(received, total);
      }
    },
    options: Options(
      headers: {'Accept': 'application/octet-stream'},
      followRedirects: true,
      receiveTimeout: const Duration(minutes: 5),
    ),
  );

  final file = File(filePath);
  if (!await file.exists() || await file.length() == 0) {
    throw Exception('Downloaded file is empty or missing');
  }

  final result = await OpenFile.open(
    filePath,
    type: 'application/vnd.android.package-archive',
  );
  if (result.type != ResultType.done) {
    throw Exception('Failed to open APK: ${result.message}');
  }
}
