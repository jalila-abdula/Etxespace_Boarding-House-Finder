import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/admin_service.dart';
import 'admin_dashboard_tab.dart';
import 'admin_properties_tab.dart';
import 'admin_settings_tab.dart';
import 'admin_subscriptions_tab.dart';
import 'admin_users_tab.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  late final Stream<int> _pendingPayments =
      AdminService().subscriptions().map(AdminService.pending);

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          AdminDashboardTab(onNavigate: _go),
          const AdminUsersTab(),
          const AdminPropertiesTab(),
          const AdminSubscriptionsTab(),
          const AdminSettingsTab(),
        ],
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: _pendingPayments,
        builder: (context, snap) {
          final n = snap.data ?? 0;
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _go,
            backgroundColor: Colors.white,
            indicatorColor: Colors.green.shade50,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.bar_chart),
                selectedIcon: Icon(Icons.bar_chart, color: AppColors.greenDark),
                label: 'Dashboard',
              ),
              const NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people, color: AppColors.greenDark),
                label: 'Users',
              ),
              const NavigationDestination(
                icon: Icon(Icons.apartment_outlined),
                selectedIcon: Icon(Icons.apartment, color: AppColors.greenDark),
                label: 'Properties',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: n > 0,
                  label: Text('$n'),
                  child: const Icon(Icons.credit_card_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: n > 0,
                  label: Text('$n'),
                  child:
                      const Icon(Icons.credit_card, color: AppColors.greenDark),
                ),
                label: 'Subscriptions',
              ),
              const NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings, color: AppColors.greenDark),
                label: 'Settings',
              ),
            ],
          );
        },
      ),
    );
  }
}