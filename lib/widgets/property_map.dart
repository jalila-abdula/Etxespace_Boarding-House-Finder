import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants.dart';
import '../models/property.dart';

class PropertyMap extends StatelessWidget {
  final List<Property> properties;
  final ValueChanged<Property>? onTapProperty;
  const PropertyMap({super.key, required this.properties, this.onTapProperty});

  @override
  Widget build(BuildContext context) {
    final center = properties.isNotEmpty
        ? LatLng(properties.first.lat, properties.first.lng)
        : MapConfig.defaultCenter;

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 14),
      children: [
        TileLayer(
          urlTemplate: MapConfig.tileUrl,
          userAgentPackageName: MapConfig.userAgent,
        ),
        MarkerLayer(
          markers: properties
              .map((p) => Marker(
                    point: LatLng(p.lat, p.lng),
                    width: 48,
                    height: 48,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => onTapProperty?.call(p),
                      child: const Icon(Icons.location_on,
                          color: AppColors.green, size: 48),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}