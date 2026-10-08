import 'package:cloud_firestore/cloud_firestore.dart';

class Plan {
  static const unlimited = 1000000;

  final String id;
  final String name;
  final double price;
  final int maxProperties;
  final int maxRooms;
  final bool featured;
  final bool analytics;

  const Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.maxProperties,
    required this.maxRooms,
    required this.featured,
    required this.analytics,
  });

  bool get isFree => price == 0;
  String get propertiesText =>
      maxProperties >= unlimited ? 'Unlimited' : '$maxProperties';

  factory Plan.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Plan(
      id: doc.id,
      name: d['name'] ?? 'PLAN',
      price: (d['price'] ?? 0).toDouble(),
      maxProperties: (d['maxProperties'] ?? unlimited).toInt(),
      maxRooms: (d['maxRooms'] ?? 0).toInt(),
      featured: d['featured'] ?? false,
      analytics: d['analytics'] ?? false,
    );
  }
}

/// Used until the admin creates plans in Firestore.
const defaultPlans = [
  Plan(id: 'free', name: 'FREE PLAN', price: 0, maxProperties: 1, maxRooms: 5, featured: false, analytics: false),
  Plan(id: 'standard', name: 'STANDARD PLAN', price: 299, maxProperties: 5, maxRooms: 20, featured: false, analytics: true),
  Plan(id: 'premium', name: 'PREMIUM PLAN', price: 999, maxProperties: Plan.unlimited, maxRooms: 30, featured: true, analytics: true),
];

class ActivePlan {
  final Plan plan;
  final DateTime? expiresAt;
  ActivePlan(this.plan, this.expiresAt);
}

class SubscriptionRequest {
  final String id;
  final String planName;
  final double price;
  final String status; // pending, active, rejected
  final DateTime? createdAt;

  SubscriptionRequest(this.id, this.planName, this.price, this.status, this.createdAt);

  factory SubscriptionRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return SubscriptionRequest(
      doc.id,
      d['planName'] ?? '',
      (d['price'] ?? 0).toDouble(),
      d['status'] ?? 'pending',
      (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}