import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/auth_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _auth = AuthService();
  String? _role;

  Widget _card(String role, String title, String badge, String desc, IconData icon) {
    final selected = _role == role;
    return GestureDetector(
      onTap: () => setState(() => _role = role),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? AppColors.green : Colors.grey.shade300,
              width: selected ? 2 : 1),
          color: selected ? Colors.green.shade50 : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(badge, style: const TextStyle(color: Colors.green)),
                  Text(desc, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppColors.green : Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('How will you use ETXESPACE?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _card(Roles.tenant, "I'm looking for a place", 'Tenant',
                  'Browse listings, make reservations, and find your perfect boarding house.',
                  Icons.home),
              _card(Roles.landlord, "I'm renting out a space", 'Landlord / Owner',
                  'Post properties, manage rooms, reservations, and grow your rental business.',
                  Icons.apartment),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _role == null
                    ? null
                    : () => _auth.setRole(_auth.currentUser!.uid, _role!),
                child: Text(_role == null
                    ? 'Continue as ...'
                    : 'Continue as ${_role == Roles.tenant ? 'Tenant' : 'Landlord / Owner'}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}