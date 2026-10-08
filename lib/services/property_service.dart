import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';

class PropertyService {
  final _col = FirebaseFirestore.instance.collection('properties');

  Future<void> addProperty(Property p) => _col.add(p.toMap());

  Future<void> updateProperty(String id, Map<String, dynamic> data) =>
      _col.doc(id).update(data);

  Future<void> deleteProperty(String id) => _col.doc(id).delete();

  Future<void> addView(String id) =>
      _col.doc(id).update({'views': FieldValue.increment(1)}).catchError((_) {});

  Stream<List<Property>> activeProperties() => _col
      .where('active', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map(Property.fromDoc).toList());

  Stream<List<Property>> ownerProperties(String ownerId) => _col
      .where('ownerId', isEqualTo: ownerId)
      .snapshots()
      .map((s) => s.docs.map(Property.fromDoc).toList());

  Future<List<Property>> ownerPropertiesOnce(String ownerId) async {
    final s = await _col.where('ownerId', isEqualTo: ownerId).get();
    return s.docs.map(Property.fromDoc).toList();
  }
}