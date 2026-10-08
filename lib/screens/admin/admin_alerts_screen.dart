import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/admin_service.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/multi_snap.dart';
import '../../widgets/property_widgets.dart';
import 'admin_subscriptions_tab.dart';
import 'reports_screen.dart';

/// System alerts: pending payment requests and pending reports.
class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({super.key});
  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen> {
  final _admin = AdminService();
  late final _streams = <Stream<Snap>>[_admin.subscriptions(), _admin.reports()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('System Alerts')),
      body: MultiSnap(
        streams: _streams,
        builder: (context, d) {
          final pays =
              d[0].docs.where((x) => x.data()['status'] == 'pending').toList();
          final reps =
              d[1].docs.where((x) => x.data()['status'] == 'pending').toList();
          if (pays.isEmpty && reps.isEmpty) {
            return const Center(child: Text('No new alerts.'));
          }
          Widget header(String t) => Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                child: Text(t,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pays.isNotEmpty) header('Payment requests (${pays.length})'),
              ...pays.map((x) {
                final m = x.data();
                final price = ((m['price'] ?? 0) as num).toDouble();
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: cardDeco(14),
                  child: ListTile(
                    leading: const Icon(Icons.payments_outlined,
                        color: AppColors.orange),
                    title: Text('${m['landlordName'] ?? 'Landlord'} · ${m['planName'] ?? ''}'),
                    subtitle: Text(peso(price)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminSubscriptionsTab())),
                  ),
                );
              }),
              if (reps.isNotEmpty) header('Reported listings (${reps.length})'),
              ...reps.map((x) {
                final m = x.data();
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: cardDeco(14),
                  child: ListTile(
                    leading: const Icon(Icons.flag, color: Colors.red),
                    title: Text((m['propertyName'] ?? 'Listing') as String),
                    subtitle: Text((m['reason'] ?? '') as String),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ReportsScreen())),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}