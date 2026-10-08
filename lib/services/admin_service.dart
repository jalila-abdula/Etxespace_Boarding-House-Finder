import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/app_exception.dart';
import '../core/constants.dart';
import '../models/reservation.dart';
import '../models/review.dart';
import '../models/subscription.dart';
import 'notification_service.dart';

typedef Snap = QuerySnapshot<Map<String, dynamic>>;
typedef Doc = QueryDocumentSnapshot<Map<String, dynamic>>;

class AdminService {
  final _db = FirebaseFirestore.instance;
  final _notify = NotificationService();

  // ---------- Streams ----------
  Stream<Snap> users() => _db.collection('users').snapshots();
  Stream<Snap> properties() => _db.collection('properties').snapshots();
  Stream<Snap> reservations() => _db.collection('reservations').snapshots();
  Stream<Snap> subscriptions() => _db.collection('subscriptions').snapshots();
  Stream<Snap> plans() => _db.collection('plans').snapshots();
  Stream<Snap> reports() => _db.collection('reports').snapshots();
  Stream<Snap> reviews() => _db.collection('reviews').snapshots();

  // ---------- Helpers ----------
  static Map<String, String> names(Snap users) => {
        for (final d in users.docs)
          d.id: (((d.data()['name'] ?? '') as String).isNotEmpty
              ? d.data()['name']
              : (d.data()['email'] ?? 'User')) as String,
      };

  static int pending(Snap s) =>
      s.docs.where((d) => d.data()['status'] == 'pending').length;

  static DateTime? created(Map<String, dynamic> d) =>
      (d['createdAt'] as Timestamp?)?.toDate();

  static int newest(Doc a, Doc b) =>
      (created(b.data()) ?? DateTime.now())
          .compareTo(created(a.data()) ?? DateTime.now());

