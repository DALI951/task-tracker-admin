import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:task_tracker_admin/screens/dashboard_screen.dart';
import 'package:task_tracker_admin/services/admin_identity.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passCtrl = TextEditingController();
  bool _error = false;
  bool _loading = false;
  bool _obscure = true;
  String? _status;

  static const _defaultPass = 'tasktracker2024';
  static const _adminEmail = 'admin@tasktracker.app';
  static const _adminPassword = 'TaskTrackerAdmin2024!';

  Future<void> _login() async {
    if (_passCtrl.text != _defaultPass) {
      setState(() => _error = true);
      return;
    }

    setState(() {
      _loading = true;
      _error = false;
      _status = 'Signing in...';
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        setState(() => _status = 'Connected');
        _goToDashboard();
        return;
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _adminEmail,
        password: _adminPassword,
      );

      try {
        await ensureAdminRole();
      } catch (e) {
        debugPrint('Admin role stamp failed: $e');
      }

      setState(() => _status = 'Connected');
      _goToDashboard();
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error: ${e.message}');
      setState(() {
        _loading = false;
        _status = null;
        _error = true;
      });
    } catch (e) {
      debugPrint('Login error: $e');
      setState(() {
        _loading = false;
        _status = null;
      });
      _goToDashboard();
    }
  }

  void _goToDashboard() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.admin_panel_settings,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text('Task Tracker',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Admin Access',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    enabled: !_loading,
                    decoration: InputDecoration(
                      hintText: 'Admin passphrase',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      errorText: _error ? 'Invalid passphrase' : null,
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                        tooltip: _obscure ? 'Show' : 'Hide',
                      ),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 16),
                  if (_status != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_status!,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12)),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
