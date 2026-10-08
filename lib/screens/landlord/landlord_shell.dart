import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/reservation.dart';
import '../../services/reservation_service.dart';
import 'dashboard_tab.dart';
import 'more_tab.dart';
import 'properties_tab.dart';
import 'reservations_tab.dart';

class LandlordShell extends StatefulWidget {
  const LandlordShell({super.key});
  @override
  State<LandlordShell> createState() => _LandlordShellState();
}

class _LandlordShellState extends State<LandlordShell> {
  int _index = 0;
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  late final Stream<int> _pending = ReservationService()
      .ownerReservations(_uid)
      .map((l) =>
          l.where((r) => r.status == ReservationStatus.pending).length);

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DashboardTab(onNavigate: _go),
          const PropertiesTab(),
          const LandlordReservationsTab(),
          const MoreTab(),
        ],
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: _pending,
        builder: (context, snap) {
          final n = snap.data ?? 0;
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _go,
            backgroundColor: Colors.white,
            indicatorColor: Colors.green.shade50,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: AppColors.greenDark),
                label: 'Dashboard',
              ),
              const NavigationDestination(
                icon: Icon(Icons.apartment_outlined),
                selectedIcon:
                    Icon(Icons.apartment, color: AppColors.greenDark),
                label: 'Properties',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: n > 0,
                  label: Text('$n'),
                  child: const Icon(Icons.calendar_today_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: n > 0,
                  label: Text('$n'),
                  child: const Icon(Icons.calendar_today,
                      color: AppColors.greenDark),
                ),
                label: 'Reservations',
              ),
              const NavigationDestination(
                icon: Icon(Icons.menu),
                selectedIcon: Icon(Icons.menu, color: AppColors.greenDark),
                label: 'More',
              ),
            ],
          );
        },
      ),
    );
  }
}