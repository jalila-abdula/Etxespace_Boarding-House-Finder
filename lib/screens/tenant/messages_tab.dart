import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/chat_room.dart';
import '../../models/property.dart';
import '../../services/chat_service.dart';
import '../../services/property_service.dart';
import '../../widgets/net_image.dart';
import 'chat_screen.dart';

class MessagesTab extends StatelessWidget {
  const MessagesTab({super.key});

  void _open(BuildContext context, ChatRoom room) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => ChatScreen(room: room)));

  Future<void> _newChat(BuildContext context) async {
    final chosen = await showModalBottomSheet<Property>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: StreamBuilder<List<Property>>(
          stream: PropertyService().activeProperties(),
          builder: (context, snap) {
            final list = snap.data ?? [];
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Message a landlord',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (list.isEmpty) const Text('No listings yet.'),
                ...list.map((p) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: NetImage(
                          url: p.images.isNotEmpty ? p.images.first : null,
                          width: 48,
                          height: 48,
                          radius: BorderRadius.circular(24)),
                      title: Text(p.name),
                      subtitle: Text(p.address),
                      onTap: () => Navigator.pop(context, p),
                    )),
              ],
            );
          },
        ),
      ),
    );
    if (chosen == null || !context.mounted) return;
    final room = await ChatService().openChat(
      propertyId: chosen.id,
      ownerId: chosen.ownerId,
      propertyName: chosen.name,
      propertyImage: chosen.images.isNotEmpty ? chosen.images.first : '',
    );
    if (context.mounted) _open(context, room);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Messages',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  IconButton(
                    onPressed: () => _newChat(context),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ChatRoom>>(
                stream: ChatService().chatsFor(uid),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final rooms = snap.data!;
                  if (rooms.isEmpty) {
                    return const Center(
                        child: Text('No conversations yet.\nTap + to message a landlord.',
                            textAlign: TextAlign.center));
                  }
                  return ListView.separated(
                    itemCount: rooms.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (_, i) {
                      final r = rooms[i];
                      final unread = r.unreadFor(uid);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        leading: NetImage(
                            url: r.propertyImage,
                            width: 52,
                            height: 52,
                            radius: BorderRadius.circular(26)),
                        title: Text(r.propertyName,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(r.lastMessage,
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
                        onTap: () => _open(context, r),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}