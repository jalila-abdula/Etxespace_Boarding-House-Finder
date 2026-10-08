import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_exception.dart';
import '../models/subscription.dart';

class SubscriptionService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Plan>> plans() => _db.collection('plans').snapshots().map((s) {
        final list = s.docs
            .where((d) => d.data()['active'] != false)
            .map(Plan.fromDoc)
            .toList();
        if (list.isEmpty) return defaultPlans;
        list.sort((a, b) => a.price.compareTo(b.price));
        return list;
      });

  ActivePlan _resolve(QuerySnapshot<Map<String, dynamic>> s) {
    final now = DateTime.now();
    ActivePlan? best;
    for (final d in s.docs) {
      final m = d.data();
      final exp = (m['expiresAt'] as Timestamp?)?.toDate();
      if (m['status'] != 'active' || exp == null || !exp.isAfter(now)) continue;
      if (best == null || exp.isAfter(best.expiresAt!)) {
        best = ActivePlan(
          Plan(
            id: m['planId'] ?? d.id,
            name: m['planName'] ?? 'PLAN',
            price: (m['price'] ?? 0).toDouble(),
            maxProperties: (m['maxProperties'] ?? Plan.unlimited).toInt(),
            maxRooms: (m['maxRooms'] ?? 0).toInt(),
            featured: m['featured'] ?? false,
            analytics: m['analytics'] ?? false,
          ),
          exp,
        );
      }
    }
    return best ?? ActivePlan(defaultPlans.first, null);
  }

  Stream<ActivePlan> current(String uid) => _db
      .collection('subscriptions')
      .where('landlordId', isEqualTo: uid)
      .snapshots()
      .map(_resolve);

  Future<ActivePlan> currentOnce(String uid) async => _resolve(await _db
      .collection('subscriptions')
      .where('landlordId', isEqualTo: uid)
      .get());

  Future<void> request({required Plan plan, required String proofUrl}) async {
    final user = FirebaseAuth.instance.currentUser!;
    final mine = await _db
        .collection('subscriptions')
        .where('landlordId', isEqualTo: user.uid)
        .get();
    if (mine.docs.any((d) => d.data()['status'] == 'pending')) {
      throw AppException(
          'You already have a payment waiting for approval.');
    }
    await _db.collection('subscriptions').add({
      'landlordId': user.uid,
      'landlordName': user.displayName ?? user.email ?? 'Landlord',
      'planId': plan.id,
      'planName': plan.name,
      'price': plan.price,
      'maxProperties': plan.maxProperties,
      'maxRooms': plan.maxRooms,
      'featured': plan.featured,
      'analytics': plan.analytics,
      'proofUrl': proofUrl,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<SubscriptionRequest>> history(String uid) => _db
          .collection('subscriptions')
          .where('landlordId', isEqualTo: uid)
          .snapshots()
          .map((s) {
        final list = s.docs.map(SubscriptionRequest.fromDoc).toList();
        list.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        return list;
      });
}