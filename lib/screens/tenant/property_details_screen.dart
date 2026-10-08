import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_exception.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../models/review.dart';
import '../../services/chat_service.dart';
import '../../services/property_service.dart';
import '../../services/reservation_service.dart';
import '../../services/review_service.dart';
import '../../widgets/net_image.dart';
import '../../widgets/property_widgets.dart';
import '../../widgets/report_sheet.dart';
import 'chat_screen.dart';
import 'reservation_sheet.dart';

/// Counts one view each time a tenant opens a listing.
class PropertyDetailsScreen extends StatefulWidget {
  final String propertyId;
  const PropertyDetailsScreen({super.key, required this.propertyId});
  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  @override
  void initState() {
    super.initState();
    PropertyService().addView(widget.propertyId);
  }

  @override
  Widget build(BuildContext context) =>
      _PropertyDetailsBody(propertyId: widget.propertyId);
}

class _PropertyDetailsBody extends StatelessWidget {
  final String propertyId;
  const _PropertyDetailsBody({required this.propertyId});

  Future<void> _message(BuildContext context, Property p) async {
    final room = await ChatService().openChat(
      propertyId: p.id,
      ownerId: p.ownerId,
      propertyName: p.name,
      propertyImage: p.images.isNotEmpty ? p.images.first : '',
    );
    if (!context.mounted) return;
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => ChatScreen(room: room)));
  }

  Future<void> _reserve(BuildContext context, Property p) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ReservationSheet(property: p),
    );
    if (sent == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Reservation request sent. Check the Reservations tab for updates.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.data!.exists) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(
                  child: Text('This listing is no longer available.')));
        }
        final p = Property.fromDoc(snap.data!);
        final full = p.availableRooms == 0;

        return Scaffold(
          backgroundColor: Colors.white,
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Gallery(p: p),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(p.address,
                              style: TextStyle(color: Colors.grey.shade700))),
                    ]),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text.rich(TextSpan(children: [
                          TextSpan(
                              text: peso(p.price),
                              style: const TextStyle(
                                  color: AppColors.greenDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22)),
                          TextSpan(
                              text: ' /month',
                              style: TextStyle(color: Colors.grey.shade600)),
                        ])),
                        RatingText(p),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      AvailabilityChip(p),
                      const SizedBox(width: 8),
                      Text('${p.totalRooms} total rooms',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ]),
                    const SizedBox(height: 20),
                    const Text('About',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(p.description,
                        style: TextStyle(
                            color: Colors.grey.shade800, height: 1.5)),
                    if (p.amenities.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('Amenities',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: p.amenities
                            .map((a) => Chip(
                                  label: Text(a),
                                  backgroundColor: Colors.green.shade50,
                                  side: BorderSide.none,
                                ))
                            .toList(),
                      ),
                    ],
                    if (p.houseRules.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('House rules',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(p.houseRules,
                          style: TextStyle(
                              color: Colors.grey.shade800, height: 1.5)),
                    ],
                    const SizedBox(height: 20),
                    const Text('Location',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(p.lat, p.lng),
                            initialZoom: 15,
                            interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: MapConfig.tileUrl,
                              userAgentPackageName: MapConfig.userAgent,
                            ),
                            MarkerLayer(markers: [
                              Marker(
                                point: LatLng(p.lat, p.lng),
                                width: 44,
                                height: 44,
                                alignment: Alignment.topCenter,
                                child: const Icon(Icons.location_on,
                                    color: Colors.red, size: 44),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _ReviewSection(p: p),
                    const SizedBox(height: 8),
                    ReportListingButton(property: p),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _message(context, p),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Message'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.green),
                      onPressed: full ? null : () => _reserve(context, p),
                      child: Text(full ? 'Fully booked' : 'Reserve a room'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Gallery extends StatefulWidget {
  final Property p;
  const _Gallery({required this.p});
  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final imgs = widget.p.images;
    final top = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imgs.isEmpty
              ? const NetImage(width: double.infinity, height: double.infinity)
              : PageView.builder(
                  itemCount: imgs.length,
                  onPageChanged: (i) => setState(() => _i = i),
                  itemBuilder: (_, i) => NetImage(
                      url: imgs[i],
                      width: double.infinity,
                      height: double.infinity),
                ),
          Positioned(
            top: top + 8,
            left: 12,
            child: Material(
              color: Colors.white.withValues(alpha: 0.9),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
              top: top + 10, right: 12, child: FavoriteButton(widget.p.id)),
          if (imgs.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  imgs.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _i ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _i
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatefulWidget {
  final Property p;
  const _ReviewSection({required this.p});
  @override
  State<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<_ReviewSection> {
  late final Future<bool> _can = ReservationService().canReview(widget.p.id);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Reviews (${widget.p.ratingCount})',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            FutureBuilder<bool>(
              future: _can,
              builder: (context, s) => s.data == true
                  ? TextButton.icon(
                      onPressed: () => showDialog(
                          context: context,
                          builder: (_) => _ReviewDialog(property: widget.p)),
                      icon: const Icon(Icons.rate_review_outlined, size: 18),
                      label: const Text('Write a review'),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        StreamBuilder<List<Review>>(
          stream: ReviewService().forProperty(widget.p.id),
          builder: (context, snap) {
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No reviews yet.',
                    style: TextStyle(color: Colors.grey.shade600)),
              );
            }
            return Column(
              children: list
                  .map((r) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(r.tenantName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Stars(r.rating, size: 14),
                              ],
                            ),
                            if (r.comment.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(r.comment),
                            ],
                            if (r.createdAt != null) ...[
                              const SizedBox(height: 6),
                              Text(DateFormat('MMM d, y').format(r.createdAt!),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600)),
                            ],
                          ],
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  final Property property;
  const _ReviewDialog({required this.property});
  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ReviewService().add(
          property: widget.property,
          rating: _rating,
          comment: _comment.text.trim());
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Review submitted')));
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not submit your review. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Write a review'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber, size: 32),
              ),
            ),
          ),
          TextField(
            controller: _comment,
            maxLines: 3,
            decoration:
                const InputDecoration(hintText: 'Share your experience'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _busy ? null : _submit,
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              minimumSize: const Size(90, 44)),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}