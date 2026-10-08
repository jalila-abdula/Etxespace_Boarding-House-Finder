import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/reservation.dart';
import '../../services/chat_service.dart';
import '../../services/reservation_service.dart';
import '../../widgets/net_image.dart';
import 'chat_screen.dart';

class ReservationsTab extends StatefulWidget {
  const ReservationsTab({super.key});
  @override
  State<ReservationsTab> createState() => _ReservationsTabState();
}

class _ReservationsTabState extends State<ReservationsTab> {
  static const _filters = ['All', 'Pending', 'Confirmed', 'Cancelled'];
  String _filter = 'All';

  // "Confirmed" also lists completed stays; "Cancelled" also lists declined ones.
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

  Future<void> _message(Reservation r) async {
    final room = await ChatService().openChat(
      propertyId: r.propertyId,
      ownerId: r.ownerId,
      propertyName: r.propertyName,
      propertyImage: r.propertyImage,
    );
    if (!mounted) return;
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => ChatScreen(room: room)));
  }

  Future<void> _cancel(Reservation r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel reservation?'),
        content: Text('Your request for ${r.propertyName} will be cancelled.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep it')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel reservation',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) await ReservationService().cancel(r.id);
  }

  void _details(Reservation r) {
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(k, style: TextStyle(color: Colors.grey.shade600)),
              Flexible(
                  child: Text(v,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
        );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.propertyName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            row('Status', r.label),
            row('Room type', r.roomType),
            row('Move-in', DateFormat('MMMM d, y').format(r.moveIn)),
            row('Rental period',
                r.months == 1 ? '1 month' : '${r.months} months'),
            if (r.createdAt != null)
              row('Requested on', DateFormat('MMM d, y').format(r.createdAt!)),
            if (r.note.isNotEmpty) row('Your note', r.note),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text('My Reservations',
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
                stream: ReservationService().tenantReservations(uid),
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
                    itemBuilder: (_, i) => _ReservationCard(
                      r: list[i],
                      onMessage: () => _message(list[i]),
                      onCancel: () => _cancel(list[i]),
                      onDetails: () => _details(list[i]),
                    ),
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

class _ReservationCard extends StatelessWidget {
  final Reservation r;
  final VoidCallback onMessage;
  final VoidCallback onCancel;
  final VoidCallback onDetails;
  const _ReservationCard({
    required this.r,
    required this.onMessage,
    required this.onCancel,
    required this.onDetails,
  });

  (Color, Color) get _colors {
    switch (r.status) {
      case ReservationStatus.confirmed:
        return (Colors.green.shade50, AppColors.greenDark);
      case ReservationStatus.completed:
        return (Colors.blue.shade50, Colors.blue.shade700);
      case ReservationStatus.cancelled:
      case ReservationStatus.declined:
        return (Colors.red.shade50, Colors.red.shade700);
      default:
        return (Colors.orange.shade50, Colors.orange.shade800);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    final msgBtn = OutlinedButton(
      onPressed: onMessage,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.greenDark,
        side: BorderSide(color: Colors.green.shade200),
        minimumSize: const Size.fromHeight(42),
      ),
      child: const Text('Message'),
    );

    Widget? action;
    if (r.status == ReservationStatus.pending) {
      action = FilledButton(
        onPressed: onCancel,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red.shade700,
          minimumSize: const Size.fromHeight(42),
        ),
        child: const Text('Cancel'),
      );
    } else if (r.status == ReservationStatus.confirmed ||
        r.status == ReservationStatus.completed) {
      action = FilledButton(
        onPressed: onDetails,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.greenDark,
          minimumSize: const Size.fromHeight(42),
        ),
        child: const Text('View Details'),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                  width: 72,
                  height: 72,
                  radius: BorderRadius.circular(14)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.propertyName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(r.roomType,
                        style: TextStyle(color: Colors.grey.shade700)),
                    Text('Move-in: ${DateFormat('MMM d, y').format(r.moveIn)}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: bg, borderRadius: BorderRadius.circular(20)),
                      child: Text('Status: ${r.label}',
                          style: TextStyle(fontSize: 11, color: fg)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: msgBtn),
              if (action != null) ...[
                const SizedBox(width: 10),
                Expanded(child: action),
              ],
            ],
          ),
        ],
      ),
    );
  }
}