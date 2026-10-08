import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/admin_service.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/multi_snap.dart';

class BannedUsersScreen extends StatefulWidget {
  const BannedUsersScreen({super.key});
  @override
  State<BannedUsersScreen> createState() => _BannedUsersScreenState();
}

class _BannedUsersScreenState extends State<BannedUsersScreen> {
  final _admin = AdminService();
  late final _users = _admin.users();

  Future<void> _unban(Doc doc) async {
    final ok = await confirmDialog(context, 'Activate this account?',
        'The user can sign in again.');
    if (!ok) return;
    try {
      await _admin.setUserActive(doc.id, (doc.data()['role'] ?? '') as String, true);
      if (mounted) toast(context, 'Account activated');
    } catch (e) {
      if (mounted) toast(context, 'Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Banned Users')),
      body: MultiSnap(
        streams: [_users],
        builder: (context, d) {
          final list =
              d[0].docs.where((x) => x.data()['active'] == false).toList();
          if (list.isEmpty) {
            return const Center(child: Text('No banned accounts.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final doc = list[i];
              final m = doc.data();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: cardDeco(14),
                child: ListTile(
                  title: Text((m['name'] ?? '') as String,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${m['email'] ?? ''} · ${m['role'] ?? ''}'),
                  trailing: OutlinedButton(
                    onPressed: () => _unban(doc),
                    child: const Text('Unban'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}