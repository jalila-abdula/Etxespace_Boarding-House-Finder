import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_exception.dart';
import '../../core/constants.dart';
import '../../models/subscription.dart';
import '../../services/admin_service.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/multi_snap.dart';
import '../../widgets/property_widgets.dart';

class AdminSubscriptionsTab extends StatefulWidget {
  const AdminSubscriptionsTab({super.key});
  @override
  State<AdminSubscriptionsTab> createState() => _AdminSubscriptionsTabState();
}

class _AdminSubscriptionsTabState extends State<AdminSubscriptionsTab> {
  final _admin = AdminService();
  late final _streams = <Stream<Snap>>[_admin.plans(), _admin.subscriptions()];
  int _tab = 0;

  Future<void> _run(Future<void> Function() action, String ok) async {
    try {
      await action();
      if (mounted) toast(context, ok);
    } on AppException catch (e) {
      if (mounted) toast(context, e.message);
    } catch (e) {
      if (mounted) toast(context, 'Failed: $e');
    }
  }

  void _planSheet([Doc? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PlanSheet(existing: existing),
    );
  }

  void _proof(String url, String who) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Payment proof · $who',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(url,
                    errorBuilder: (_, _, _) => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Could not load the image.'))),
              ),
            ),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  Widget _plansList(Snap plans) {
    if (plans.docs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('No plans in the database yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
              'Landlords currently see the built-in Free, Standard and Premium plans. Create them here to manage them.',
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
            onPressed: () =>
                _run(_admin.seedDefaultPlans, 'Default plans created'),
            child: const Text('Create default plans'),
          ),
        ],
      );
    }

    final docs = plans.docs.toList()
      ..sort((a, b) => ((a.data()['price'] ?? 0) as num)
          .compareTo((b.data()['price'] ?? 0) as num));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (_, i) {
        final doc = docs[i];
        final d = doc.data();
        final price = ((d['price'] ?? 0) as num).toDouble();
        final maxProps = ((d['maxProperties'] ?? Plan.unlimited) as num).toInt();
        final active = d['active'] != false;

        Widget bullet(String t, [Color? c]) => Text('• $t',
            style: TextStyle(
                fontSize: 12, color: c ?? Colors.grey.shade700, height: 1.5));

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: cardDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((d['name'] ?? 'PLAN') as String,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w800)),
                        Text(price == 0 ? 'FREE' : '${peso(price)}/month',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.greenDark)),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => _planSheet(doc),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                        foregroundColor: Colors.red.shade700),
                    onPressed: () async {
                      final ok = await confirmDialog(
                          context,
                          'Delete this plan?',
                          'Landlords already subscribed keep their plan until it expires.',
                          yes: 'Delete',
                          danger: true);
                      if (ok) {
                        await _run(() => _admin.deletePlan(doc.id), 'Plan deleted');
                      }
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              bullet(
                  '${maxProps >= Plan.unlimited ? 'Unlimited' : maxProps} properties · ${d['maxRooms'] ?? 0} rooms max'),
              if (d['featured'] == true)
                bullet('Featured listing included', AppColors.greenDark),
              if (d['analytics'] == true)
                bullet('Analytics access', AppColors.greenDark),
              if (d['priority'] == true)
                bullet('Priority visibility', AppColors.greenDark),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  active ? const Pill.green('Active') : const Pill.grey('Inactive'),
                  Switch(
                    value: active,
                    activeThumbColor: AppColors.green,
                    onChanged: (v) => _run(
                        () => _admin.setPlanActive(doc.id, v),
                        v ? 'Plan activated' : 'Plan deactivated'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _requestsList(Snap subs) {
    final docs = subs.docs.toList()
      ..sort((a, b) {
        final pa = a.data()['status'] == 'pending' ? 0 : 1;
        final pb = b.data()['status'] == 'pending' ? 0 : 1;
        return pa != pb ? pa.compareTo(pb) : AdminService.newest(a, b);
      });
    if (docs.isEmpty) {
      return const Center(child: Text('No payment requests.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (_, i) {
        final doc = docs[i];
        final d = doc.data();
        final status = (d['status'] ?? 'pending') as String;
        final date = AdminService.created(d);
        final who = (d['landlordName'] ?? 'Landlord') as String;
        final price = ((d['price'] ?? 0) as num).toDouble();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: cardDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(who,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      Text((d['planName'] ?? '') as String,
                          style: TextStyle(color: Colors.grey.shade700)),
                      Text(
                          date == null ? '' : DateFormat('MMM d, y').format(date),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                  Text(peso(price),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.greenDark)),
                ],
              ),
              const SizedBox(height: 12),
              if (status == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.greenDark,
                            minimumSize: const Size.fromHeight(40)),
                        onPressed: () async {
                          final ok = await confirmDialog(
                              context,
                              'Approve this payment?',
                              '$who gets ${d['planName']} for 30 days.');
                          if (ok) {
                            await _run(() => _admin.approvePayment(doc.id),
                                'Payment approved');
                          }
                        },
                        child: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red.shade700,
                            minimumSize: const Size.fromHeight(40)),
                        onPressed: () async {
                          final ok = await confirmDialog(
                              context,
                              'Reject this payment?',
                              '$who will be notified.',
                              yes: 'Reject',
                              danger: true);
                          if (ok) {
                            await _run(() => _admin.rejectPayment(doc.id),
                                'Payment rejected');
                          }
                        },
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40)),
                        onPressed: () => _proof((d['proofUrl'] ?? '') as String, who),
                        child: const Text('View Proof'),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    status == 'active'
                        ? const Pill.green('Approved')
                        : const Pill.red('Rejected'),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _proof((d['proofUrl'] ?? '') as String, who),
                      child: const Text('View Proof'),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            AdminHeader(
              'Subscriptions',
              trailing: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    minimumSize: const Size(0, 38)),
                onPressed: () => _planSheet(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Plan'),
              ),
            ),
            Expanded(
              child: MultiSnap(
                streams: _streams,
                builder: (context, d) {
                  final pending = AdminService.pending(d[1]);
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Plans'),
                              selected: _tab == 0,
                              selectedColor: AppColors.orange,
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                  color: _tab == 0 ? Colors.white : Colors.black87),
                              onSelected: (_) => setState(() => _tab = 0),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Payment Requests',
                                      style: TextStyle(
                                          color: _tab == 1
                                              ? Colors.white
                                              : Colors.black87)),
                                  if (pending > 0) ...[
                                    const SizedBox(width: 6),
                                    CircleAvatar(
                                      radius: 9,
                                      backgroundColor: Colors.red,
                                      child: Text('$pending',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white)),
                                    ),
                                  ],
                                ],
                              ),
                              selected: _tab == 1,
                              selectedColor: AppColors.orange,
                              showCheckmark: false,
                              onSelected: (_) => setState(() => _tab = 1),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                          child: _tab == 0
                              ? _plansList(d[0])
                              : _requestsList(d[1])),
                    ],
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

