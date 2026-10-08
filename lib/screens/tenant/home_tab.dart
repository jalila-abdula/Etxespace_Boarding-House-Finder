import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/notification_service.dart';
import '../../services/property_service.dart';
import '../../widgets/property_widgets.dart';
import 'notifications_screen.dart';
import 'property_details_screen.dart';

class HomeTab extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  const HomeTab({super.key, required this.onNavigate});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Position? _pos;

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  Future<void> _loadPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _pos = pos);
    } catch (_) {}
  }

  double? _km(Property p) => _pos == null
      ? null
      : Geolocator.distanceBetween(
              _pos!.latitude, _pos!.longitude, p.lat, p.lng) /
          1000;

  String _greeting() {
    final h = DateTime.now().hour;
    return h < 12
        ? 'Good morning'
        : h < 18
            ? 'Good afternoon'
            : 'Good evening';
  }

  void _open(Property p) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => PropertyDetailsScreen(propertyId: p.id)));

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            GestureDetector(
              onTap: () => widget.onNavigate(1),
              child: const Text('See all',
                  style: TextStyle(
                      color: AppColors.greenDark, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final first = (user.displayName ?? '').trim().split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: StreamBuilder<List<Property>>(
          stream: PropertyService().activeProperties(),
          builder: (context, snap) {
            final all = snap.data ?? [];
            final featured = all.where((p) => p.featured).toList();
            final near = [...all];
            if (_pos != null) {
              near.sort((a, b) => _km(a)!.compareTo(_km(b)!));
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting(),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                          Text('Hello${first.isEmpty ? '' : ', $first'}!',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800)),
                          const Text('Find your perfect',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.greenDark)),
                          const Text('boarding house',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    StreamBuilder<int>(
                      stream: NotificationService().unreadCount(user.uid),
                      builder: (context, s) {
                        final n = s.data ?? 0;
                        return IconButton.filledTonal(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const NotificationsScreen())),
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
                InkWell(
                  onTap: () => widget.onNavigate(1),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(children: [
                      Icon(Icons.search, color: Colors.grey.shade500),
                      const SizedBox(width: 10),
                      Text('Search boarding house, location...',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B7F4B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Find Comfortable\nPlaces to Stay',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2)),
                            const SizedBox(height: 12),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.green,
                                minimumSize: const Size(0, 38),
                              ),
                              onPressed: () => widget.onNavigate(1),
                              child: const Text('Explore Now'),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.weekend,
                          size: 70, color: Colors.white.withValues(alpha: 0.3)),
                    ],
                  ),
                ),
                if (featured.isNotEmpty) ...[
                  _section('Featured Boarding Houses'),
                  SizedBox(
                    height: 240,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: featured.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => FeaturedCard(
                          p: featured[i], onTap: () => _open(featured[i])),
                    ),
                  ),
                ],
                _section('Near You'),
                if (snap.connectionState == ConnectionState.waiting)
                  const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()))
                else if (near.isEmpty)
                  const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No listings yet')))
                else
                  ...near.take(5).map((p) => NearYouTile(
                      p: p, distanceKm: _km(p), onTap: () => _open(p))),
              ],
            );
          },
        ),
      ),
    );
  }
}