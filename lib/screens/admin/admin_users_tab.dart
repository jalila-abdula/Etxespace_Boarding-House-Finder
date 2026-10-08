import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../services/admin_service.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/multi_snap.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});
  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _admin = AdminService();
  late final _users = _admin.users();
  String _role = Roles.tenant;
  String _q = '';

  Future<void> _manage(Doc doc) async {
    final d = doc.data();
    final active = d['active'] != false;
    final role = (d['role'] ?? '') as String;
    final joined = (d['createdAt'] as Timestamp?)?.toDate();

    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(k, style: TextStyle(color: Colors.grey.shade600)),
              Flexible(
                  child: Text(v.isEmpty ? '-' : v,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
        );

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text((d['name'] ?? 'User') as String,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              row('Email', (d['email'] ?? '') as String),
              row('Phone', (d['phone'] ?? '') as String),
              row('Role', role),
              row('Joined',
                  joined == null ? '' : DateFormat('MMM d, y').format(joined)),
              row('Status', active ? 'Active' : 'Inactive (banned)'),
              const SizedBox(height: 14),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor:
                        active ? Colors.red.shade600 : AppColors.green),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await confirmDialog(
                    context,
                    active ? 'Deactivate this account?' : 'Activate this account?',
                    active
                        ? 'The user will be locked out. A landlord\'s listings are hidden too.'
                        : 'The user can sign in again. Hidden listings stay hidden until the landlord shows them.',
                    danger: active,
                  );
                  if (!ok) return;
                  try {
                    await _admin.setUserActive(doc.id, role, !active);
                    if (mounted) {
                      toast(context,
                          active ? 'Account deactivated' : 'Account activated');
                    }
                  } catch (e) {
                    if (mounted) toast(context, 'Failed: $e');
                  }
                },
                child: Text(active ? 'Deactivate account' : 'Activate account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const AdminHeader('Users'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final r in [Roles.tenant, Roles.landlord])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(r == Roles.tenant ? 'Tenants' : 'Landlords'),
                        selected: _role == r,
                        selectedColor: AppColors.orange,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                            color: _role == r ? Colors.white : Colors.black87),
                        onSelected: (_) => setState(() => _role = r),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (v) => setState(() => _q = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText:
                      'Search ${_role == Roles.tenant ? 'tenants' : 'landlords'}...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: MultiSnap(
                streams: [_users],
                builder: (context, data) {
                  final list = data[0].docs.where((d) {
                    final m = d.data();
                    final text =
                        '${m['name'] ?? ''} ${m['email'] ?? ''}'.toLowerCase();
                    return m['role'] == _role && text.contains(_q);
                  }).toList()
                    ..sort((a, b) => ((a.data()['name'] ?? '') as String)
                        .compareTo((b.data()['name'] ?? '') as String));

                  if (list.isEmpty) {
                    return const Center(child: Text('No users found.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final doc = list[i];
                      final m = doc.data();
                      final name = (m['name'] ?? '') as String;
                      final active = m['active'] != false;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: cardDeco(16),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade50,
                            child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                                style: const TextStyle(
                                    color: AppColors.orange,
                                    fontWeight: FontWeight.w700)),
                          ),
                          title: Text(name.isEmpty ? '(no name)' : name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text((m['email'] ?? '') as String),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              active
                                  ? const Pill.green('Active')
                                  : const Pill.red('Inactive'),
                              const SizedBox(height: 4),
                              const Text('Manage',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.orange,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          onTap: () => _manage(doc),
                        ),
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