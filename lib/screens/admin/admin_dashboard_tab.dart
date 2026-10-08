import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../models/reservation.dart';
import '../../services/admin_service.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/multi_snap.dart';
import '../../widgets/net_image.dart';
import 'admin_alerts_screen.dart';
import 'admin_reservations_screen.dart';
import 'reports_hub_screen.dart';

class AdminDashboardTab extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  const AdminDashboardTab({super.key, required this.onNavigate});
  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  final _admin = AdminService();
  late final _streams = <Stream<Snap>>[
    _admin.users(),
    _admin.properties(),
    _admin.reservations(),
    _admin.subscriptions(),
    _admin.reports(),
  ];

  void _push(Widget w) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: MultiSnap(
          streams: _streams,
          builder: (context, d) {
            final users = d[0].docs;
            final props = d[1].docs;
            final res = d[2].docs;
            final alerts = AdminService.pending(d[3]) + AdminService.pending(d[4]);
            final names = AdminService.names(d[0]);

            final members = users.where((u) {
              final r = u.data()['role'];
              return r == Roles.tenant || r == Roles.landlord;
            }).toList();
            final landlords =
                members.where((u) => u.data()['role'] == Roles.landlord).length;

            int rooms = 0, available = 0;
            for (final p in props) {
              rooms += ((p.data()['totalRooms'] ?? 0) as num).toInt();
              available += ((p.data()['availableRooms'] ?? 0) as num).toInt();
            }

            int pending = 0, confirmed = 0, cancelled = 0;
            for (final r in res) {
              switch (r.data()['status']) {
                case ReservationStatus.pending:
                  pending++;
                case ReservationStatus.confirmed:
                case ReservationStatus.completed:
                  confirmed++;
                default:
                  cancelled++;
              }
            }

            final recent = props.toList()..sort(AdminService.newest);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('System Overview',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                          const Text('Admin Dashboard',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => _push(const AdminAlertsScreen()),
                      icon: Badge(
                        isLabelVisible: alerts > 0,
                        label: Text('$alerts'),
                        child: const Icon(Icons.notifications_none),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Overview',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.7,
                  children: [
                    _Tile('${members.length}', 'Total Users', Colors.blue),
                    _Tile('$landlords', 'Landlords', Colors.purple),
                    _Tile('$rooms', 'Total Rooms', Colors.green),
                    _Tile('$available', 'Available Rooms', Colors.teal),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('Reservations Overview',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: cardDeco(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Count('$pending', 'Pending', const Color(0xFFF59E0B)),
                          _Count('$confirmed', 'Confirmed', AppColors.greenDark),
                          _Count('$cancelled', 'Cancelled', Colors.red),
                          _Count('${res.length}', 'Total', Colors.blueGrey),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: CustomPaint(
                          painter: _DonutPainter(
                            [pending.toDouble(), confirmed.toDouble(), cancelled.toDouble()],
                            const [Color(0xFFF59E0B), Color(0xFF16A34A), Color(0xFFEF4444)],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${res.length}',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800)),
                                Text('Total',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Management',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.1,
                  children: [
                    _Manage(Icons.people, 'Users', () => widget.onNavigate(1)),
                    _Manage(Icons.home_work, 'Properties',
                        () => widget.onNavigate(2)),
                    _Manage(Icons.assignment, 'Reservations',
                        () => _push(const AdminReservationsScreen())),
                    _Manage(Icons.diamond, 'Subscriptions',
                        () => widget.onNavigate(3)),
                    _Manage(Icons.flag, 'Reports',
                        () => _push(const ReportsHubScreen())),
                    _Manage(Icons.settings, 'Settings',
                        () => widget.onNavigate(4)),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('Recent Properties',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (recent.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                        child: Text('No properties yet.',
                            style: TextStyle(color: Colors.grey.shade600))),
                  ),
                ...recent.take(3).map((doc) {
                  final p = Property.fromDoc(doc);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: cardDeco(16),
                    child: Row(
                      children: [
                        NetImage(
                            url: p.images.isNotEmpty ? p.images.first : null,
                            width: 48,
                            height: 48,
                            radius: BorderRadius.circular(12)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Text(p.address,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600)),
                              Text('Owner: ${names[p.ownerId] ?? '-'}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        p.active ? const Pill.green('Active') : const Pill.grey('Hidden'),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
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
  Widget build(BuildContext context) => Container(
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

class _Count extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Count(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      );
}

class _Manage extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Manage(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: cardDeco(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: AppColors.orange),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  _DonutPainter(this.values, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Rect.fromLTWH(
        stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total == 0) {
      paint.color = Colors.grey.shade200;
      canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
      return;
    }
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * 2 * math.pi;
      paint.color = colors[i];
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}