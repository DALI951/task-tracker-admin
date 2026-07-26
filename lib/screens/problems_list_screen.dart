import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:task_tracker_admin/screens/problem_detail_screen.dart';

class ProblemsListScreen extends StatelessWidget {
  const ProblemsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Problems'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('problems')
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
                  Icon(Icons.check_circle_outline,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('No problems found',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          final problems = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: problems.length,
            itemBuilder: (context, index) {
              final doc = problems[index];
              final data = doc.data() as Map<String, dynamic>;
              final description =
                  data['description'] as String? ?? 'No description';
              final reporterName =
                  data['reporterName'] as String? ?? 'Unknown';
              final reportedBy =
                  data['reportedBy'] as String? ?? '';
              final status = data['status'] as String? ?? 'open';
              final convertedId =
                  data['convertedToTaskId'] as String?;

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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reported by: $reporterName',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      if (reportedBy.isNotEmpty)
                        Text(reportedBy,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                      if (convertedId != null)
                        Text('Converted to task',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade700)),
                    ],
                  ),
                  isThreeLine: true,
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
      ),
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
