import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/chat_room.dart';
import '../../models/property.dart';
import '../../models/reservation.dart';
import '../../models/subscription.dart';
import '../../services/chat_service.dart';
import '../../services/reservation_service.dart';
import '../../services/subscription_service.dart';
import '../../widgets/property_widgets.dart';
import 'subscription_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static const _periods = ['This Month', 'Last Month', 'This Year'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _period = 'This Month';
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  late final _planStream = SubscriptionService().current(_uid);
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _propStream =
      FirebaseFirestore.instance
          .collection('properties')
          .where('ownerId', isEqualTo: _uid)
          .snapshots();
  late final _resStream = ReservationService().ownerReservations(_uid);
  late final _chatStream = ChatService().chatsFor(_uid);

  (DateTime, DateTime) _range({bool previous = false}) {
    final n = DateTime.now();
    if (_period == 'This Year') {
      final y = previous ? n.year - 1 : n.year;
      return (DateTime(y, 1, 1), DateTime(y + 1, 1, 1));
    }
    var m = _period == 'Last Month' ? n.month - 1 : n.month;
    if (previous) m -= 1;
    return (DateTime(n.year, m, 1), DateTime(n.year, m + 1, 1));
  }

  bool _in(DateTime? d, (DateTime, DateTime) r) =>
      d != null && !d.isBefore(r.$1) && d.isBefore(r.$2);

  Widget _pill(String t, MaterialColor c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: c.shade50, borderRadius: BorderRadius.circular(20)),
        child: Text(t,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: c.shade700)),
      );

  Widget _trend(num cur, num prev) {
    if (prev == 0) return cur == 0 ? const SizedBox.shrink() : _pill('New', Colors.green);
    final pct = (cur - prev) / prev * 100;
    final up = pct >= 0;
    return _pill('${up ? '+' : ''}${pct.toStringAsFixed(0)}%',
        up ? Colors.green : Colors.red);
  }

  Widget _card(Widget child) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: child,
      );

  Widget _stat(String label, String value, Widget trend) => _card(Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800)),
            ],
          ),
          trend,
        ],
      ));

  Widget _locked() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48, color: Colors.grey.shade500),
              const SizedBox(height: 12),
              const Text('Analytics is not in your plan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Upgrade to the Standard or Premium plan to see how your properties perform.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.green),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen())),
                child: const Text('View Subscription'),
              ),
            ],
          ),
        ),
      );

  Widget _content(QuerySnapshot<Map<String, dynamic>> propSnap,
      List<Reservation> res, int chats) {
    final props = propSnap.docs.map(Property.fromDoc).toList();
    final views = propSnap.docs
        .fold<int>(0, (t, d) => t + ((d.data()['views'] ?? 0) as num).toInt());

    final cur = _range();
    final prev = _range(previous: true);
    final curRes = res.where((r) => _in(r.createdAt, cur)).length;
    final prevRes = res.where((r) => _in(r.createdAt, prev)).length;

    double revenueIn((DateTime, DateTime) range) => res
        .where((r) =>
            (r.status == ReservationStatus.confirmed ||
                r.status == ReservationStatus.completed) &&
            _in(r.moveIn, range))
        .fold<double>(0, (t, r) => t + r.price);
    final revenue = revenueIn(cur);
    final prevRevenue = revenueIn(prev);

    final year = DateTime.now().year;
    final counts = List<int>.filled(12, 0);
    for (final r in res) {
      final d = r.createdAt;
      if (d != null && d.year == year) counts[d.month - 1]++;
    }
    final maxCount = counts.fold<int>(0, (m, c) => c > m ? c : m);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _stat('Property views (all time)', '$views', const SizedBox.shrink()),
        _stat('Inquiries (conversations)', '$chats', const SizedBox.shrink()),
        _stat('Reservations ($_period)', '$curRes', _trend(curRes, prevRes)),
        _card(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Reservations ($year)',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  12,
                  (i) => Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (counts[i] > 0)
                          Text('${counts[i]}',
                              style: const TextStyle(fontSize: 9)),
                        Container(
                          height:
                              maxCount == 0 ? 2 : 80 * counts[i] / maxCount + 2,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: counts[i] == 0
                                ? Colors.grey.shade200
                                : AppColors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_months[i],
                            style: TextStyle(
                                fontSize: 8, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        )),
        _card(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Room Occupancy',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (props.isEmpty)
              Text('No properties yet.',
                  style: TextStyle(color: Colors.grey.shade600)),
            ...props.map((p) {
              final used = p.totalRooms - p.availableRooms;
              final v = p.totalRooms == 0 ? 0.0 : used / p.totalRooms;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(p.name, style: const TextStyle(fontSize: 12)),
                        Text('$used/${p.totalRooms}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: v,
                        minHeight: 8,
                        color: AppColors.green,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        )),
        _card(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booked Revenue ($_period)',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(peso(revenue),
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            _trend(revenue, prevRevenue),
            const SizedBox(height: 8),
            Text(
                'Monthly rent of confirmed and completed reservations with a move-in date in this period.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButton<String>(
              value: _period,
              underline: const SizedBox.shrink(),
              items: _periods
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _period = v!),
            ),
          ),
        ],
      ),
      body: StreamBuilder<ActivePlan>(
        stream: _planStream,
        builder: (context, planSnap) {
          if (!planSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!planSnap.data!.plan.analytics) return _locked();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _propStream,
            builder: (context, ps) => StreamBuilder<List<Reservation>>(
              stream: _resStream,
              builder: (context, rs) => StreamBuilder<List<ChatRoom>>(
                stream: _chatStream,
                builder: (context, cs) {
                  if (!ps.hasData || !rs.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _content(ps.data!, rs.data!, (cs.data ?? []).length);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}