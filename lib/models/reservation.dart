import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationStatus {
  static const pending = 'pending';
  static const confirmed = 'confirmed';
  static const declined = 'declined';
  static const cancelled = 'cancelled';
  static const completed = 'completed';
}

class Reservation {
  final String id;
  final String tenantId;
  final String tenantName;
  final String tenantEmail;
  final String tenantPhone;
  final String ownerId;
  final String propertyId;
  final String propertyName;
  final String propertyImage;
  final String roomType;
  final String status;
  final String note;
  final double price;
  final DateTime moveIn;
  final int months;
  final DateTime? createdAt;

  Reservation({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.tenantEmail,
    required this.tenantPhone,
    required this.ownerId,
    required this.propertyId,
    required this.propertyName,
    required this.propertyImage,
    required this.roomType,
    required this.status,
    required this.note,
    required this.price,
    required this.moveIn,
    required this.months,
    this.createdAt,
  });

  factory Reservation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Reservation(
      id: doc.id,
      tenantId: d['tenantId'] ?? '',
      tenantName: d['tenantName'] ?? '',
      tenantEmail: d['tenantEmail'] ?? '',
      tenantPhone: d['tenantPhone'] ?? '',
      ownerId: d['ownerId'] ?? '',
      propertyId: d['propertyId'] ?? '',
      propertyName: d['propertyName'] ?? '',
      propertyImage: d['propertyImage'] ?? '',
      roomType: d['roomType'] ?? '',
      status: d['status'] ?? ReservationStatus.pending,
      note: d['note'] ?? '',
      price: (d['price'] ?? 0).toDouble(),
      moveIn: (d['moveInDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      months: (d['months'] ?? 1).toInt(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  DateTime get moveOut => DateTime(moveIn.year, moveIn.month + months, moveIn.day);
  String get label => status[0].toUpperCase() + status.substring(1);
}