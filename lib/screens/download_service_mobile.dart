import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

Future<void> downloadAndInstallApk(String apkUrl) async {
  final dio = Dio();
  final dir = await getTemporaryDirectory();
  final filePath = '${dir.path}/task-tracker-admin-update.apk';

  await dio.download(apkUrl, filePath);

  final result = await OpenFile.open(filePath);
  if (result.type != ResultType.done) {
    throw Exception('Failed to open APK: ${result.message}');
  }
}
