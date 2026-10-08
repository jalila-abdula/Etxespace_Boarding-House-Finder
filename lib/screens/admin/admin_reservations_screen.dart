import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_exception.dart';
import '../../core/constants.dart';
import '../../models/reservation.dart';
import '../../services/admin_service.dart';
import '../../services/reservation_service.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/multi_snap.dart';
import '../../widgets/net_image.dart';
import '../../widgets/status_chip.dart';

class AdminReservationsScreen extends StatefulWidget {
  const AdminReservationsScreen({super.key});
  @override
  State<AdminReservationsScreen> createState() =>
      _AdminReservationsScreenState();
}

class _AdminReservationsScreenState extends State<AdminReservationsScreen> {
  static const _filters = ['All', 'Pending', 'Confirmed', 'Cancelled'];
  final _admin = AdminService();
  late final _res = _admin.reservations();
  String _filter = 'All';

  bool _match(Reservation r) {
    switch (_filter) {
      case 'Pending':
        return r.status == ReservationStatus.pending;
      case 'Confirmed':
        return r.status == ReservationStatus.confirmed ||
            r.status == ReservationStatus.completed;
      case 'Cancelled':
        return r.status == ReservationStatus.cancelled ||
            r.status == ReservationStatus.declined;
      default:
        return true;
    }
  }

  Future<void> _run(Future<void> Function() action, String ok) async {
    try {
      await action();
      if (mounted) toast(context, ok);
    } on AppException catch (e) {
      if (mounted) toast(context, e.message);
    } catch (e) {
      if (mounted) toast(context, 'Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminHeader('Reservations'),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _filters
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: _filter == f,
                            selectedColor: AppColors.orange,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                                color: _filter == f
                                    ? Colors.white
                                    : Colors.black87),
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ))
                    .toList(),
              ),
            ),
            Expanded(
              child: MultiSnap(
                streams: [_res],
                builder: (context, d) {
                  final docs = d[0].docs.toList()..sort(AdminService.newest);
                  final list =
                      docs.map(Reservation.fromDoc).where(_match).toList();
                  if (list.isEmpty) {
                    return const Center(child: Text('No reservations here.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final r = list[i];
                      final pending = r.status == ReservationStatus.pending;
                      final confirmed = r.status == ReservationStatus.confirmed;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: cardDeco(),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                NetImage(
                                    url: r.propertyImage,
                                    width: 56,
                                    height: 56,
                                    radius: BorderRadius.circular(12)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(r.tenantName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700)),
                                      Text(r.propertyName,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade700)),
                                      Text(
                                          '${r.roomType} · ${DateFormat('MMM d, y').format(r.moveIn)}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600)),
                                      const SizedBox(height: 4),
                                      StatusChip(r.status),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (pending || confirmed) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          minimumSize: const Size.fromHeight(40)),
                                      onPressed: () async {
                                        final ok = await confirmDialog(
                                            context,
                                            'Cancel this reservation?',
                                            'Both the tenant and the landlord will be notified.',
                                            danger: true);
                                        if (ok) {
                                          await _run(
                                              () => _admin.cancelReservation(r),
                                              'Reservation cancelled');
                                        }
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  if (confirmed) ...[
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.greenDark,
                                            minimumSize:
                                                const Size.fromHeight(40)),
                                        onPressed: () async {
                                          final ok = await confirmDialog(
                                              context,
                                              'Mark as completed?',
                                              'The room becomes available again.');
                                          if (ok) {
                                            await _run(
                                                () => ReservationService()
                                                    .moveOut(r),
                                                'Reservation completed');
                                          }
                                        },
                                        child: const Text('Mark completed'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
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