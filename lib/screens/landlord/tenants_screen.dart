import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/reservation.dart';
import '../../services/reservation_service.dart';
import 'reservation_details.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});
  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  String _q = '';
  late final Stream<List<Reservation>> _stream = ReservationService()
      .ownerReservations(FirebaseAuth.instance.currentUser!.uid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Tenants')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _q = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search tenant...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Reservation>>(
              stream: _stream,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data!
                    .where((r) =>
                        (r.status == ReservationStatus.confirmed ||
                            r.status == ReservationStatus.completed) &&
                        r.tenantName.toLowerCase().contains(_q))
                    .toList();
                if (list.isEmpty) {
                  return const Center(
                      child: Text('No tenants yet.\nConfirmed reservations appear here.',
                          textAlign: TextAlign.center));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final r = list[i];
                    final active = r.status == ReservationStatus.confirmed;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        onTap: () => showReservationDetails(context, r),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text(r.tenantName[0].toUpperCase(),
                              style: const TextStyle(
                                  color: AppColors.greenDark,
                                  fontWeight: FontWeight.w700)),
                        ),
                        title: Text(r.tenantName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            '${r.roomType} · ${r.propertyName}\nMove-in: ${DateFormat('MMM d, y').format(r.moveIn)}'),
                        isThreeLine: true,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(active ? 'Active' : 'Inactive',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: active
                                      ? AppColors.greenDark
                                      : Colors.red.shade700)),
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
    );
  }
}