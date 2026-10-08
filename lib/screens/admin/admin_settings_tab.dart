import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/app_user.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/multi_snap.dart';
import 'admin_alerts_screen.dart';
import 'banned_users_screen.dart';
import 'data_backup_screen.dart';
import 'manage_reviews_screen.dart';
import 'reports_screen.dart';

class AdminSettingsTab extends StatefulWidget {
  const AdminSettingsTab({super.key});
  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  final _admin = AdminService();
  final _user = FirebaseAuth.instance.currentUser!;
  late final _streams = <Stream<Snap>>[_admin.reports(), _admin.users()];
  late final _me = AuthService().userStream(_user.uid);

  void _push(Widget w) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  void _security() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Security',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_reset),
                title: const Text('Change password'),
                subtitle: Text('A reset link is emailed to ${_user.email}'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await AuthService().resetPassword(_user.email ?? '');
                    if (mounted) toast(context, 'Password reset link sent');
                  } catch (_) {
                    if (mounted) toast(context, 'Could not send the reset link');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(context, 'Log out?', 'You will leave the admin panel.',
        yes: 'Log out', danger: true);
    if (ok) await AuthService().logout();
  }

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, Color color, String title, String sub,
            VoidCallback onTap) =>
        ListTile(
          leading: Icon(icon, color: color),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(sub,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        );

    Widget section(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Text(t,
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600)),
        );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: MultiSnap(
          streams: _streams,
          builder: (context, d) {
            final pending = AdminService.pending(d[0]);
            final banned =
                d[1].docs.where((x) => x.data()['active'] == false).length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Settings',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                StreamBuilder<AppUser?>(
                  stream: _me,
                  builder: (context, snap) {
                    final name = (snap.data?.name.isNotEmpty ?? false)
                        ? snap.data!.name
                        : 'Admin User';
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(14)),
                            alignment: Alignment.center,
                            child: Text(name[0].toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800)),
                                Text(_user.email ?? '',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.9),
                                        fontSize: 12)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: const Text('Administrator',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 11)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                section('SYSTEM'),
                Container(
                  decoration: cardDeco(),
                  child: Column(
                    children: [
                      item(Icons.notifications, Colors.amber, 'Notifications',
                          'System alerts and updates',
                          () => _push(const AdminAlertsScreen())),
                      const Divider(height: 1),
                      item(Icons.lock, Colors.amber.shade800, 'Security',
                          'Password', _security),
                      const Divider(height: 1),
                      item(Icons.storage_outlined, Colors.black87,
                          'Data & Backup', 'Export and backup data',
                          () => _push(const DataBackupScreen())),
                    ],
                  ),
                ),
                section('MODERATION'),
                Container(
                  decoration: cardDeco(),
                  child: Column(
                    children: [
                      item(Icons.flag, Colors.red, 'Reported Properties',
                          '$pending pending reports',
                          () => _push(const ReportsScreen())),
                      const Divider(height: 1),
                      item(Icons.star, Colors.amber, 'Manage Reviews',
                          'Approve or remove reviews',
                          () => _push(const ManageReviewsScreen())),
                      const Divider(height: 1),
                      item(Icons.block, Colors.red, 'Banned Users',
                          '$banned banned accounts',
                          () => _push(const BannedUsersScreen())),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700),
                  onPressed: _logout,
                  child: const Text('Log Out'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}