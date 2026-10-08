import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/admin_service.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/multi_snap.dart';
import '../../widgets/net_image.dart';
import '../../widgets/property_widgets.dart';

class AdminPropertiesTab extends StatefulWidget {
  const AdminPropertiesTab({super.key});
  @override
  State<AdminPropertiesTab> createState() => _AdminPropertiesTabState();
}

class _AdminPropertiesTabState extends State<AdminPropertiesTab> {
  final _admin = AdminService();
  late final _streams = <Stream<Snap>>[_admin.properties(), _admin.users()];
  String _q = '';

  Future<void> _remove(Property p) async {
    final ok = await confirmDialog(context, 'Remove this property?',
        '"${p.name}" will be deleted and the owner notified.',
        yes: 'Remove', danger: true);
    if (!ok) return;
    try {
      await _admin.removeProperty(p.id, p.ownerId, p.name);
      if (mounted) toast(context, 'Property removed');
    } catch (e) {
      if (mounted) toast(context, 'Failed: $e');
    }
  }

  Future<void> _toggle(Property p) async {
    try {
      await _admin.setPropertyActive(p.id, !p.active, p.ownerId, p.name);
      if (mounted) toast(context, p.active ? 'Listing hidden' : 'Listing visible');
    } catch (e) {
      if (mounted) toast(context, 'Failed: $e');
    }
  }

  void _view(Property p, String owner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          children: [
            if (p.images.isNotEmpty)
              SizedBox(
                height: 190,
                child: PageView(
                  children: p.images
                      .map((u) => NetImage(
                          url: u,
                          width: double.infinity,
                          height: 190,
                          radius: BorderRadius.circular(16)))
                      .toList(),
                ),
              ),
            const SizedBox(height: 14),
            Text(p.name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(p.address, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text('Owner: $owner'),
            Text('${peso(p.price)}/month · ${p.totalRooms} rooms · ${p.availableRooms} available'),
            Text(p.ratingCount == 0
                ? 'No reviews yet'
                : 'Rating ${p.rating.toStringAsFixed(1)} (${p.ratingCount} reviews)'),
            if (p.amenities.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                  spacing: 6,
                  children:
                      p.amenities.map((a) => Chip(label: Text(a))).toList()),
            ],
            const SizedBox(height: 10),
            Text(p.description),
            if (p.houseRules.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('House rules',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Text(p.houseRules),
            ],
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _toggle(p);
              },
              child: Text(p.active ? 'Hide listing' : 'Show listing'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const AdminHeader('Properties'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                onChanged: (v) => setState(() => _q = v.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search properties...',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: MultiSnap(
                streams: _streams,
                builder: (context, d) {
                  final names = AdminService.names(d[1]);
                  final docs = d[0].docs.toList()..sort(AdminService.newest);
                  final list = docs
                      .map(Property.fromDoc)
                      .where((p) =>
                          p.name.toLowerCase().contains(_q) ||
                          p.address.toLowerCase().contains(_q))
                      .toList();
                  if (list.isEmpty) {
                    return const Center(child: Text('No properties found.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final p = list[i];
                      final owner = names[p.ownerId] ?? '-';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        clipBehavior: Clip.antiAlias,
                        decoration: cardDeco(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 160,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  NetImage(
                                      url: p.images.isNotEmpty
                                          ? p.images.first
                                          : null,
                                      width: double.infinity,
                                      height: double.infinity),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: p.active
                                        ? const Pill(
                                            'Active',
                                            AppColors.green, Colors.white)
                                        : const Pill(
                                            'Hidden', Colors.black87, Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                                  Text(p.address,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600)),
                                  Text('Owner: $owner',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600)),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Pill.grey('${p.totalRooms} rooms'),
                                      const SizedBox(width: 6),
                                      Pill.green('${p.availableRooms} available'),
                                      const Spacer(),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(0, 34),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14)),
                                        onPressed: () => _view(p, owner),
                                        child: const Text('View'),
                                      ),
                                      const SizedBox(width: 6),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(0, 34),
                                            foregroundColor: Colors.red,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14)),
                                        onPressed: () => _remove(p),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}