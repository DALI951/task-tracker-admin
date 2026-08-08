import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_tracker_admin/utils/upload_progress.dart';

class TaskDetailScreen extends StatelessWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

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
        title: const Text('Complete Task Now'),
        content: const Text(
            'Approve this task with the photos uploaded so far?'),
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
    final ref = FirebaseFirestore.instance.collection('tasks').doc(taskId);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final snap = await txn.get(ref);
        final current = (snap.data() as Map<String, dynamic>?) ?? {};
        final history = List<Map<String, dynamic>>.from(
            (current['history'] as List?) ?? []);
        history.add({
          'action': 'approved',
          'by': adminEmail,
          'detail': 'Completed by admin',
          'at': Timestamp.now(),
        });
        if (history.length > 50) history.removeRange(0, history.length - 50);
        txn.update(ref, {
          'status': 'completed',
          'photoUrl': photoUrls.isEmpty ? null : photoUrls.first,
          'photoUrls': photoUrls,
          'uploadsComplete': true,
          'uploadCompleted': photoUrls.length,
          'uploadTotal': total,
          'completedAt': Timestamp.now(),
          'approvedBy': adminEmail,
          'rejectionReason': null,
          'history': history,
        });
      });
      messenger.showSnackBar(
          const SnackBar(content: Text('Task completed')));
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
            'Stop this upload? Photos already uploaded stay on the task, '
            'and the task returns to Doing.'),
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
    final ref = FirebaseFirestore.instance.collection('tasks').doc(taskId);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final snap = await txn.get(ref);
        final current = (snap.data() as Map<String, dynamic>?) ?? {};
        final history = List<Map<String, dynamic>>.from(
            (current['history'] as List?) ?? []);
        history.add({
          'action': 'reset',
          'by': adminEmail,
          'detail': 'Upload stopped by admin',
          'at': Timestamp.now(),
        });
        if (history.length > 50) history.removeRange(0, history.length - 50);
        txn.update(ref, {
          'status': 'doing',
          'uploadsComplete': false,
          'history': history,
        });
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
        title: const Text('Task Details'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .doc(taskId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Task not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final title = data['title'] as String? ?? 'Untitled';
          final description = data['description'] as String? ?? '';
          final assignedTo = data['assignedTo'] as String? ?? 'Unassigned';
          final assignedToEmail =
              data['assignedToEmail'] as String? ?? '';
          final createdBy = data['createdBy'] as String? ?? 'Unknown';
          final status = data['status'] as String? ?? 'pending';
          final customer = data['customer'] as String?;
          final carOrThing = data['carOrThing'] as String?;
          final createdAt = data['createdAt'];
          final completedAt = data['completedAt'];
          final rejectionReason = data['rejectionReason'] as String?;
          final history = data['history'] as List<dynamic>? ?? [];

          final createdStr = createdAt != null
              ? DateFormat('MMM d, yyyy h:mm a')
                  .format((createdAt as Timestamp).toDate())
              : 'Unknown';

          final uploading = isUploading(data) || isUploadPaused(data);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

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
                      _InfoRow(
                          label: 'Status',
                          value: status.replaceAll('_', ' ').toUpperCase(),
                          valueColor: _statusColor(status)),
                      const Divider(),
                      _InfoRow(label: 'Assigned to', value: assignedTo),
                      if (assignedToEmail.isNotEmpty)
                        _InfoRow(
                            label: 'Employee email', value: assignedToEmail),
                      const Divider(),
                      _InfoRow(label: 'Created by (Manager)', value: createdBy),
                      const Divider(),
                      _InfoRow(label: 'Created at', value: createdStr),
                      if (customer != null && customer.isNotEmpty) ...[
                        const Divider(),
                        _InfoRow(label: 'Customer', value: customer),
                      ],
                      if (carOrThing != null && carOrThing.isNotEmpty) ...[
                        const Divider(),
                        _InfoRow(label: 'Vehicle/Object', value: carOrThing),
                      ],
                      if (completedAt != null) ...[
                        const Divider(),
                        _InfoRow(
                            label: 'Completed at',
                            value: DateFormat('MMM d, yyyy h:mm a')
                                .format((completedAt as Timestamp).toDate())),
                      ],
                      if (rejectionReason != null &&
                          rejectionReason.isNotEmpty) ...[
                        const Divider(),
                        _InfoRow(
                            label: 'Rejection reason',
                            value: rejectionReason,
                            valueColor: const Color(0xFFC62828)),
                      ],
                    ],
                  ),
                ),
              ),

              if (description.isNotEmpty) ...[
                const SizedBox(height: 12),
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
                        Text('Description',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Text(description),
                      ],
                    ),
                  ),
                ),
              ],

              if (history.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('History',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...history.reversed.map((event) {
                  final action = event['action'] as String? ?? '';
                  final by = event['by'] as String? ?? '';
                  final detail = event['detail'] as String?;
                  final at = event['at'] as Timestamp?;
                  final atStr = at != null
                      ? DateFormat('MMM d, h:mm a').format(at.toDate())
                      : '';

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      dense: true,
                      leading: Icon(_historyIcon(action),
                          size: 18, color: Colors.grey.shade600),
                      title: Text(action.replaceAll('_', ' '),
                          style: const TextStyle(fontSize: 13)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (by.isNotEmpty)
                            Text('by: $by',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600)),
                          if (detail != null && detail.isNotEmpty)
                            Text(detail,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                      trailing: Text(atStr,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade500)),
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'pending_review':
        return const Color(0xFFF57F17);
      case 'doing':
        return const Color(0xFF1565C0);
      case 'uploading':
        return const Color(0xFF1565C0);
      case 'paused':
      case 'failed':
        return const Color(0xFFE65100);
      default:
        return Colors.grey;
    }
  }

  static IconData _historyIcon(String action) {
    switch (action) {
      case 'created':
        return Icons.add_circle_outline;
      case 'started':
        return Icons.play_circle_outline;
      case 'submitted_proof':
        return Icons.camera_alt;
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'reassigned':
        return Icons.swap_horiz;
      case 'reset':
        return Icons.restart_alt;
      default:
        return Icons.circle;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

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
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor)),
        ),
      ],
    );
  }
}
