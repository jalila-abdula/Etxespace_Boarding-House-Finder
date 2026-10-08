import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/admin_service.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/multi_snap.dart';
import '../../widgets/net_image.dart';
import '../../widgets/property_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _filters = {
    'pending': 'Pending',
    'resolved': 'Resolved',
    'dismissed': 'Dismissed',
    'all': 'All',
  };

  final _admin = AdminService();
  late final _reports = _admin.reports();
  String _filter = 'pending';

  Future<void> _run(Future<void> Function() action, String ok) async {
    try {
      await action();
      if (mounted) toast(context, ok);
    } catch (e) {
      if (mounted) toast(context, 'Failed: $e');
    }
  }

  Widget _statusPill(String s) {
    if (s == 'pending') return const Pill.orange('Pending');
    if (s == 'resolved') return const Pill.green('Resolved');
    return const Pill.grey('Dismissed');
  }

  void _viewListing(String propertyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('properties')
            .doc(propertyId)
            .get(),
        builder: (context, s) {
          if (!s.hasData) {
            return const SizedBox(
                height: 220, child: Center(child: CircularProgressIndicator()));
          }
          if (!s.data!.exists) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Text('This listing no longer exists.',
                  textAlign: TextAlign.center),
            );
          }
          final p = Property.fromDoc(s.data!);
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              children: [
                if (p.images.isNotEmpty)
                  SizedBox(
                    height: 170,
                    child: PageView(
                      children: p.images
                          .map((u) => NetImage(
                              url: u,
                              width: double.infinity,
                              height: 170,
                              radius: BorderRadius.circular(16)))
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(p.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    p.active ? const Pill.green('Visible') : const Pill.grey('Hidden'),
                  ],
                ),
                Text(p.address, style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 6),
                Text('${peso(p.price)}/month · ${p.totalRooms} rooms · ${p.availableRooms} available'),
                const SizedBox(height: 8),
                Text(p.description),
                if (p.houseRules.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('House rules',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  Text(p.houseRules),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Reported Listings')),
      body: MultiSnap(
        streams: [_reports],
        builder: (context, d) {
          final all = d[0].docs.toList()..sort(AdminService.newest);
          int count(String s) =>
              all.where((x) => x.data()['status'] == s).length;
          final docs = _filter == 'all'
              ? all
              : all.where((x) => x.data()['status'] == _filter).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    _Count('${count('pending')}', 'Pending', Colors.orange),
                    const SizedBox(width: 10),
                    _Count('${count('resolved')}', 'Resolved', Colors.green),
                    const SizedBox(width: 10),
                    _Count('${count('dismissed')}', 'Dismissed', Colors.blueGrey),
                  ],
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _filters.entries
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(e.value),
                              selected: _filter == e.key,
                              selectedColor: AppColors.orange,
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                  color: _filter == e.key
                                      ? Colors.white
                                      : Colors.black87),
                              onSelected: (_) =>
                                  setState(() => _filter = e.key),
                            ),
                          ))
                      .toList(),
                ),
              ),
              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text('No reports here.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final doc = docs[i];
                          final r = doc.data();
                          final status = (r['status'] ?? 'pending') as String;
                          final date = AdminService.created(r);
                          final reviewed =
                              (r['reviewedAt'] as Timestamp?)?.toDate();
                          final propertyId = (r['propertyId'] ?? '') as String;
                          final others = all
                                  .where((x) =>
                                      x.data()['propertyId'] == propertyId)
                                  .length -
                              1;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: cardDeco(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.flag,
                                        color: Colors.red, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                          (r['propertyName'] ?? 'Listing')
                                              as String,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700)),
                                    ),
                                    _statusPill(status),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Reason: ${r['reason'] ?? '-'}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                if (((r['details'] ?? '') as String)
                                    .isNotEmpty)
                                  Text(r['details'] as String),
                                const SizedBox(height: 4),
                                Text(
                                    'Reported by ${r['reporterName'] ?? '-'}${date == null ? '' : ' · ${DateFormat('MMM d, y').format(date)}'}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600)),
                                if (others > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                        '$others other report${others == 1 ? '' : 's'} on this listing',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                if (status != 'pending' && reviewed != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                        'Reviewed ${DateFormat('MMM d, y').format(reviewed)}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600)),
                                  ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 32)),
                                  onPressed: () => _viewListing(propertyId),
                                  icon: const Icon(Icons.visibility_outlined,
                                      size: 18),
                                  label: const Text('View listing'),
                                ),
                                if (status == 'pending') ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.orange,
                                              minimumSize:
                                                  const Size.fromHeight(40)),
                                          onPressed: () async {
                                            final ok = await confirmDialog(
                                                context,
                                                'Hide this listing?',
                                                'It disappears for tenants. The owner and the reporter are notified.');
                                            if (ok) {
                                              await _run(
                                                  () => _admin
                                                      .hideReportedListing(
                                                    reportId: doc.id,
                                                    propertyId: propertyId,
                                                    ownerId:
                                                        (r['ownerId'] ?? '')
                                                            as String,
                                                    propertyName:
                                                        (r['propertyName'] ??
                                                            '') as String,
                                                    reporterId:
                                                        (r['reporterId'] ??
                                                            '') as String,
                                                  ),
                                                  'Listing hidden');
                                            }
                                          },
                                          child: const Text('Hide listing'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                              minimumSize:
                                                  const Size.fromHeight(40)),
                                          onPressed: () => _run(
                                              () => _admin.dismissReport(
                                                    doc.id,
                                                    reporterId:
                                                        (r['reporterId'] ??
                                                            '') as String,
                                                    propertyName:
                                                        (r['propertyName'] ??
                                                            '') as String,
                                                  ),
                                              'Report dismissed'),
                                          child: const Text('Dismiss'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final String value;
  final String label;
  final MaterialColor color;
  const _Count(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: color.shade50, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color.shade700)),
              Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
            ],
          ),
        ),
      );
}