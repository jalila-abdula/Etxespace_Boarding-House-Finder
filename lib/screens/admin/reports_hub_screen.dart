import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/admin_service.dart';
import '../../widgets/admin_ui.dart';
import 'generate_reports_screen.dart';
import 'reports_screen.dart';

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  Widget _card(BuildContext context,
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required Widget screen,
      int badge = 0}) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: cardDeco(),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14)),
              child: Badge(
                isLabelVisible: badge > 0,
                label: Text('$badge'),
                child: Icon(icon, color: color, size: 28),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Reports')),
      body: StreamBuilder<Snap>(
        stream: AdminService().reports(),
        builder: (context, snap) {
          final pending = snap.hasData ? AdminService.pending(snap.data!) : 0;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _card(
                context,
                icon: Icons.flag,
                color: Colors.red,
                title: 'Reported Listings',
                subtitle: pending == 0
                    ? 'Review listings reported by tenants'
                    : '$pending report${pending == 1 ? '' : 's'} waiting for review',
                screen: const ReportsScreen(),
                badge: pending,
              ),
              _card(
                context,
                icon: Icons.analytics_outlined,
                color: AppColors.orange,
                title: 'Generate Reports',
                subtitle: 'Users, properties, reservations, revenue, reviews',
                screen: const GenerateReportsScreen(),
              ),
            ],
          );
        },
      ),
    );
  }
}