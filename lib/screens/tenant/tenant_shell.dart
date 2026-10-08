import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/chat_service.dart';
import 'explore_tab.dart';
import 'home_tab.dart';
import 'messages_tab.dart';
import 'profile_tab.dart';
import 'reservations_tab.dart';

class TenantShell extends StatefulWidget {
  const TenantShell({super.key});
  @override
  State<TenantShell> createState() => _TenantShellState();
}

class _TenantShellState extends State<TenantShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeTab(onNavigate: _go),
          const ExploreTab(),
          const ReservationsTab(),
          const MessagesTab(),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: ChatService().unreadTotal(uid),
        builder: (context, snap) {
          final unread = snap.data ?? 0;
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _go,
            backgroundColor: Colors.white,
            indicatorColor: Colors.green.shade50,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: AppColors.greenDark),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.search),
                selectedIcon: Icon(Icons.search, color: AppColors.greenDark),
                label: 'Explore',
              ),
              const NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon:
                    Icon(Icons.calendar_today, color: AppColors.greenDark),
                label: 'Reservations',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.chat_bubble_outline),
                ),
                selectedIcon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.chat_bubble,
                      color: AppColors.greenDark),
                ),
                label: 'Messages',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: AppColors.greenDark),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}