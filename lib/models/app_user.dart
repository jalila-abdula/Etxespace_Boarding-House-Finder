import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // '', tenant, landlord, admin
  final bool active;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.active = true,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AppUser(
      uid: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      role: d['role'] ?? '',
      active: d['active'] ?? true,
    );
  }
}