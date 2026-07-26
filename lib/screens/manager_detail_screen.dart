import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:task_tracker_admin/screens/employee_detail_screen.dart';
import 'package:task_tracker_admin/screens/task_detail_screen.dart';
import 'package:task_tracker_admin/screens/problem_detail_screen.dart';

class ManagerDetailScreen extends StatefulWidget {
  final String managerEmail;
  final String managerName;

  const ManagerDetailScreen(
      {super.key, required this.managerEmail, required this.managerName});

  @override
  State<ManagerDetailScreen> createState() => _ManagerDetailScreenState();
}

class _ManagerDetailScreenState extends State<ManagerDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.managerName),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Employees'),
              Tab(text: 'Tasks'),
              Tab(text: 'Problems'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _EmployeesTab(managerEmail: widget.managerEmail),
            _TasksTab(managerEmail: widget.managerEmail),
            _ProblemsTab(managerEmail: widget.managerEmail),
          ],
        ),
      ),
    );
  }
}

class _EmployeesTab extends StatelessWidget {
  final String managerEmail;
  const _EmployeesTab({required this.managerEmail});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('employees')
          .where('createdBy', isEqualTo: managerEmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline,
                    size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('No employees under this manager',
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        final employees = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final doc = employees[index];
            final data = doc.data() as Map<String, dynamic>;
            final email = data['email'] as String? ?? '';
            final name =
                data['displayName'] as String? ?? data['name'] as String? ?? email;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF2E7D32).withAlpha(20),
                  child: const Icon(Icons.person,
                      color: Color(0xFF2E7D32), size: 20),
                ),
                title: Text(name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text(email,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                trailing:
                    const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EmployeeDetailScreen(
                      employeeEmail: email,
                      employeeName: name,
                    ),
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

class _TasksTab extends StatelessWidget {
  final String managerEmail;
  const _TasksTab({required this.managerEmail});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('createdBy', isEqualTo: managerEmail)
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
                Text('No tasks created by this manager',
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
            final assignedTo =
                data['assignedTo'] as String? ?? 'Unassigned';
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
                subtitle: Text('Assigned to: $assignedTo',
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
  final String managerEmail;
  const _ProblemsTab({required this.managerEmail});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('problems')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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

        // Filter client-side: only show problems reported by employees
        // whose createdBy matches this manager
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('employees')
              .where('createdBy', isEqualTo: managerEmail)
              .snapshots(),
          builder: (context, empSnapshot) {
            if (!empSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final employeeEmails = empSnapshot.data!.docs
                .map((d) => (d.data() as Map<String, dynamic>)['email'] as String? ?? '')
                .where((e) => e.isNotEmpty)
                .toSet();

            final allProblems = snapshot.data!.docs;
            final myProblems = allProblems.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final reportedBy = data['reportedBy'] as String? ?? '';
              return employeeEmails.contains(reportedBy);
            }).toList();

            if (myProblems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text('No problems from this manager\'s employees',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myProblems.length,
              itemBuilder: (context, index) {
                final doc = myProblems[index];
                final data = doc.data() as Map<String, dynamic>;
                final description =
                    data['description'] as String? ?? 'No description';
                final reporterName =
                    data['reporterName'] as String? ?? 'Unknown';
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
                    subtitle: Text('Reported by: $reporterName',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
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
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _StatusChipState._statusColor(status);
    final label = status.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusChipState {
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
