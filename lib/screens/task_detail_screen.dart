import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskDetailScreen extends StatelessWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('tasks').doc(taskId).get(),
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
