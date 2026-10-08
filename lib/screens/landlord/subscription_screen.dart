import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/app_exception.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../models/subscription.dart';
import '../../services/cloudinary_service.dart';
import '../../services/property_service.dart';
import '../../services/subscription_service.dart';
import '../../widgets/property_widgets.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  String? _selectedId;
  late final _plans = SubscriptionService().plans();
  late final _current = SubscriptionService().current(_uid);
  late final _props = PropertyService().ownerProperties(_uid);

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _upgrade(Plan selected, Plan current) async {
    if (selected.id == current.id) return _toast('You are already on this plan.');
    if (selected.isFree) {
      return _toast('The Free plan applies automatically when a paid plan ends.');
    }
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PaymentSheet(plan: selected),
    );
    if (sent == true) {
      _toast('Payment submitted. Waiting for admin approval.');
    }
  }

  Widget _usage(String label, int used, int limit, String limitText) {
    final v = limit >= Plan.unlimited || limit == 0
        ? 0.0
        : (used / limit).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$label: $used/$limitText',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              if (limit < Plan.unlimited && limit > 0)
                Text('${(v * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 6,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feat(bool ok, String text) => Text('${ok ? '✓' : '✗'} $text',
      style: TextStyle(
          fontSize: 12,
          color: ok ? AppColors.greenDark : Colors.grey.shade400));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Subscription')),
      body: StreamBuilder<ActivePlan>(
        stream: _current,
        builder: (context, cs) => StreamBuilder<List<Plan>>(
          stream: _plans,
          builder: (context, ps) => StreamBuilder<List<Property>>(
            stream: _props,
            builder: (context, pr) {
              if (!cs.hasData || !ps.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final active = cs.data!;
              final cur = active.plan;
              final props = pr.data ?? [];
              final rooms = props.fold<int>(0, (t, p) => t + p.totalRooms);
              final selectedId = _selectedId ?? cur.id;
              final selected = ps.data!.firstWhere((p) => p.id == selectedId,
                  orElse: () => ps.data!.first);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Plan',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12)),
                        Text(cur.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        Text(
                            cur.isFree
                                ? 'Free · No expiry'
                                : '${peso(cur.price)}/month · Expires ${DateFormat('MMM d, y').format(active.expiresAt!)}',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12)),
                        _usage('Properties', props.length, cur.maxProperties,
                            cur.propertiesText),
                        _usage('Rooms', rooms, cur.maxRooms, '${cur.maxRooms}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Available Plans',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ...ps.data!.map((p) {
                    final sel = p.id == selectedId;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedId = p.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: sel ? Colors.green.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: sel ? AppColors.green : Colors.grey.shade200,
                              width: sel ? 1.5 : 1),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                  Text(
                                      p.isFree
                                          ? 'FREE'
                                          : '${peso(p.price)}/month',
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.greenDark)),
                                  const SizedBox(height: 6),
                                  Text('${p.propertiesText} Properties',
                                      style: const TextStyle(fontSize: 12)),
                                  Text('${p.maxRooms} Rooms max',
                                      style: const TextStyle(fontSize: 12)),
                                  _feat(p.featured,
                                      p.featured ? 'Featured Listing' : 'No Featured Listing'),
                                  _feat(p.analytics,
                                      p.analytics ? 'Analytics Access' : 'No Analytics'),
                                ],
                              ),
                            ),
                            Icon(
                                sel
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: sel ? AppColors.green : Colors.grey),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.greenDark),
                    onPressed: () => _upgrade(selected, cur),
                    child: const Text('Upgrade Plan'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PaymentHistoryScreen())),
                    child: const Text('View Payment History'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PaymentSheet extends StatefulWidget {
  final Plan plan;
  const _PaymentSheet({required this.plan});
  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  File? _proof;
  bool _busy = false;
  String? _error;

  Future<void> _pick() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) setState(() => _proof = File(x.path));
  }

  Future<void> _submit() async {
    if (_proof == null) {
      setState(() => _error = 'Upload your payment screenshot first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final url = await CloudinaryService()
          .uploadImage(_proof!, folder: 'etxespace/payments');
      await SubscriptionService().request(plan: widget.plan, proofUrl: url);
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not submit. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pay for ${widget.plan.name}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('${peso(widget.plan.price)} for 30 days',
                style: const TextStyle(
                    color: AppColors.greenDark, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(PaymentConfig.instructions),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _pick,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _proof == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, size: 32),
                          SizedBox(height: 6),
                          Text('Tap to upload payment proof'),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_proof!, fit: BoxFit.cover)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.green),
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Submit payment'),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Payment History')),
      body: StreamBuilder<List<SubscriptionRequest>>(
        stream: SubscriptionService().history(uid),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(child: Text('No payments yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final s = list[i];
              final (bg, fg) = switch (s.status) {
                'active' => (Colors.green.shade50, AppColors.greenDark),
                'rejected' => (Colors.red.shade50, Colors.red.shade700),
                _ => (Colors.orange.shade50, Colors.orange.shade800),
              };
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.planName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                            '${peso(s.price)} · ${s.createdAt == null ? '' : DateFormat('MMM d, y').format(s.createdAt!)}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: bg, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                          s.status[0].toUpperCase() + s.status.substring(1),
                          style: TextStyle(fontSize: 11, color: fg)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}