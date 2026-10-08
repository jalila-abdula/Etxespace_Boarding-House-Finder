import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';
import '../../widgets/property_widgets.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Reviews')),
      body: StreamBuilder<List<Review>>(
        stream: ReviewService().forOwner(uid),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(child: Text('No reviews yet.'));
          }
          final avg = list.fold<int>(0, (t, r) => t + r.rating) / list.length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Text(avg.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stars(avg.round(), size: 20),
                        Text('${list.length} reviews',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...list.map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(r.tenantName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Stars(r.rating, size: 14),
                          ],
                        ),
                        Text(r.propertyName,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
                        if (r.comment.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(r.comment),
                        ],
                        if (r.createdAt != null) ...[
                          const SizedBox(height: 6),
                          Text(DateFormat('MMM d, y').format(r.createdAt!),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}