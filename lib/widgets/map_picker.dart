import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants.dart';

class MapPicker extends StatefulWidget {
  final LatLng? initial;
  final ValueChanged<LatLng> onPicked;
  const MapPicker({super.key, this.initial, required this.onPicked});

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  final _controller = MapController();
  LatLng? _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  Future<void> _useMyLocation() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')));
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    final point = LatLng(pos.latitude, pos.longitude);
    setState(() => _picked = point);
    _controller.move(point, 16);
    widget.onPicked(point);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _picked ?? MapConfig.defaultCenter,
              initialZoom: 15,
              onTap: (_, point) {
                setState(() => _picked = point);
                widget.onPicked(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: MapConfig.tileUrl,
                userAgentPackageName: MapConfig.userAgent,
              ),
              if (_picked != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _picked!,
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
        Positioned(
          right: 8,
          bottom: 8,
          child: FloatingActionButton.small(
            heroTag: 'myloc',
            onPressed: _useMyLocation,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}