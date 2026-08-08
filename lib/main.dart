import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_tracker_admin/firebase_options.dart';
import 'package:task_tracker_admin/screens/dashboard_screen.dart';
import 'package:task_tracker_admin/screens/login_screen.dart';
import 'package:task_tracker_admin/services/admin_identity.dart';
import 'package:firebase_auth/firebase_auth.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }
  runApp(const AdminApp());
}

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.light);

  static void setThemeMode(ThemeMode mode) {
    themeNotifier.value = mode;
  }

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  @override
  void initState() {
    super.initState();
    _loadTheme();
    if (FirebaseAuth.instance.currentUser != null) {
      ensureAdminRole().catchError((_) {});
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('admin_dark_mode') ?? false;
    AdminApp.themeNotifier.value =
        isDark ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AdminApp.themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Task Tracker Admin',
          debugShowCheckedModeBanner: false,
          navigatorKey: AdminApp.navigatorKey,
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF1565C0),
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: const Color(0xFF1565C0),
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF1C1B1F),
          ),
          themeMode: themeMode,
          home: user != null ? const DashboardScreen() : const LoginScreen(),
        );
      },
    );
  }
}
