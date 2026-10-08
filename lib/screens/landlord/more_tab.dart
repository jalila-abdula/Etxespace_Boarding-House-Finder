import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/app_user.dart';
import '../../models/reservation.dart';
import '../../models/subscription.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/reservation_service.dart';
import '../../services/review_service.dart';
import '../../services/subscription_service.dart';
import '../tenant/edit_profile_screen.dart';
import '../tenant/notifications_screen.dart';
import 'analytics_screen.dart';
import 'inquiries_screen.dart';
import 'reviews_screen.dart';
import 'subscription_screen.dart';
import 'tenants_screen.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

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

  void _help(BuildContext context) {
    Widget q(String t) =>
        Text(t, style: const TextStyle(fontWeight: FontWeight.w700));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Help & Support'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              q('How do I accept a reservation?'),
              const Text('Open Reservations and tap Confirm. One room is taken out of availability automatically.'),
              const SizedBox(height: 12),
              q('A tenant moved out. What now?'),
              const Text('Tap "Mark as moved out" on the reservation. The room becomes available again.'),
              const SizedBox(height: 12),
              q('Why can I not add more properties?'),
              const Text('Your plan limits the number of properties and rooms. Open Subscription to upgrade.'),
              const SizedBox(height: 12),
              q('How do I hide a listing?'),
              const Text('Edit the property and turn off "Visible to tenants".'),
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

    Text plain(String s) =>
        Text(s, style: TextStyle(fontSize: 12, color: Colors.grey.shade600));

    Widget item(IconData icon, Color color, String title, Widget sub,
            VoidCallback onTap) =>
        ListTile(
          leading: Icon(icon, color: color),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: sub,
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('More',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            StreamBuilder<AppUser?>(
              stream: AuthService().userStream(uid),
              builder: (context, snap) {
                final u = snap.data;
                final name = (u?.name.isNotEmpty ?? false) ? u!.name : 'Landlord';
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: const Color(0xFF2962FF),
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
                            Text(u?.email ?? '',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20)),
                              child: const Text('Landlord',
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
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(
                children: [
                  item(
                    Icons.people,
                    Colors.blueGrey,
                    'Manage Tenants',
                    StreamBuilder<List<Reservation>>(
                      stream: ReservationService().ownerReservations(uid),
                      builder: (_, s) => plain(
                          '${(s.data ?? []).where((r) => r.status == ReservationStatus.confirmed).length} active tenants'),
                    ),
                    () => _push(context, const TenantsScreen()),
                  ),
                  const Divider(height: 1),
                  item(Icons.bar_chart, Colors.deepOrange, 'Analytics',
                      plain('View property performance'),
                      () => _push(context, const AnalyticsScreen())),
                  const Divider(height: 1),
                  item(
                    Icons.diamond,
                    Colors.lightBlue,
                    'Subscription',
                    StreamBuilder<ActivePlan>(
                      stream: SubscriptionService().current(uid),
                      builder: (_, s) {
                        final a = s.data;
                        if (a == null) return plain('');
                        return plain(a.expiresAt == null
                            ? '${a.plan.name} · Free'
                            : '${a.plan.name} · Renew ${DateFormat('MMM d').format(a.expiresAt!)}');
                      },
                    ),
                    () => _push(context, const SubscriptionScreen()),
                  ),
                  const Divider(height: 1),
                  item(
                    Icons.chat_bubble_outline,
                    Colors.black87,
                    'Inquiries',
                    StreamBuilder<int>(
                      stream: ChatService().unreadTotal(uid),
                      builder: (_, s) => plain('${s.data ?? 0} new messages'),
                    ),
                    () => _push(context, const InquiriesScreen()),
                  ),
                  const Divider(height: 1),
                  item(
                    Icons.star,
                    Colors.amber,
                    'Reviews',
                    StreamBuilder(
                      stream: ReviewService().forOwner(uid),
                      builder: (_, s) =>
                          plain('${(s.data ?? []).length} reviews received'),
                    ),
                    () => _push(context, const ReviewsScreen()),
                  ),
                  const Divider(height: 1),
                  item(Icons.person, Colors.blueGrey, 'Profile',
                      plain('Manage your account'),
                      () => _push(context, const EditProfileScreen())),
                  const Divider(height: 1),
                  item(Icons.notifications, Colors.amber, 'Notifications',
                      plain('Alerts and updates'),
                      () => _push(context, const NotificationsScreen())),
                  const Divider(height: 1),
                  item(Icons.help, Colors.red, 'Help & Support',
                      plain('FAQ, contact'), () => _help(context)),
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
          ],
        ),
      ),
    );
  }
}