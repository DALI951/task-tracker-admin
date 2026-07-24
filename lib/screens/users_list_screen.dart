import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('employees').snapshots(),
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
                  Icon(Icons.people_outline,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('No employees found',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionHeader('Employees (${docs.length})'),
              const SizedBox(height: 8),
              ...docs.map((doc) => _EmployeeTile(doc: doc)),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  final QueryDocumentSnapshot doc;

  const _EmployeeTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final email = data['email'] as String? ?? '';
    final name = data['displayName'] as String? ?? data['name'] as String? ?? email;
    final createdBy = data['createdBy'] as String? ?? '';

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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            if (createdBy.isNotEmpty)
              Text('Created by: $createdBy',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
        isThreeLine: createdBy.isNotEmpty,
      ),
    );
  }
}
