import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:task_tracker_admin/screens/create_account_screen.dart';
import 'package:task_tracker_admin/screens/employees_list_screen.dart';
import 'package:task_tracker_admin/screens/managers_list_screen.dart';
import 'package:task_tracker_admin/screens/problems_list_screen.dart';
import 'package:task_tracker_admin/screens/settings_screen.dart';
import 'package:task_tracker_admin/screens/tasks_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _managers = 0;
  int _employees = 0;
  int _tasks = 0;
  int _problems = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final db = FirebaseFirestore.instance;

      final employeesSnap = await db
          .collection('employees')
          .get()
          .timeout(const Duration(seconds: 10));

      final managersSnap = await db
          .collection('users')
          .where('role', isEqualTo: 'manager')
          .get()
          .timeout(const Duration(seconds: 10));

      final tasksSnap =
          await db.collection('tasks').get().timeout(const Duration(seconds: 10));
      final problemsSnap = await db
          .collection('problems')
          .get()
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _managers = managersSnap.size;
          _employees = employeesSnap.size;
          _tasks = tasksSnap.size;
          _problems = problemsSnap.size;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load data: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminSettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(
                              color: Color(0xFFC62828), fontSize: 13)),
                    ),
                  Text('Overview',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              title: 'Managers',
                              value: '$_managers',
                              icon: Icons.business_center,
                              color: const Color(0xFF1565C0),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ManagersListScreen())))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                              title: 'Employees',
                              value: '$_employees',
                              icon: Icons.people,
                              color: const Color(0xFF2E7D32),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const EmployeesListScreen())))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              title: 'Tasks',
                              value: '$_tasks',
                              icon: Icons.task_alt,
                              color: const Color(0xFFE65100),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const TasksListScreen())))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                              title: 'Problems',
                              value: '$_problems',
                              icon: Icons.report_problem,
                              color: const Color(0xFFC62828),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ProblemsListScreen())))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Actions',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _ActionCard(
                    title: 'Create Account',
                    subtitle: 'Add a new manager or employee',
                    icon: Icons.person_add,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateAccountScreen())),
                  ),
                  const SizedBox(height: 8),
                  _ActionCard(
                    title: 'View Users',
                    subtitle: 'See managers and their employees',
                    icon: Icons.people_outline,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ManagersListScreen())),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 12),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(title,
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Icon(icon, color: const Color(0xFF1565C0)),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style:
                TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
