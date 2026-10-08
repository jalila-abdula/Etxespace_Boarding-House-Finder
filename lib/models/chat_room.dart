import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatRoom {
  final String id;
  final String propertyId;
  final String propertyName;
  final String propertyImage;
  final String tenantId;
  final String tenantName;
  final String ownerId;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unread;

  ChatRoom({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.propertyImage,
    required this.tenantId,
    required this.tenantName,
    required this.ownerId,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unread,
  });

  int unreadFor(String uid) => unread[uid] ?? 0;

  factory ChatRoom.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final raw = Map<String, dynamic>.from(d['unread'] ?? {});
    return ChatRoom(
      id: doc.id,
      propertyId: d['propertyId'] ?? '',
      propertyName: d['propertyName'] ?? '',
      propertyImage: d['propertyImage'] ?? '',
      tenantId: d['tenantId'] ?? '',
      tenantName: d['tenantName'] ?? '',
      ownerId: d['ownerId'] ?? '',
      lastMessage: d['lastMessage'] ?? '',
      lastMessageAt: (d['lastMessageAt'] as Timestamp?)?.toDate(),
      unread: raw.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }
}

String formatChatTime(DateTime? t) {
  if (t == null) return '';
  final now = DateTime.now();
  final sameDay = t.year == now.year && t.month == now.month && t.day == now.day;
  return sameDay ? DateFormat('h:mm a').format(t) : DateFormat('MMM d').format(t);
}