import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_exception.dart';
import '../models/property.dart';
import '../models/reservation.dart';
import 'notification_service.dart';

class ReservationService {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('reservations');

  // ---------- Tenant ----------

  Future<void> create({
    required Property property,
    required String roomType,
    required DateTime moveIn,
    required int months,
    String note = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final name = user.displayName ?? user.email ?? 'A tenant';

    final mine = await _col.where('tenantId', isEqualTo: user.uid).get();
    final hasActive = mine.docs.any((d) {
      final m = d.data();
      return m['propertyId'] == property.id &&
          (m['status'] == ReservationStatus.pending ||
              m['status'] == ReservationStatus.confirmed);
    });
    if (hasActive) {
      throw AppException(
          'You already have an active reservation at this boarding house.');
    }

    final me = await _db.collection('users').doc(user.uid).get();
    final phone = me.data()?['phone'] ?? '';

    await _col.add({
      'tenantId': user.uid,
      'tenantName': name,
      'tenantEmail': user.email ?? '',
      'tenantPhone': phone,
      'ownerId': property.ownerId,
      'propertyId': property.id,
      'propertyName': property.name,
      'propertyImage': property.images.isNotEmpty ? property.images.first : '',
      'roomType': roomType,
      'price': property.price,
      'moveInDate': Timestamp.fromDate(moveIn),
      'months': months,
      'note': note,
      'status': ReservationStatus.pending,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await NotificationService().send(
      userId: property.ownerId,
      title: 'New reservation request',
      body: '$name requested a $roomType at ${property.name}.',
    );
  }

  List<Reservation> _sorted(QuerySnapshot<Map<String, dynamic>> s) {
    final list = s.docs.map(Reservation.fromDoc).toList();
    list.sort((a, b) => (b.createdAt ?? DateTime.now())
        .compareTo(a.createdAt ?? DateTime.now()));
    return list;
  }

  Stream<List<Reservation>> tenantReservations(String uid) =>
      _col.where('tenantId', isEqualTo: uid).snapshots().map(_sorted);

  Future<void> cancel(String id) =>
      _col.doc(id).update({'status': ReservationStatus.cancelled});

  Future<bool> canReview(String propertyId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final s = await _col.where('tenantId', isEqualTo: uid).get();
    return s.docs.any((d) {
      final m = d.data();
      return m['propertyId'] == propertyId &&
          (m['status'] == ReservationStatus.confirmed ||
              m['status'] == ReservationStatus.completed);
    });
  }

  // ---------- Landlord ----------

  Stream<List<Reservation>> ownerReservations(String uid) =>
      _col.where('ownerId', isEqualTo: uid).snapshots().map(_sorted);

  /// Confirms a pending request and takes one room out of availability.
  
  Future<void> confirm(Reservation r) async {
    await _db.runTransaction((tx) async {
      final propRef = _db.collection('properties').doc(r.propertyId);
      final resRef = _col.doc(r.id);
      final prop = await tx.get(propRef);
      final res = await tx.get(resRef);

      if (res.data()?['status'] != ReservationStatus.pending) {
        throw AppException('This reservation was already updated.');
      }
      final available = ((prop.data()?['availableRooms'] ?? 0) as num).toInt();
      if (available <= 0) {
        throw AppException(
            'No rooms available. Update the room availability first.');
      }
      tx.update(propRef, {'availableRooms': available - 1});
      tx.update(resRef, {'status': ReservationStatus.confirmed});
    });

    await NotificationService().send(
      userId: r.tenantId,
      title: 'Reservation confirmed',
      body: 'Your ${r.roomType} at ${r.propertyName} was confirmed.',
    );
  }

  Future<void> decline(Reservation r) async {
    await _col.doc(r.id).update({'status': ReservationStatus.declined});
    await NotificationService().send(
      userId: r.tenantId,
      title: 'Reservation declined',
      body: 'Your request for ${r.propertyName} was declined.',
    );
  }

  /// Tenant moved out: close the reservation and free the room again.
  Future<void> moveOut(Reservation r) async {
    await _db.runTransaction((tx) async {
      final propRef = _db.collection('properties').doc(r.propertyId);
      final prop = await tx.get(propRef);
      tx.update(_col.doc(r.id), {'status': ReservationStatus.completed});
      if (prop.exists) {
        final d = prop.data()!;
        final total = ((d['totalRooms'] ?? 0) as num).toInt();
        final available = ((d['availableRooms'] ?? 0) as num).toInt();
        tx.update(propRef,
            {'availableRooms': available + 1 > total ? total : available + 1});
      }
    });
  }
}