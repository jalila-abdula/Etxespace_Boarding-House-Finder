import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import '../tenant/chat_screen.dart';

class InquiriesScreen extends StatelessWidget {
  const InquiriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Inquiries')),
      body: StreamBuilder<List<ChatRoom>>(
        stream: ChatService().chatsFor(uid),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rooms = snap.data!;
          if (rooms.isEmpty) {
            return const Center(child: Text('No inquiries yet.'));
          }
          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (_, i) {
              final r = rooms[i];
              final unread = r.unreadFor(uid);
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                      r.tenantName.isEmpty ? '?' : r.tenantName[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.greenDark,
                          fontWeight: FontWeight.w700)),
                ),
                title: Text(r.tenantName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${r.propertyName} · ${r.lastMessage}',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatChatTime(r.lastMessageAt),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    if (unread > 0) ...[
                      const SizedBox(height: 4),
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: AppColors.greenDark,
                        child: Text('$unread',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11)),
                      ),
                    ],
                  ],
                ),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ChatScreen(room: r))),
              );
            },
          );
        },
      ),
    );
  }
}