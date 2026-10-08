import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';
import '../../widgets/admin_ui.dart';

class DataBackupScreen extends StatefulWidget {
  const DataBackupScreen({super.key});
  @override
  State<DataBackupScreen> createState() => _DataBackupScreenState();
}

class _DataBackupScreenState extends State<DataBackupScreen> {
  static const _collections = [
    'users', 'properties', 'reservations', 'subscriptions', 'reviews', 'reports'
  ];
  final _db = FirebaseFirestore.instance;

  late final Future<List<int>> _counts = Future.wait(_collections.map((c) async =>
      (await _db.collection(c).count().get()).count ?? 0));

  String _cell(Object? v) {
    if (v is Timestamp) v = v.toDate().toIso8601String();
    final s = (v ?? '').toString();
    return '"${s.replaceAll('"', '""')}"';
  }

  Future<void> _export(String collection, List<String> keys) async {
    try {
      final s = await _db.collection(collection).get();
      final lines = <String>[keys.join(',')];
      for (final d in s.docs) {
        final m = d.data();
        lines.add(keys.map((k) => _cell(m[k])).join(','));
      }
      await Clipboard.setData(ClipboardData(text: lines.join('\n')));
      if (mounted) {
        toast(context,
            'Copied ${s.docs.length} rows. Paste into a spreadsheet or notes app.');
      }
    } catch (e) {
      if (mounted) toast(context, 'Export failed: $e');
    }
  }

  Widget _exportBtn(String label, String collection, List<String> keys) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              alignment: Alignment.centerLeft),
          onPressed: () => _export(collection, keys),
          icon: const Icon(Icons.copy_all_outlined, size: 18),
          label: Text(label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Data & Backup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('System summary',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          FutureBuilder<List<int>>(
            future: _counts,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()));
              }
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: cardDeco(),
                child: Column(
                  children: List.generate(_collections.length, (i) {
                    final name = _collections[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(name[0].toUpperCase() + name.substring(1)),
                          Text('${snap.data![i]}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    );
                  }),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text('Export (copies CSV to the clipboard)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _exportBtn('Users', 'users',
              ['name', 'email', 'role', 'active', 'createdAt']),
          _exportBtn('Properties', 'properties', [
            'name', 'address', 'ownerId', 'price', 'totalRooms',
            'availableRooms', 'active', 'featured', 'views'
          ]),
          _exportBtn('Reservations', 'reservations', [
            'tenantName', 'propertyName', 'roomType', 'price', 'moveInDate',
            'months', 'status', 'createdAt'
          ]),
          _exportBtn('Subscriptions', 'subscriptions', [
            'landlordName', 'planName', 'price', 'status', 'createdAt',
            'expiresAt'
          ]),
          const SizedBox(height: 12),
          Text(
              'For a full database backup, use Firebase Console → Firestore → Import/Export (requires the Blaze plan).',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}