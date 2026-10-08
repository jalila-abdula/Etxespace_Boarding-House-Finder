import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/property.dart';
import '../services/favorite_service.dart';
import 'net_image.dart';

String peso(double v) => '₱${NumberFormat('#,##0').format(v)}';

class FavoriteButton extends StatelessWidget {
  final String propertyId;
  const FavoriteButton(this.propertyId, {super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FavoriteService().col(uid).doc(propertyId);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        final isFav = snap.data?.exists ?? false;
        return Material(
          color: Colors.white.withValues(alpha: 0.9),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => isFav
                ? ref.delete()
                : ref.set({'createdAt': FieldValue.serverTimestamp()}),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                  size: 20, color: isFav ? Colors.red : Colors.grey.shade600),
            ),
          ),
        );
      },
    );
  }
}

class Stars extends StatelessWidget {
  final int rating;
  final double size;
  const Stars(this.rating, {super.key, this.size = 16});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
            5,
            (i) => Icon(i < rating ? Icons.star : Icons.star_border,
                size: size, color: Colors.amber)),
      );
}

class RatingText extends StatelessWidget {
  final Property p;
  const RatingText(this.p, {super.key});

  @override
  Widget build(BuildContext context) {
    if (p.ratingCount == 0) {
      return Text('New',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.star, size: 16, color: Colors.amber),
      const SizedBox(width: 3),
      Text(p.rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      Text(' (${p.ratingCount})',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    ]);
  }
}

class AvailabilityChip extends StatelessWidget {
  final Property p;
  const AvailabilityChip(this.p, {super.key});

  @override
  Widget build(BuildContext context) {
    final ok = p.availableRooms > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ok ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        ok ? '${p.availableRooms} rooms available' : 'Fully booked',
        style: TextStyle(
            fontSize: 11,
            color: ok ? AppColors.greenDark : Colors.red.shade700),
      ),
    );
  }
}

class _FeaturedBadge extends StatelessWidget {
  const _FeaturedBadge();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: AppColors.green, borderRadius: BorderRadius.circular(20)),
        child: const Text('FEATURED',
            style: TextStyle(
                color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
      );
}

BoxDecoration _cardDeco() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4)),
      ],
    );

/// Big card used on the Explore tab.
class ExploreCard extends StatelessWidget {
  final Property p;
  final VoidCallback onTap;
  const ExploreCard({super.key, required this.p, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        clipBehavior: Clip.antiAlias,
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 190,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(
                      url: p.images.isNotEmpty ? p.images.first : null,
                      width: double.infinity,
                      height: double.infinity),
                  if (p.featured)
                    const Positioned(
                        top: 10, left: 10, child: _FeaturedBadge()),
                  Positioned(
                      top: 10, right: 10, child: FavoriteButton(p.id)),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Row(
                      children: p.amenities
                          .take(3)
                          .map((a) => Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(a,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10)),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(p.address,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(
                            text: peso(p.price),
                            style: const TextStyle(
                                color: AppColors.greenDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                        TextSpan(
                            text: '/mo',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12)),
                      ])),
                      RatingText(p),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    AvailabilityChip(p),
                    const SizedBox(width: 8),
                    Text('${p.totalRooms} total rooms',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal card used in Home → Featured.
class FeaturedCard extends StatelessWidget {
  final Property p;
  final VoidCallback onTap;
  const FeaturedCard({super.key, required this.p, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        clipBehavior: Clip.antiAlias,
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(
                      url: p.images.isNotEmpty ? p.images.first : null,
                      width: double.infinity,
                      height: double.infinity),
                  const Positioned(top: 8, left: 8, child: _FeaturedBadge()),
                  Positioned(top: 6, right: 6, child: FavoriteButton(p.id)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(p.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${peso(p.price)}/mo',
                          style: const TextStyle(
                              color: AppColors.greenDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                      RatingText(p),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact row used in Home → Near You and Saved Properties.
class NearYouTile extends StatelessWidget {
  final Property p;
  final double? distanceKm;
  final VoidCallback onTap;
  const NearYouTile(
      {super.key, required this.p, required this.onTap, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: _cardDeco(),
        child: Row(
          children: [
            NetImage(
                url: p.images.isNotEmpty ? p.images.first : null,
                width: 80,
                height: 80,
                radius: BorderRadius.circular(14)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(
                      distanceKm == null
                          ? p.address
                          : '${p.address} • ${distanceKm!.toStringAsFixed(1)} km',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${peso(p.price)}/mo',
                          style: const TextStyle(
                              color: AppColors.greenDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                      RatingText(p),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AvailabilityChip(p),
                ],
              ),
            ),
            FavoriteButton(p.id),
          ],
        ),
      ),
    );
  }
}