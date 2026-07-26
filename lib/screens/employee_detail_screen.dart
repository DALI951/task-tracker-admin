import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:task_tracker_admin/screens/task_detail_screen.dart';
import 'package:task_tracker_admin/screens/problem_detail_screen.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final String employeeEmail;
  final String employeeName;

  const EmployeeDetailScreen(
      {super.key, required this.employeeEmail, required this.employeeName});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.employeeName),
              Text(widget.employeeEmail,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tasks'),
              Tab(text: 'Problems'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TasksTab(employeeEmail: widget.employeeEmail),
            _ProblemsTab(employeeEmail: widget.employeeEmail),
          ],
        ),
      ),
    );
  }
}

class _TasksTab extends StatelessWidget {
  final String employeeEmail;
  const _TasksTab({required this.employeeEmail});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedToEmail', isEqualTo: employeeEmail)
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
                Text('No tasks assigned',
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        final tasks = snapshot.data!.docs;
        tasks.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aDate = (aData['createdAt'] as Timestamp?)?.toDate();
          final bDate = (bData['createdAt'] as Timestamp?)?.toDate();
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final doc = tasks[index];
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] as String? ?? 'Untitled';
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
                subtitle: Text('Created by: $createdBy',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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

class _ProblemsTab extends StatelessWidget {
  final String employeeEmail;
  const _ProblemsTab({required this.employeeEmail});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('problems')
          .where('reportedBy', isEqualTo: employeeEmail)
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
                Icon(Icons.check_circle_outline,
                    size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('No problems reported',
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        final problems = snapshot.data!.docs;
        problems.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aDate = (aData['createdAt'] as Timestamp?)?.toDate();
          final bDate = (bData['createdAt'] as Timestamp?)?.toDate();
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: problems.length,
          itemBuilder: (context, index) {
            final doc = problems[index];
            final data = doc.data() as Map<String, dynamic>;
            final description =
                data['description'] as String? ?? 'No description';
            final status = data['status'] as String? ?? 'open';

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFC62828).withAlpha(20),
                  child: const Icon(Icons.report_problem,
                      color: Color(0xFFC62828), size: 20),
                ),
                title: Text(description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ProblemStatusChip(status: status),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        color: Colors.grey, size: 20),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProblemDetailScreen(problemId: doc.id),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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

class _ProblemStatusChip extends StatelessWidget {
  final String status;
  const _ProblemStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'resolved':
        color = const Color(0xFF2E7D32);
        break;
      case 'assigned':
        color = const Color(0xFF1565C0);
        break;
      default:
        color = const Color(0xFFC62828);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}