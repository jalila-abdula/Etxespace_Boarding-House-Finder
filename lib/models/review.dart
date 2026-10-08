import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String propertyId;
  final String propertyName;
  final String tenantId;
  final String tenantName;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  Review({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.tenantId,
    required this.tenantName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Review(
      id: doc.id,
      propertyId: d['propertyId'] ?? '',
      propertyName: d['propertyName'] ?? '',
      tenantId: d['tenantId'] ?? '',
      tenantName: d['tenantName'] ?? '',
      rating: (d['rating'] ?? 0).toInt(),
      comment: d['comment'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}