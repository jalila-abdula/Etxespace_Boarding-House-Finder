import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/review.dart';
import '../../services/admin_service.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/multi_snap.dart';
import '../../widgets/property_widgets.dart';

class ManageReviewsScreen extends StatefulWidget {
  const ManageReviewsScreen({super.key});
  @override
  State<ManageReviewsScreen> createState() => _ManageReviewsScreenState();
}

class _ManageReviewsScreenState extends State<ManageReviewsScreen> {
  final _admin = AdminService();
  late final _reviews = _admin.reviews();

  Future<void> _remove(Review r) async {
    final ok = await confirmDialog(context, 'Remove this review?',
        'It is deleted and the property rating is recalculated.',
        yes: 'Remove', danger: true);
    if (!ok) return;
    try {
      await _admin.removeReview(r);
      if (mounted) toast(context, 'Review removed');
    } catch (e) {
      if (mounted) toast(context, 'Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Manage Reviews')),
      body: MultiSnap(
        streams: [_reviews],
        builder: (context, d) {
          final docs = d[0].docs.toList()..sort(AdminService.newest);
          final list = docs.map(Review.fromDoc).toList();
          if (list.isEmpty) return const Center(child: Text('No reviews.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final r = list[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: cardDeco(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(r.propertyName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        Stars(r.rating, size: 14),
                      ],
                    ),
                    Text(
                        'by ${r.tenantName}${r.createdAt == null ? '' : ' · ${DateFormat('MMM d, y').format(r.createdAt!)}'}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    if (r.comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(r.comment),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade700),
                        onPressed: () => _remove(r),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Remove'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}