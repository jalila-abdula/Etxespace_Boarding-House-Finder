import 'package:cloud_firestore/cloud_firestore.dart';

class Property {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String address;
  final double lat;
  final double lng;
  final double price;
  final int totalRooms;
  final int availableRooms;
  final List<String> amenities;
  final List<String> images;
  final String houseRules;
  final bool featured;
  final bool active;
  final int ratingSum;
  final int ratingCount;

  Property({
    this.id = '',
    required this.ownerId,
    required this.name,
    required this.description,
    required this.address,
    required this.lat,
    required this.lng,
    required this.price,
    required this.totalRooms,
    required this.availableRooms,
    required this.amenities,
    required this.images,
    this.houseRules = '',
    this.featured = false,
    this.active = true,
    this.ratingSum = 0,
    this.ratingCount = 0,
  });

  double get rating => ratingCount == 0 ? 0 : ratingSum / ratingCount;

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'name': name,
        'description': description,
        'address': address,
        'lat': lat,
        'lng': lng,
        'price': price,
        'totalRooms': totalRooms,
        'availableRooms': availableRooms,
        'amenities': amenities,
        'images': images,
        'houseRules': houseRules,
        'featured': featured,
        'active': active,
        'ratingSum': ratingSum,
        'ratingCount': ratingCount,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory Property.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Property(
      id: doc.id,
      ownerId: d['ownerId'] ?? '',
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      address: d['address'] ?? '',
      lat: (d['lat'] ?? 0).toDouble(),
      lng: (d['lng'] ?? 0).toDouble(),
      price: (d['price'] ?? 0).toDouble(),
      totalRooms: d['totalRooms'] ?? 0,
      availableRooms: d['availableRooms'] ?? 0,
      amenities: List<String>.from(d['amenities'] ?? []),
      images: List<String>.from(d['images'] ?? []),
      houseRules: d['houseRules'] ?? '',
      featured: d['featured'] ?? false,
      active: d['active'] ?? true,
      ratingSum: (d['ratingSum'] ?? 0).toInt(),
      ratingCount: (d['ratingCount'] ?? 0).toInt(),
    );
  }
}