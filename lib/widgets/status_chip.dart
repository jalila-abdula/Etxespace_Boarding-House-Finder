import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/reservation.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final bool prefix;
  const StatusChip(this.status, {super.key, this.prefix = true});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case ReservationStatus.confirmed:
        bg = Colors.green.shade50;
        fg = AppColors.greenDark;
      case ReservationStatus.completed:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
      case ReservationStatus.cancelled:
      case ReservationStatus.declined:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
    }
    final label = status[0].toUpperCase() + status.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(prefix ? 'Status: $label' : label,
          style: TextStyle(fontSize: 11, color: fg)),
    );
  }
}