class _PlanSheet extends StatefulWidget {
  final Doc? existing;
  const _PlanSheet({this.existing});
  @override
  State<_PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<_PlanSheet> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _props = TextEditingController();
  final _rooms = TextEditingController();
  bool _featured = false;
  bool _analytics = false;
  bool _priority = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = widget.existing?.data();
    if (d != null) {
      _name.text = (d['name'] ?? '') as String;
      _price.text = ((d['price'] ?? 0) as num).toStringAsFixed(0);
      final mp = ((d['maxProperties'] ?? Plan.unlimited) as num).toInt();
      _props.text = mp >= Plan.unlimited ? 'Unlimited' : '$mp';
      _rooms.text = '${d['maxRooms'] ?? ''}';
      _featured = d['featured'] == true;
      _analytics = d['analytics'] == true;
      _priority = d['priority'] == true;
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final price = double.tryParse(_price.text.trim());
    final rooms = int.tryParse(_rooms.text.trim());
    final propsText = _props.text.trim().toLowerCase();
    final props = (propsText.isEmpty || propsText == 'unlimited')
        ? Plan.unlimited
        : int.tryParse(propsText);

    if (name.isEmpty) return setState(() => _error = 'Enter a plan name.');
    if (price == null || price < 0) return setState(() => _error = 'Enter a valid price.');
    if (props == null || props < 1) {
      return setState(() => _error = 'Max properties: a number or "Unlimited".');
    }
    if (rooms == null || rooms < 1) return setState(() => _error = 'Enter max rooms.');

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AdminService().savePlan(
        id: widget.existing?.id,
        name: name,
        price: price,
        maxProperties: props,
        maxRooms: rooms,
        featured: _featured,
        analytics: _analytics,
        priority: _priority,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _price, _props, _rooms]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _check(String label, bool v, ValueChanged<bool> on) => Expanded(
        child: InkWell(
          onTap: () => on(!v),
          child: Row(
            children: [
              Checkbox(
                  value: v,
                  activeColor: AppColors.orange,
                  onChanged: (x) => on(x ?? false)),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final edit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(edit ? 'Edit Plan' : 'Add New Plan',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Plan Name', hintText: 'PREMIUM PLAN')),
            const SizedBox(height: 12),
            TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Price (₱/month)', hintText: '999')),
            const SizedBox(height: 12),
            TextField(
                controller: _props,
                decoration: const InputDecoration(
                    labelText: 'Max Properties', hintText: 'Unlimited')),
            const SizedBox(height: 12),
            TextField(
                controller: _rooms,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Max Rooms', hintText: '30')),
            const SizedBox(height: 8),
            Row(
              children: [
                _check('Featured Listing', _featured,
                    (v) => setState(() => _featured = v)),
                _check('Analytics', _analytics,
                    (v) => setState(() => _analytics = v)),
                _check('Priority Visibility', _priority,
                    (v) => setState(() => _priority = v)),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
              onPressed: _busy ? null : _save,
              child: Text(edit ? 'Save Plan' : 'Create Plan'),
            ),
          ],
        ),
      ),
    );
  }
}