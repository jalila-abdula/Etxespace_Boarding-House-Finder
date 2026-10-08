import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_exception.dart';
import '../models/property.dart';
import '../models/review.dart';

class ReviewService {
  final _db = FirebaseFirestore.instance;

  Future<void> add({
    required Property property,
    required int rating,
    required String comment,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final ref = _db.collection('reviews').doc('${property.id}_${user.uid}');
    if ((await ref.get()).exists) {
      throw AppException('You already reviewed this boarding house.');
    }
    final batch = _db.batch();
    batch.set(ref, {
      'propertyId': property.id,
      'propertyName': property.name,
      'ownerId': property.ownerId,
      'tenantId': user.uid,
      'tenantName': user.displayName ?? user.email ?? 'Tenant',
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('properties').doc(property.id), {
      'ratingSum': FieldValue.increment(rating),
      'ratingCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  Stream<List<Review>> _stream(String field, String value) => _db
          .collection('reviews')
          .where(field, isEqualTo: value)
          .snapshots()
          .map((s) {
        final list = s.docs.map(Review.fromDoc).toList();
        list.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        return list;
      });

  Stream<List<Review>> forProperty(String propertyId) =>
      _stream('propertyId', propertyId);

  Stream<List<Review>> forTenant(String uid) => _stream('tenantId', uid);

  Stream<List<Review>> forOwner(String uid) => _stream('ownerId', uid);
}