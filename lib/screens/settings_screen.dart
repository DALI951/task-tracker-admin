import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_tracker_admin/main.dart';
import 'package:task_tracker_admin/screens/login_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDark = prefs.getBool('admin_dark_mode') ?? false);
  }

  Future<void> _toggleTheme(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin_dark_mode', val);
    setState(() => _isDark = val);
    if (mounted) {
      AdminApp.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
    }
  }

  Future<void> _changePassphrase() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Passphrase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Passphrase',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Passphrase',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Passphrase',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (currentCtrl.text != 'tasktracker2024') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Current passphrase is wrong')),
                );
                return;
              }
              if (newCtrl.text.isEmpty || newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passphrases do not match')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_passphrase', newCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passphrase updated')),
        );
      }
    }

    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  Future<void> _changeAdminPassword() async {
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Admin Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password (min 6 chars)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (newPassCtrl.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Password must be at least 6 characters')),
                );
                return;
              }
              if (newPassCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updatePassword(newPassCtrl.text);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password updated successfully')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e')),
          );
        }
      }
    }

    newPassCtrl.dispose();
    confirmCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _section('Appearance'),
          SwitchListTile(
            secondary: Icon(
              _isDark ? Icons.dark_mode : Icons.light_mode,
              color: _isDark ? Colors.amber : Colors.blue,
            ),
            title: const Text('Dark Mode'),
            subtitle: Text(_isDark ? 'Dark theme enabled' : 'Light theme enabled'),
            value: _isDark,
            onChanged: _toggleTheme,
          ),
          const Divider(),
          _section('Security'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Passphrase'),
            subtitle: const Text('Admin login passphrase'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changePassphrase,
          ),
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Change Admin Password'),
            subtitle: const Text('Firebase Auth password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changeAdminPassword,
          ),
          const Divider(),
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
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
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
