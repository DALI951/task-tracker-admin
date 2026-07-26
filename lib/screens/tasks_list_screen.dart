import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:task_tracker_admin/screens/task_detail_screen.dart';

class TasksListScreen extends StatelessWidget {
  const TasksListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red)),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.task_alt,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('No tasks found',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          final tasks = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final doc = tasks[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] as String? ?? 'Untitled';
              final assignedTo =
                  data['assignedTo'] as String? ?? 'Unassigned';
              final createdBy = data['createdBy'] as String? ?? 'Unknown';
              final status = data['status'] as String? ?? 'pending';

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(status).withAlpha(20),
                    child: Icon(_statusIcon(status),
                        color: _statusColor(status), size: 20),
                  ),
                  title: Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assigned to: $assignedTo',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      Text('Created by: $createdBy',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatusChip(status: status),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right,
                          color: Colors.grey, size: 20),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskDetailScreen(taskId: doc.id),
                    ),
                  ),
                ),
              );
            },
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

  static IconData _statusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'pending_review':
        return Icons.rate_review_outlined;
      case 'doing':
        return Icons.play_circle_outline;
      default:
        return Icons.hourglass_empty;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'completed':
        color = const Color(0xFF2E7D32);
        break;
      case 'pending_review':
        color = const Color(0xFFF57F17);
        break;
      case 'doing':
        color = const Color(0xFF1565C0);
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.replaceAll('_', ' '),
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
