import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteService {
  CollectionReference<Map<String, dynamic>> col(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favorites');

  Stream<Set<String>> ids(String uid) =>
      col(uid).snapshots().map((s) => s.docs.map((d) => d.id).toSet());
}