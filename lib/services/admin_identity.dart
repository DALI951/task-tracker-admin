import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Stamps the signed-in user's own users/{uid} doc with role 'admin'
/// (owner self-write is allowed by the rules). Called after every sign-in
/// and on app start for persisted sessions, so the admin panel always
/// holds the read/write rights granted to isAdmin().
Future<void> ensureAdminRole() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'email': user.email ?? '',
    'role': 'admin',
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
