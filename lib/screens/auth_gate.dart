import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/auth_service.dart';
import 'admin/admin_shell.dart';
import 'landing_screen.dart';
import 'landlord/landlord_shell.dart';
import 'role_selection_screen.dart';
import 'tenant/tenant_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder<User?>(
      stream: auth.authChanges,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        if (user == null) return const LandingScreen();

        return StreamBuilder(
          stream: auth.userStream(user.uid),
          builder: (context, userSnap) {
            if (!userSnap.hasData) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            final u = userSnap.data!;
            if (!u.active && u.role != Roles.admin) {
              return const _SuspendedScreen();
            }
            switch (u.role) {
              case Roles.tenant:
                return const TenantShell();
              case Roles.landlord:
                return const LandlordShell();
              case Roles.admin:
                return const AdminShell();
              default:
                return const RoleSelectionScreen();
            }
          },
        );
      },
    );
  }
}

class _SuspendedScreen extends StatelessWidget {
  const _SuspendedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block, size: 56, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Account suspended',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                  'Your account was deactivated by the administrator. Contact support if you think this is a mistake.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => AuthService().logout(),
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}