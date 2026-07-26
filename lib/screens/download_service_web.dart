Future<void> downloadAndInstallApk(
  String apkUrl, {
  void Function(int received, int total)? onProgress,
}) async {
  throw UnsupportedError('Cannot install APK on web');
}
