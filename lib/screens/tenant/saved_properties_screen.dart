import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/favorite_service.dart';
import '../../services/property_service.dart';
import '../../widgets/property_widgets.dart';
import 'property_details_screen.dart';

class SavedPropertiesScreen extends StatelessWidget {
  const SavedPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Saved Properties')),
      body: StreamBuilder<Set<String>>(
        stream: FavoriteService().ids(uid),
        builder: (context, favSnap) {
          if (!favSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<List<Property>>(
            stream: PropertyService().activeProperties(),
            builder: (context, snap) {
              final list = (snap.data ?? [])
                  .where((p) => favSnap.data!.contains(p.id))
                  .toList();
              if (list.isEmpty) {
                return const Center(
                    child: Text('No saved properties yet.\nTap the heart on a listing.',
                        textAlign: TextAlign.center));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => NearYouTile(
                  p: list[i],
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              PropertyDetailsScreen(propertyId: list[i].id))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}