import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../models/reservation.dart';
import '../../models/subscription.dart';
import '../../services/notification_service.dart';
import '../../services/property_service.dart';
import '../../services/reservation_service.dart';
import '../../services/subscription_service.dart';
import '../../widgets/net_image.dart';
import '../../widgets/status_chip.dart';
import '../tenant/notifications_screen.dart';
import 'analytics_screen.dart';
import 'property_form_screen.dart';
import 'subscription_screen.dart';
import 'tenants_screen.dart';

class DashboardTab extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const DashboardTab({super.key, required this.onNavigate});

  void _push(BuildContext c, Widget w) =>
      Navigator.push(c, MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: StreamBuilder<List<Property>>(
          stream: PropertyService().ownerProperties(user.uid),
          builder: (context, ps) => StreamBuilder<List<Reservation>>(
            stream: ReservationService().ownerReservations(user.uid),
            builder: (context, rs) {
              final props = ps.data ?? [];
              final res = rs.data ?? [];
              final totalRooms = props.fold<int>(0, (t, p) => t + p.totalRooms);
              final available =
                  props.fold<int>(0, (t, p) => t + p.availableRooms);
              final pending = res
                  .where((r) => r.status == ReservationStatus.pending)
                  .length;
              final confirmed = res
                  .where((r) => r.status == ReservationStatus.confirmed)
                  .length;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome back,',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600)),
                            Text(user.displayName ?? user.email ?? 'Landlord',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      StreamBuilder<int>(
                        stream: NotificationService().unreadCount(user.uid),
                        builder: (context, s) {
                          final n = s.data ?? 0;
                          return IconButton.filledTonal(
                            onPressed: () =>
                                _push(context, const NotificationsScreen()),
                            icon: Badge(
                              isLabelVisible: n > 0,
                              label: Text('$n'),
                              child: const Icon(Icons.notifications_none),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  StreamBuilder<ActivePlan>(
                    stream: SubscriptionService().current(user.uid),
                    builder: (context, s) {
                      final a = s.data;
                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Current Plan',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.85),
                                        fontSize: 12)),
                                Icon(Icons.verified_user_outlined,
                                    color: Colors.white.withValues(alpha: 0.8)),
                              ],
                            ),
                            Text(a?.plan.name ?? '...',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800)),
                            Text(
                                a?.expiresAt == null
                                    ? 'No expiry'
                                    : 'Expires on ${DateFormat('MMM d, y').format(a!.expiresAt!)}',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12)),
                            const SizedBox(height: 12),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.25),
                                minimumSize: const Size(0, 38),
                              ),
                              onPressed: () =>
                                  _push(context, const SubscriptionScreen()),
                              child: const Text('View Subscription'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  const Text('Overview',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.7,
                    children: [
                      _Tile('${props.length}', 'Properties', Colors.blue),
                      _Tile('$totalRooms', 'Total Rooms', Colors.purple),
                      _Tile('$available', 'Available Rooms', Colors.green),
                      _Tile('${totalRooms - available}', 'Occupied',
                          Colors.deepOrange),
                      _Tile('$pending', 'Pending Reservations', Colors.orange),
                      _Tile('$confirmed', 'Confirmed Reservations',
                          Colors.green),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Reservations',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      GestureDetector(
                        onTap: () => onNavigate(2),
                        child: const Text('See all',
                            style: TextStyle(
                                color: AppColors.greenDark,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (res.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                          child: Text('No reservations yet.',
                              style: TextStyle(color: Colors.grey.shade600))),
                    ),
                  ...res.take(3).map((r) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            NetImage(
                                url: r.propertyImage,
                                width: 48,
                                height: 48,
                                radius: BorderRadius.circular(12)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.tenantName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  Text(r.propertyName,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700)),
                                  Text(
                                      '${r.roomType} · ${DateFormat('MMM d, y').format(r.moveIn)}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            StatusChip(r.status, prefix: false),
                          ],
                        ),
                      )),
                  const SizedBox(height: 8),
                  const Text('Quick Actions',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 3,
                    children: [
                      _Action(Icons.add_home_work_outlined, 'Add Property',
                          () => _push(context, const PropertyFormScreen())),
                      _Action(Icons.people_outline, 'Manage Tenants',
                          () => _push(context, const TenantsScreen())),
                      _Action(Icons.bar_chart, 'Analytics',
                          () => _push(context, const AnalyticsScreen())),
                      _Action(Icons.diamond_outlined, 'Subscription',
                          () => _push(context, const SubscriptionScreen())),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String value;
  final String label;
  final MaterialColor color;
  const _Tile(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.shade50, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color.shade700)),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Action(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.greenDark),
            const SizedBox(width: 8),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}