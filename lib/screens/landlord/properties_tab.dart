import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/property_service.dart';
import '../../widgets/net_image.dart';
import '../../widgets/property_widgets.dart';
import 'property_form_screen.dart';

class PropertiesTab extends StatelessWidget {
  const PropertiesTab({super.key});

  void _form(BuildContext c, [Property? p]) => Navigator.push(c,
      MaterialPageRoute(builder: (_) => PropertyFormScreen(existing: p)));

  Widget _chip(String t, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: TextStyle(fontSize: 11, color: fg)),
      );

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Properties',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.greenDark,
                        minimumSize: const Size(0, 40)),
                    onPressed: () => _form(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Property'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Property>>(
                stream: PropertyService().ownerProperties(uid),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = snap.data!;
                  if (list.isEmpty) {
                    return const Center(
                        child: Text('No properties yet.\nTap Add Property.',
                            textAlign: TextAlign.center));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final p = list[i];
                      return GestureDetector(
                        onTap: () => _form(context, p),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 170,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    NetImage(
                                        url: p.images.isNotEmpty
                                            ? p.images.first
                                            : null,
                                        width: double.infinity,
                                        height: double.infinity),
                                    if (p.featured)
                                      Positioned(
                                          top: 10,
                                          left: 10,
                                          child: _chip('FEATURED',
                                              AppColors.green, Colors.white)),
                                    if (!p.active)
                                      Positioned(
                                          top: 10,
                                          right: 10,
                                          child: _chip('HIDDEN',
                                              Colors.black87, Colors.white)),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(p.name,
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700)),
                                          Text(p.address,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600)),
                                          const SizedBox(height: 8),
                                          Wrap(spacing: 6, runSpacing: 6, children: [
                                            _chip('${p.totalRooms} Rooms',
                                                Colors.grey.shade100,
                                                Colors.black87),
                                            _chip('${p.availableRooms} Available',
                                                Colors.green.shade50,
                                                AppColors.greenDark),
                                            _chip('${peso(p.price)}/mo',
                                                Colors.blue.shade50,
                                                Colors.blue.shade700),
                                          ]),
                                        ],
                                      ),
                                    ),
                                    IconButton.filledTonal(
                                      onPressed: () => _form(context, p),
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 18),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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