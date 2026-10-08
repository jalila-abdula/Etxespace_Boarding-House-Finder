import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_room.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  /// Tenant opens (or creates) the chat for a boarding house.
  Future<ChatRoom> openChat({
    required String propertyId,
    required String ownerId,
    required String propertyName,
    required String propertyImage,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final ref = _db.collection('chats').doc('${propertyId}_${user.uid}');
    if (!(await ref.get()).exists) {
      await ref.set({
        'participants': [user.uid, ownerId],
        'propertyId': propertyId,
        'propertyName': propertyName,
        'propertyImage': propertyImage,
        'tenantId': user.uid,
        'tenantName': user.displayName ?? user.email ?? 'Tenant',
        'ownerId': ownerId,
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unread': {},
      });
    }
    return ChatRoom.fromDoc(await ref.get());
  }

  /// Landlord opens (or creates) the chat with a tenant.
  Future<ChatRoom> openChatAsOwner({
    required String propertyId,
    required String tenantId,
    required String tenantName,
    required String propertyName,
    required String propertyImage,
  }) async {
    final owner = FirebaseAuth.instance.currentUser!;
    final ref = _db.collection('chats').doc('${propertyId}_$tenantId');
    if (!(await ref.get()).exists) {
      await ref.set({
        'participants': [tenantId, owner.uid],
        'propertyId': propertyId,
        'propertyName': propertyName,
        'propertyImage': propertyImage,
        'tenantId': tenantId,
        'tenantName': tenantName,
        'ownerId': owner.uid,
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unread': {},
      });
    }
    return ChatRoom.fromDoc(await ref.get());
  }

  Future<void> send(ChatRoom room, String text) async {
    final me = FirebaseAuth.instance.currentUser!.uid;
    final other = me == room.tenantId ? room.ownerId : room.tenantId;
    final ref = _db.collection('chats').doc(room.id);
    final batch = _db.batch();
    batch.set(ref.collection('messages').doc(), {
      'senderId': me,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(ref, {
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unread.$other': FieldValue.increment(1),
    });
    await batch.commit();
  }

  Future<void> markRead(String roomId) {
    final me = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('chats').doc(roomId).update({'unread.$me': 0});
  }

  Stream<List<ChatRoom>> chatsFor(String uid) => _db
          .collection('chats')
          .where('participants', arrayContains: uid)
          .snapshots()
          .map((s) {
        final list = s.docs
            .map(ChatRoom.fromDoc)
            .where((r) => r.lastMessage.isNotEmpty)
            .toList();
        list.sort((a, b) => (b.lastMessageAt ?? DateTime.now())
            .compareTo(a.lastMessageAt ?? DateTime.now()));
        return list;
      });

  Stream<QuerySnapshot<Map<String, dynamic>>> messages(String roomId) => _db
      .collection('chats')
      .doc(roomId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .snapshots();

  Stream<int> unreadTotal(String uid) => chatsFor(uid).map(
      (rooms) => rooms.fold<int>(0, (total, r) => total + r.unreadFor(uid)));
}