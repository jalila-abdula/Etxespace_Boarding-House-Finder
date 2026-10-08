import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/reservation.dart';
import '../../services/chat_service.dart';
import '../../widgets/property_widgets.dart';
import '../tenant/chat_screen.dart';

Future<void> showReservationDetails(BuildContext context, Reservation r) {
  Widget row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(width: 16),
            Flexible(
                child: Text(v.isEmpty ? '-' : v,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.tenantName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            row('Email', r.tenantEmail),
            row('Phone', r.tenantPhone),
            const Divider(),
            row('Property', r.propertyName),
            row('Room type', r.roomType),
            row('Monthly rent', peso(r.price)),
            row('Move-in', DateFormat('MMMM d, y').format(r.moveIn)),
            row('Rental period',
                r.months == 1 ? '1 month' : '${r.months} months'),
            row('Expected move-out', DateFormat('MMMM d, y').format(r.moveOut)),
            row('Status', r.label),
            if (r.note.isNotEmpty) row('Note', r.note),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.green),
              onPressed: () async {
                final room = await ChatService().openChatAsOwner(
                  propertyId: r.propertyId,
                  tenantId: r.tenantId,
                  tenantName: r.tenantName,
                  propertyName: r.propertyName,
                  propertyImage: r.propertyImage,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!context.mounted) return;
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ChatScreen(room: room)));
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Message tenant'),
            ),
          ],
        ),
      ),
    ),
  );
}