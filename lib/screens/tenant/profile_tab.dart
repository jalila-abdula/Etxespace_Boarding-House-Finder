import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/favorite_service.dart';
import '../../services/reservation_service.dart';
import '../../services/review_service.dart';
import 'edit_profile_screen.dart';
import 'my_reviews_screen.dart';
import 'notifications_screen.dart';
import 'saved_properties_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  void _push(BuildContext c, Widget w) =>
      Navigator.push(c, MaterialPageRoute(builder: (_) => w));

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Log out', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) await AuthService().logout();
  }

  void _privacy(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Privacy & Security',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_reset),
                title: const Text('Change password'),
                subtitle: Text('We will email a reset link to ${user.email}'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await AuthService().resetPassword(user.email ?? '');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Password reset link sent')));
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Could not send the reset link')));
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _help(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How do I reserve a room?',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Text('Open a boarding house, tap "Reserve a room", choose your move-in date, and send the request.'),
              SizedBox(height: 12),
              Text('How do I cancel?',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Text('Go to Reservations and tap Cancel on a pending request.'),
              SizedBox(height: 12),
              Text('Need more help?',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Text('Message the landlord from the listing or your reservation.'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    Widget item(IconData icon, Color color, String title, Widget sub,
        VoidCallback onTap) {
      return ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: sub,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
    }

    Text plain(String s) =>
        Text(s, style: TextStyle(fontSize: 12, color: Colors.grey.shade600));

    Widget countText(Stream<int> stream, String Function(int) fmt) =>
        StreamBuilder<int>(
            stream: stream,
            builder: (_, s) => plain(fmt(s.data ?? 0)));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            StreamBuilder<AppUser?>(
              stream: AuthService().userStream(uid),
              builder: (context, snap) {
                final u = snap.data;
                final name = (u?.name.isNotEmpty ?? false) ? u!.name : 'Tenant';
                return Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(18)),
                      alignment: Alignment.center,
                      child: Text(name[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w800)),
                          Text(u?.email ?? '',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20)),
                            child: const Text('Tenant',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.greenDark)),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _push(context, const EditProfileScreen()),
                      child: const Text('Edit'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Stat(
                    ReservationService()
                        .tenantReservations(uid)
                        .map((l) => l.length),
                    'Reservations'),
                const SizedBox(width: 10),
                _Stat(ReviewService().forTenant(uid).map((l) => l.length),
                    'Reviews'),
                const SizedBox(width: 10),
                _Stat(FavoriteService().ids(uid).map((s) => s.length), 'Saved'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(
                children: [
                  item(Icons.person_outline, Colors.blueGrey, 'Edit Profile',
                      plain('Update your personal info'),
                      () => _push(context, const EditProfileScreen())),
                  const Divider(height: 1),
                  item(
                      Icons.favorite,
                      Colors.red,
                      'Saved Properties',
                      countText(FavoriteService().ids(uid).map((s) => s.length),
                          (n) => '$n properties saved'),
                      () => _push(context, const SavedPropertiesScreen())),
                  const Divider(height: 1),
                  item(Icons.notifications, Colors.amber, 'Notifications',
                      plain('Manage alerts'),
                      () => _push(context, const NotificationsScreen())),
                  const Divider(height: 1),
                  item(
                      Icons.star,
                      Colors.amber,
                      'My Reviews',
                      countText(ReviewService().forTenant(uid).map((l) => l.length),
                          (n) => '$n reviews written'),
                      () => _push(context, const MyReviewsScreen())),
                  const Divider(height: 1),
                  item(Icons.lock, Colors.amber.shade800, 'Privacy & Security',
                      plain('Password'), () => _privacy(context)),
                  const Divider(height: 1),
                  item(Icons.help, Colors.red, 'Help & Support',
                      plain('FAQ, contact us'), () => _help(context)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700),
              onPressed: () => _logout(context),
              child: const Text('Log Out'),
            ),
            const SizedBox(height: 12),
            Center(
                child: Text('ETXESPACE v1.0.0',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500))),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final Stream<int> stream;
  final String label;
  const _Stat(this.stream, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            StreamBuilder<int>(
              stream: stream,
              builder: (_, s) => Text('${s.data ?? 0}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}