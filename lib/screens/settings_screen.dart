import 'package:flutter/material.dart';
import 'package:task_tracker_admin/screens/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _section('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Task Tracker Admin'),
            subtitle: Text('Version 1.0.0'),
          ),
          const Divider(),
          _section('Danger Zone'),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFC62828)),
            title: const Text('Sign Out',
                style: TextStyle(color: Color(0xFFC62828))),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Task Tracker Admin Panel',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withAlpha(100),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(title,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey,
              letterSpacing: 0.5)),
    );
  }
}
