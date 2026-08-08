import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_tracker_admin/screens/task_detail_screen.dart';
import 'package:task_tracker_admin/utils/upload_progress.dart';

class ProblemDetailScreen extends StatelessWidget {
  final String problemId;
  const ProblemDetailScreen({super.key, required this.problemId});

  List<String> _existingPhotoUrls(Map<String, dynamic> data) {
    final urls =
        (data['photoUrls'] as List?)?.whereType<String>().toList() ?? [];
    if (urls.isNotEmpty) return urls;
    final single = data['photoUrl'] as String?;
    return (single == null || single.isEmpty) ? [] : [single];
  }

  Future<void> _completeNow(
      BuildContext context, Map<String, dynamic> data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Report Now'),
        content: const Text(
            'Mark this report as delivered with the photos uploaded so far?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Complete')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final adminEmail = FirebaseAuth.instance.currentUser?.email ?? 'admin';
    final photoUrls = _existingPhotoUrls(data);
    final total =
        (data['uploadTotal'] as num?)?.toInt() ?? photoUrls.length;
    final ref =
        FirebaseFirestore.instance.collection('problems').doc(problemId);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final update = <String, dynamic>{
        'status': 'open',
        'photoUrl': photoUrls.isEmpty ? null : photoUrls.first,
        'photoUrls': photoUrls,
        'uploadsComplete': true,
        'uploadCompleted': photoUrls.length,
        'uploadTotal': total,
        'reviewedBy': adminEmail,
        'reviewedAt': Timestamp.now(),
      };
      if (data['managerEmail'] is String &&
          (data['managerEmail'] as String).isNotEmpty) {
        update['managerEmail'] = data['managerEmail'];
      }
      await ref.update(update);
      messenger.showSnackBar(
          const SnackBar(content: Text('Report completed')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _stopUpload(
      BuildContext context, Map<String, dynamic> data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop Upload'),
        content: const Text(
            'Stop this upload? Photos already uploaded stay on the report, '
            'and the report returns to Open.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Stop')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final adminEmail = FirebaseAuth.instance.currentUser?.email ?? 'admin';
    final ref =
        FirebaseFirestore.instance.collection('problems').doc(problemId);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.update({
        'status': 'open',
        'uploadsComplete': false,
        'reviewedBy': adminEmail,
        'reviewedAt': Timestamp.now(),
      });
      messenger.showSnackBar(
          const SnackBar(content: Text('Upload stopped')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Problem Details'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('problems')
            .doc(problemId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Problem not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final description =
              data['description'] as String? ?? 'No description';
          final reporterName = data['reporterName'] as String? ?? 'Unknown';
          final reportedBy = data['reportedBy'] as String? ?? '';
          final status = data['status'] as String? ?? 'open';
          final carOrThing = data['carOrThing'] as String?;
          final createdAt = data['createdAt'];
          final convertedToTaskId = data['convertedToTaskId'] as String?;

          final createdStr = createdAt != null
              ? DateFormat('MMM d, yyyy h:mm a')
                  .format((createdAt as Timestamp).toDate())
              : 'Unknown';

          final uploading = isUploading(data) || isUploadPaused(data);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Upload progress panel
              if (uploading) ...[
                Card(
                  elevation: 0,
                  color: const Color(0xFFE3F2FD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UploadProgressBar(
                            doc: data, paused: isUploadPaused(data)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.stop, size: 18),
                              label: const Text('Stop'),
                              onPressed: () => _stopUpload(context, data),
                            ),
                            FilledButton.icon(
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Complete Now'),
                              onPressed: () => _completeNow(context, data),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Status badge
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(status.toUpperCase(),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _statusColor(status))),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(description,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Info card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(label: 'Status', value: status),
                      const Divider(),
                      _InfoRow(label: 'Reported by', value: reporterName),
                      if (reportedBy.isNotEmpty)
                        _InfoRow(label: 'Reporter email', value: reportedBy),
                      const Divider(),
                      _InfoRow(label: 'Reported at', value: createdStr),
                      if (carOrThing != null && carOrThing.isNotEmpty) ...[
                        const Divider(),
                        _InfoRow(label: 'Vehicle/Object', value: carOrThing),
                      ],
                    ],
                  ),
                ),
              ),

              if (convertedToTaskId != null) ...[
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.arrow_forward,
                        color: Color(0xFF1565C0)),
                    title: const Text('Converted to Task',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Task ID: $convertedToTaskId',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TaskDetailScreen(taskId: convertedToTaskId),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
        return const Color(0xFF2E7D32);
      case 'assigned':
        return const Color(0xFF1565C0);
      case 'uploading':
        return const Color(0xFF1565C0);
      case 'paused':
      case 'failed':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFFC62828);
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
