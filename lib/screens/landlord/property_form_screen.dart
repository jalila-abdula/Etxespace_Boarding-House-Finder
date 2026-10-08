import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/cloudinary_service.dart';
import '../../services/property_service.dart';
import '../../services/subscription_service.dart';
import '../../widgets/map_picker.dart';
import '../../widgets/net_image.dart';

class PropertyFormScreen extends StatefulWidget {
  final Property? existing;
  const PropertyFormScreen({super.key, this.existing});
  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  static const _amenityOptions = [
    'WiFi', 'Water', 'CCTV', 'Kitchen', 'Parking', 'Laundry'
  ];

  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _desc = TextEditingController(text: widget.existing?.description);
  late final _address = TextEditingController(text: widget.existing?.address);
  late final _price = TextEditingController(
      text: widget.existing?.price.toStringAsFixed(0));
  late final _rooms =
      TextEditingController(text: widget.existing?.totalRooms.toString());
  late final _available =
      TextEditingController(text: widget.existing?.availableRooms.toString());
  late final _rules = TextEditingController(text: widget.existing?.houseRules);

  final _amenities = <String>{};
  final _urls = <String>[]; // photos already uploaded
  final _newFiles = <File>[]; // photos picked now
  LatLng? _location;
  bool _active = true;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _amenities.addAll(e.amenities);
      _urls.addAll(e.images);
      _location = LatLng(e.lat, e.lng);
      _active = e.active;
    }
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
    setState(() => _newFiles.addAll(picked.map((x) => File(x.path))));
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_urls.isEmpty && _newFiles.isEmpty) return _toast('Add at least one photo');
    if (_location == null) return _toast('Tap the map to pin the location');

    final rooms = int.parse(_rooms.text);
    final available = _isEdit ? int.parse(_available.text) : rooms;
    if (available > rooms) {
      return _toast('Available rooms cannot be more than total rooms');
    }

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final plan = (await SubscriptionService().currentOnce(uid)).plan;
      final others = (await PropertyService().ownerPropertiesOnce(uid))
          .where((p) => p.id != widget.existing?.id)
          .toList();
      final usedRooms = others.fold<int>(0, (t, p) => t + p.totalRooms);

      if (!_isEdit && others.length >= plan.maxProperties) {
        _toast(
            'Your ${plan.name} allows ${plan.propertiesText} property(ies). Upgrade your plan to add more.');
        return;
      }
      if (usedRooms + rooms > plan.maxRooms) {
        _toast(
            'Your ${plan.name} allows ${plan.maxRooms} rooms in total ($usedRooms already used). Upgrade your plan.');
        return;
      }

      final newUrls = await CloudinaryService().uploadImages(_newFiles);
      final images = [..._urls, ...newUrls];

      if (_isEdit) {
        await PropertyService().updateProperty(widget.existing!.id, {
          'name': _name.text.trim(),
          'description': _desc.text.trim(),
          'address': _address.text.trim(),
          'lat': _location!.latitude,
          'lng': _location!.longitude,
          'price': double.parse(_price.text),
          'totalRooms': rooms,
          'availableRooms': available,
          'amenities': _amenities.toList(),
          'images': images,
          'houseRules': _rules.text.trim(),
          'active': _active,
          'featured': plan.featured,
        });
      } else {
        await PropertyService().addProperty(Property(
          ownerId: uid,
          name: _name.text.trim(),
          description: _desc.text.trim(),
          address: _address.text.trim(),
          lat: _location!.latitude,
          lng: _location!.longitude,
          price: double.parse(_price.text),
          totalRooms: rooms,
          availableRooms: available,
          amenities: _amenities.toList(),
          images: images,
          houseRules: _rules.text.trim(),
          featured: plan.featured,
        ));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _toast('Failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this property?'),
        content: const Text('This removes the listing for good.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    await PropertyService().deleteProperty(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  Widget _thumb(Widget img, VoidCallback onRemove) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Stack(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: img),
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: onRemove,
                child: const CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 12, color: Colors.white)),
              ),
            ),
          ],
        ),
      );

  @override
  void dispose() {
    for (final c in [_name, _desc, _address, _price, _rooms, _available, _rules]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Property' : 'Add Property')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
                controller: _name,
                decoration:
                    const InputDecoration(labelText: 'Boarding house name'),
                validator: _required),
            const SizedBox(height: 12),
            TextFormField(
                controller: _desc,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: _required),
            const SizedBox(height: 12),
            TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: _required),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price (₱/mo)'),
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? 'Invalid' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _rooms,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Total rooms'),
                  validator: (v) =>
                      (int.tryParse(v ?? '') ?? 0) < 1 ? 'Invalid' : null,
                ),
              ),
            ]),
            if (_isEdit) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _available,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Available rooms'),
                validator: (v) =>
                    int.tryParse(v ?? '') == null ? 'Invalid' : null,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
                controller: _rules,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'House rules')),
            const SizedBox(height: 16),
            const Text('Amenities',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _amenityOptions
                  .map((a) => FilterChip(
                        label: Text(a),
                        selected: _amenities.contains(a),
                        onSelected: (s) => setState(() =>
                            s ? _amenities.add(a) : _amenities.remove(a)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text('Photos', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 90,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_photo_alternate),
                    ),
                  ),
                  ..._urls.map((u) => _thumb(
                      NetImage(url: u, width: 90, height: 90),
                      () => setState(() => _urls.remove(u)))),
                  ..._newFiles.map((f) => _thumb(
                      Image.file(f, width: 90, height: 90, fit: BoxFit.cover),
                      () => setState(() => _newFiles.remove(f)))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Pin the location (tap the map)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              child: MapPicker(initial: _location, onPicked: (p) => _location = p),
            ),
            if (_isEdit)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Visible to tenants'),
                subtitle: const Text('Turn off to hide this listing'),
                value: _active,
                activeThumbColor: AppColors.green,
                onChanged: (v) => setState(() => _active = v),
              ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.green),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Save Changes' : 'Save Property'),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    minimumSize: const Size.fromHeight(52)),
                onPressed: _delete,
                child: const Text('Delete Property'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}