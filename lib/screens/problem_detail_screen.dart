import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProblemDetailScreen extends StatelessWidget {
  final String problemId;
  const ProblemDetailScreen({super.key, required this.problemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Problem Details'),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('problems')
            .doc(problemId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Problem not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final description = data['description'] as String? ?? 'No description';
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status badge
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                      // Navigate to task detail would need a route
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