  // ---------- Users ----------
  Future<void> setUserActive(String uid, String role, bool active) async {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(uid), {'active': active});
    if (!active && role == Roles.landlord) {
      final props = await _db
          .collection('properties')
          .where('ownerId', isEqualTo: uid)
          .get();
      for (final p in props.docs) {
        batch.update(p.reference, {'active': false});
      }
    }
    await batch.commit();
  }

  // ---------- Properties ----------
  Future<void> setPropertyActive(
      String id, bool active, String ownerId, String name) async {
    await _db.collection('properties').doc(id).update({'active': active});
    if (!active) {
      await _notify.send(
        userId: ownerId,
        title: 'Listing hidden',
        body: 'Your listing "$name" was hidden by the administrator.',
      );
    }
  }

  Future<void> removeProperty(String id, String ownerId, String name) async {
    await _db.collection('properties').doc(id).delete();
    await _notify.send(
      userId: ownerId,
      title: 'Listing removed',
      body: 'Your listing "$name" was removed by the administrator.',
    );
  }

  // ---------- Reservations ----------
  /// Admin override. If the reservation was confirmed, the room is freed.
  Future<void> cancelReservation(Reservation r) async {
    await _db.runTransaction((tx) async {
      final resRef = _db.collection('reservations').doc(r.id);
      final propRef = _db.collection('properties').doc(r.propertyId);
      final res = await tx.get(resRef);
      final status = res.data()?['status'];
      if (status != ReservationStatus.pending &&
          status != ReservationStatus.confirmed) {
        throw AppException('This reservation can no longer be cancelled.');
      }
      DocumentSnapshot<Map<String, dynamic>>? prop;
      if (status == ReservationStatus.confirmed) prop = await tx.get(propRef);

      tx.update(resRef, {'status': ReservationStatus.cancelled});
      if (prop != null && prop.exists) {
        final d = prop.data()!;
        final total = ((d['totalRooms'] ?? 0) as num).toInt();
        final available = ((d['availableRooms'] ?? 0) as num).toInt();
        tx.update(propRef,
            {'availableRooms': available + 1 > total ? total : available + 1});
      }
    });
    const msg = 'The administrator cancelled this reservation.';
    await _notify.send(
        userId: r.tenantId,
        title: 'Reservation cancelled',
        body: '${r.propertyName}: $msg');
    await _notify.send(
        userId: r.ownerId,
        title: 'Reservation cancelled',
        body: '${r.tenantName} at ${r.propertyName}: $msg');
  }

  // ---------- Subscriptions ----------
  Future<void> approvePayment(String id) async {
    final ref = _db.collection('subscriptions').doc(id);
    final snap = await ref.get();
    final d = snap.data();
    if (d == null) throw AppException('Request not found.');
    if (d['status'] != 'pending') {
      throw AppException('This request was already processed.');
    }
    final now = DateTime.now();
    final expires = now.add(const Duration(days: 30));
    final landlordId = d['landlordId'] as String;
    final featured = d['featured'] == true;

    final batch = _db.batch();
    batch.update(ref, {
      'status': 'active',
      'startsAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expires),
    });
    final props = await _db
        .collection('properties')
        .where('ownerId', isEqualTo: landlordId)
        .get();
    for (final p in props.docs) {
      batch.update(p.reference, {'featured': featured});
    }
    await batch.commit();

    await _notify.send(
      userId: landlordId,
      title: 'Subscription approved',
      body:
          'Your ${d['planName']} is active until ${DateFormat('MMM d, y').format(expires)}.',
    );
  }

  Future<void> rejectPayment(String id) async {
    final ref = _db.collection('subscriptions').doc(id);
    final snap = await ref.get();
    final d = snap.data();
    if (d == null) throw AppException('Request not found.');
    if (d['status'] != 'pending') {
      throw AppException('This request was already processed.');
    }
    await ref.update({'status': 'rejected'});
    await _notify.send(
      userId: d['landlordId'] as String,
      title: 'Payment rejected',
      body:
          'Your payment for ${d['planName']} could not be verified. Please submit a clearer proof.',
    );
  }

  Future<void> savePlan({
    String? id,
    required String name,
    required double price,
    required int maxProperties,
    required int maxRooms,
    required bool featured,
    required bool analytics,
    required bool priority,
  }) async {
    final data = {
      'name': name,
      'price': price,
      'maxProperties': maxProperties,
      'maxRooms': maxRooms,
      'featured': featured,
      'analytics': analytics,
      'priority': priority,
    };
    if (id == null) {
      await _db.collection('plans').add(
          {...data, 'active': true, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await _db.collection('plans').doc(id).update(data);
    }
  }

  Future<void> setPlanActive(String id, bool active) =>
      _db.collection('plans').doc(id).update({'active': active});

  Future<void> deletePlan(String id) =>
      _db.collection('plans').doc(id).delete();

  Future<void> seedDefaultPlans() async {
    final batch = _db.batch();
    for (final p in defaultPlans) {
      batch.set(_db.collection('plans').doc(p.id), {
        'name': p.name,
        'price': p.price,
        'maxProperties': p.maxProperties,
        'maxRooms': p.maxRooms,
        'featured': p.featured,
        'analytics': p.analytics,
        'priority': false,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // ---------- Reports ----------
  Future<void> hideReportedListing({
    required String reportId,
    required String propertyId,
    required String ownerId,
    required String propertyName,
    String reporterId = '',
  }) async {
    final propRef = _db.collection('properties').doc(propertyId);
    final batch = _db.batch();
    if ((await propRef.get()).exists) batch.update(propRef, {'active': false});
    batch.update(_db.collection('reports').doc(reportId), {
      'status': 'resolved',
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    if (ownerId.isNotEmpty) {
      await _notify.send(
        userId: ownerId,
        title: 'Listing hidden',
        body:
            '"$propertyName" was hidden after a report. Please review it and contact the administrator.',
      );
    }
    if (reporterId.isNotEmpty) {
      await _notify.send(
        userId: reporterId,
        title: 'Report reviewed',
        body:
            'Thank you. We reviewed your report about "$propertyName" and hid the listing.',
      );
    }
  }

  Future<void> dismissReport(
    String id, {
    String reporterId = '',
    String propertyName = '',
  }) async {
    await _db.collection('reports').doc(id).update({
      'status': 'dismissed',
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    if (reporterId.isNotEmpty) {
      await _notify.send(
        userId: reporterId,
        title: 'Report reviewed',
        body:
            'We reviewed your report about "$propertyName" and found no violation.',
      );
    }
  }

  // ---------- Reviews ----------
  Future<void> removeReview(Review r) async {
    final batch = _db.batch();
    batch.delete(_db.collection('reviews').doc(r.id));
    final propRef = _db.collection('properties').doc(r.propertyId);
    if ((await propRef.get()).exists) {
      batch.update(propRef, {
        'ratingSum': FieldValue.increment(-r.rating),
        'ratingCount': FieldValue.increment(-1),
      });
    }
    await batch.commit();
  }
}