import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final bool read;
  final DateTime? createdAt;
  AppNotification(this.id, this.title, this.body, this.read, this.createdAt);
}

class NotificationService {
  final _col = FirebaseFirestore.instance.collection('notifications');

  Future<void> send({
    required String userId,
    required String title,
    required String body,
  }) =>
      _col.add({
        'userId': userId,
        'title': title,
        'body': body,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Stream<List<AppNotification>> forUser(String uid) =>
      _col.where('userId', isEqualTo: uid).snapshots().map((s) {
        final list = s.docs.map((d) {
          final m = d.data();
          return AppNotification(d.id, m['title'] ?? '', m['body'] ?? '',
              m['read'] ?? false, (m['createdAt'] as Timestamp?)?.toDate());
        }).toList();
        list.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        return list;
      });

  Stream<int> unreadCount(String uid) =>
      forUser(uid).map((l) => l.where((n) => !n.read).length);

  Future<void> markAllRead(String uid) async {
    final snap = await _col
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }
}