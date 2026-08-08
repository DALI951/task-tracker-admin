import 'package:flutter/material.dart';

/// Upload progress/state helpers mirroring the main app (v0.5.7):
/// byte-first (uploadBytesSent/uploadBytesTotal), photo-count fallback
/// (uploadCompleted/uploadTotal).

double uploadProgress(Map<String, dynamic> doc) {
  final bytesSent = (doc['uploadBytesSent'] as num?)?.toDouble() ?? 0;
  final bytesTotal = (doc['uploadBytesTotal'] as num?)?.toDouble() ?? 0;
  if (bytesTotal > 0) return (bytesSent / bytesTotal).clamp(0.0, 1.0);
  final done = (doc['uploadCompleted'] as num?)?.toDouble() ?? 0;
  final total = (doc['uploadTotal'] as num?)?.toDouble() ?? 0;
  if (total > 0) return (done / total).clamp(0.0, 1.0);
  return 0.0;
}

bool isUploading(Map<String, dynamic> doc) {
  final status = doc['status'] as String?;
  return status == 'uploading';
}

bool isUploadPaused(Map<String, dynamic> doc) {
  final status = doc['status'] as String?;
  return status == 'paused' || status == 'failed';
}

String uploadProgressLabel(Map<String, dynamic> doc) {
  final bytesSent = (doc['uploadBytesSent'] as num?)?.toDouble() ?? 0;
  final bytesTotal = (doc['uploadBytesTotal'] as num?)?.toDouble() ?? 0;
  if (bytesTotal > 0) {
    return '${(uploadProgress(doc) * 100).toInt()}% '
        '(${_mb(bytesSent)} / ${_mb(bytesTotal)})';
  }
  final done = (doc['uploadCompleted'] as num?)?.toInt() ?? 0;
  final total = (doc['uploadTotal'] as num?)?.toInt() ?? 0;
  if (total > 0) return '${(uploadProgress(doc) * 100).toInt()}% ($done/$total)';
  return '0%';
}

String _mb(double bytes) {
  if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${bytes.toStringAsFixed(0)} B';
}

/// Blue progress bar shown while an upload is in flight.
class UploadProgressBar extends StatelessWidget {
  final Map<String, dynamic> doc;
  final bool paused;

  const UploadProgressBar({super.key, required this.doc, this.paused = false});

  @override
  Widget build(BuildContext context) {
    final progress = uploadProgress(doc);
    final color = paused ? Colors.orange : const Color(0xFF1565C0);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(paused ? Icons.pause_circle_outline : Icons.cloud_upload,
                  size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  paused
                      ? 'Upload paused · ${uploadProgressLabel(doc)}'
                      : 'Uploading ${uploadProgressLabel(doc)}',
                  style: TextStyle(fontSize: 11, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: paused ? null : progress,
            backgroundColor: color.withAlpha(25),
            color: color,
            minHeight: 4,
          ),
        ],
      ),
    );
  }
}
