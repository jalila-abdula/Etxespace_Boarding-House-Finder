import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_exception.dart';
import '../../core/constants.dart';
import '../../models/reservation.dart';
import '../../services/reservation_service.dart';
import '../../widgets/net_image.dart';
import '../../widgets/status_chip.dart';
import 'reservation_details.dart';

class LandlordReservationsTab extends StatefulWidget {
  const LandlordReservationsTab({super.key});
  @override
  State<LandlordReservationsTab> createState() =>
      _LandlordReservationsTabState();
}

class _LandlordReservationsTabState extends State<LandlordReservationsTab> {
  static const _filters = ['All', 'Pending', 'Confirmed', 'Cancelled'];
  String _filter = 'All';
  final _service = ReservationService();
  late final Stream<List<Reservation>> _stream = _service
      .ownerReservations(FirebaseAuth.instance.currentUser!.uid);

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

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _run(Future<void> Function() action, String ok) async {
    try {
      await action();
      _toast(ok);
    } on AppException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Something went wrong. Try again.');
    }
  }

  Future<bool> _confirm(String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Back')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes')),
        ],
      ),
    );
    return ok == true;
  }

  Widget _actions(Reservation r) {
    if (r.status == ReservationStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.greenDark,
                  minimumSize: const Size.fromHeight(42)),
              onPressed: () =>
                  _run(() => _service.confirm(r), 'Reservation confirmed'),
              child: const Text('Confirm'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  minimumSize: const Size.fromHeight(42)),
              onPressed: () async {
                if (await _confirm('Reject this request?',
                    '${r.tenantName} will be notified.')) {
                  await _run(() => _service.decline(r), 'Reservation rejected');
                }
              },
              child: const Text('Reject'),
            ),
          ),
        ],
      );
    }
    if (r.status == ReservationStatus.confirmed) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(42),
            foregroundColor: AppColors.greenDark),
        onPressed: () async {
          if (await _confirm('Mark as moved out?',
              'The reservation will be completed and the room becomes available again.')) {
            await _run(() => _service.moveOut(r), 'Room is available again');
          }
        },
        child: const Text('Mark as moved out'),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text('Reservations',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ),
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
                            selectedColor: AppColors.greenDark,
                            labelStyle: TextStyle(
                                color: _filter == f
                                    ? Colors.white
                                    : Colors.black87),
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ))
                    .toList(),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Reservation>>(
                stream: _stream,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = snap.data!.where(_match).toList();
                  if (list.isEmpty) {
                    return const Center(child: Text('No reservations here.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final r = list[i];
                      final actions = _actions(r);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
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
                                IconButton.filledTonal(
                                  onPressed: () =>
                                      showReservationDetails(context, r),
                                  icon: const Icon(Icons.visibility_outlined,
                                      size: 18),
                                ),
                              ],
                            ),
                            if (r.status == ReservationStatus.pending ||
                                r.status == ReservationStatus.confirmed) ...[
                              const SizedBox(height: 12),
                              actions,
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