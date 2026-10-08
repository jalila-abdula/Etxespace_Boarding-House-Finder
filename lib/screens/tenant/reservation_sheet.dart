import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_exception.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/reservation_service.dart';
import '../../widgets/property_widgets.dart';

class ReservationSheet extends StatefulWidget {
  final Property property;
  const ReservationSheet({super.key, required this.property});
  @override
  State<ReservationSheet> createState() => _ReservationSheetState();
}

class _ReservationSheetState extends State<ReservationSheet> {
  static const _roomTypes = ['Single Room', 'Double Room', 'Bedspace'];
  static const _durations = [1, 3, 6, 12];

  String _room = _roomTypes.first;
  DateTime _moveIn = DateTime.now().add(const Duration(days: 7));
  int _months = 1;
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _moveIn,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _moveIn = d);
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ReservationService().create(
        property: widget.property,
        roomType: _room,
        moveIn: _moveIn,
        months: _months,
        note: _note.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not send your request. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _note.dispose();
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
            const Text('Reserve a room',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('${widget.property.name} • ${peso(widget.property.price)}/mo',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _room,
              decoration: const InputDecoration(labelText: 'Room type'),
              items: _roomTypes
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _room = v!),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Move-in date',
                    suffixIcon: Icon(Icons.calendar_today, size: 18)),
                child: Text(DateFormat('MMMM d, y').format(_moveIn)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _months,
              decoration: const InputDecoration(labelText: 'Rental period'),
              items: _durations
                  .map((m) => DropdownMenuItem(
                      value: m, child: Text(m == 1 ? '1 month' : '$m months')))
                  .toList(),
              onChanged: (v) => setState(() => _months = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Note to the landlord (optional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
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
                  : const Text('Send reservation request'),
            ),
          ],
        ),
      ),
    );
  }
}