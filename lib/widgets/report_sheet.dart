import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/property.dart';

class ReportListingButton extends StatelessWidget {
  final Property property;
  const ReportListingButton({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
        onPressed: () async {
          final sent = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            builder: (_) => _ReportSheet(property: property),
          );
          if (sent == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Report sent. Thank you for helping us.')));
          }
        },
        icon: const Icon(Icons.flag_outlined, size: 18),
        label: const Text('Report this listing'),
      ),
    );
  }
}

class _ReportSheet extends StatefulWidget {
  final Property property;
  const _ReportSheet({required this.property});
  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static const _reasons = [
    'Misleading information',
    'Inappropriate content',
    'Outdated listing',
    'Suspicious or scam',
    'Other',
  ];
  String _reason = _reasons.first;
  final _details = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // One report per tenant per listing: a second write is refused by the rules.
      await FirebaseFirestore.instance
          .collection('reports')
          .doc('${widget.property.id}_${user.uid}')
          .set({
        'propertyId': widget.property.id,
        'propertyName': widget.property.name,
        'ownerId': widget.property.ownerId,
        'reporterId': user.uid,
        'reporterName': user.displayName ?? user.email ?? 'Tenant',
        'reason': _reason,
        'details': _details.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      setState(() => _error = e.code == 'permission-denied'
          ? 'You already reported this listing.'
          : 'Could not send the report. Try again.');
    } catch (_) {
      setState(() => _error = 'Could not send the report. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report this listing',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(widget.property.name,
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reasons
                  .map((r) => ChoiceChip(
                        label: Text(r),
                        selected: _reason == r,
                        onSelected: (_) => setState(() => _reason = r),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _details,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: 'Details (optional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.green),
              onPressed: _busy ? null : _submit,
              child: const Text('Send report'),
            ),
          ],
        ),
      ),
    );
  }
}