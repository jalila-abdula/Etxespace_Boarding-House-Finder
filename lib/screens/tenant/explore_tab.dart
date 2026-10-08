import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/property_service.dart';
import '../../widgets/property_map.dart';
import '../../widgets/property_widgets.dart';
import 'property_details_screen.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});
  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  static const _amenityOptions = [
    'WiFi', 'Water', 'CCTV', 'Kitchen', 'Parking', 'Laundry'
  ];
  static const _sorts = [
    'Default',
    'Price: low to high',
    'Price: high to low',
    'Top rated',
  ];

  final _search = TextEditingController();
  String _q = '';
  bool _showMap = false;
  double _maxPrice = 20000;
  final Set<String> _amenities = {};
  bool _onlyAvailable = false;
  String _sort = 'Default';
  Property? _selected;

  int get _activeFilters =>
      (_maxPrice < 20000 ? 1 : 0) +
      _amenities.length +
      (_onlyAvailable ? 1 : 0) +
      (_sort != 'Default' ? 1 : 0);

  List<Property> _apply(List<Property> all) {
    final q = _q.toLowerCase();
    final list = all.where((p) {
      final matchQ = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.address.toLowerCase().contains(q);
      return matchQ &&
          p.price <= _maxPrice &&
          _amenities.every(p.amenities.contains) &&
          (!_onlyAvailable || p.availableRooms > 0);
    }).toList();

    switch (_sort) {
      case 'Price: low to high':
        list.sort((a, b) => a.price.compareTo(b.price));
      case 'Price: high to low':
        list.sort((a, b) => b.price.compareTo(a.price));
      case 'Top rated':
        list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  void _open(Property p) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => PropertyDetailsScreen(propertyId: p.id)));

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          void change(VoidCallback f) {
            setState(f);
            setSheet(() {});
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filter',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      TextButton(
                        onPressed: () => change(() {
                          _maxPrice = 20000;
                          _amenities.clear();
                          _onlyAvailable = false;
                          _sort = 'Default';
                        }),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Max price: ${peso(_maxPrice)}/mo'),
                  Slider(
                    value: _maxPrice,
                    min: 500,
                    max: 20000,
                    divisions: 39,
                    activeColor: AppColors.green,
                    onChanged: (v) => change(() => _maxPrice = v),
                  ),
                  const Text('Amenities'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _amenityOptions
                        .map((a) => FilterChip(
                              label: Text(a),
                              selected: _amenities.contains(a),
                              onSelected: (s) => change(() => s
                                  ? _amenities.add(a)
                                  : _amenities.remove(a)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('Sort by'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _sorts
                        .map((s) => ChoiceChip(
                              label: Text(s),
                              selected: _sort == s,
                              onSelected: (_) => change(() => _sort = s),
                            ))
                        .toList(),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Only show available rooms'),
                    value: _onlyAvailable,
                    activeThumbColor: AppColors.green,
                    onChanged: (v) => change(() => _onlyAvailable = v),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Show results'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ]Explore" on the left, Map/List toggle on the right
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Explore',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 38)),
                    onPressed: () => setState(() {
                      _showMap = !_showMap;
                      _selected = null;
                    }),
                    icon: Icon(_showMap ? Icons.list : Icons.map_outlined,
                        size: 18),
                    label: Text(_showMap ? 'List' : 'Map'),
                  ),
                ],
              ),
            ),
            // Search bar + Filter button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _q = v),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search location, property...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _q.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _search.clear();
                                  setState(() => _q = '');
                                },
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Badge(
                    isLabelVisible: _activeFilters > 0,
                    label: Text('$_activeFilters'),
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 50)),
                      onPressed: _openFilter,
                      icon: const Icon(Icons.filter_alt_outlined, size: 18),
                      label: const Text('Filter'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Property>>(
                stream: PropertyService().activeProperties(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = _apply(snap.data!);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 8),
                        child: Text(
                            '${list.length} ${list.length == 1 ? 'property' : 'properties'} found',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ),
                      Expanded(
                        child: list.isEmpty
                            ? const Center(
                                child: Text('No boarding houses match.'))
                            : _showMap
                                ? Stack(
                                    children: [
                                      PropertyMap(
                                        properties: list,
                                        onTapProperty: (p) =>
                                            setState(() => _selected = p),
                                      ),
                                      if (_selected != null)
                                        Positioned(
                                          left: 16,
                                          right: 16,
                                          bottom: 8,
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              NearYouTile(
                                                p: _selected!,
                                                onTap: () =>
                                                    _open(_selected!),
                                              ),
                                              Positioned(
                                                top: -6,
                                                right: -6,
                                                child: CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor:
                                                      Colors.white,
                                                  child: IconButton(
                                                    padding: EdgeInsets.zero,
                                                    iconSize: 16,
                                                    icon: const Icon(
                                                        Icons.close),
                                                    onPressed: () => setState(
                                                        () =>
                                                            _selected = null),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 16),
                                    itemCount: list.length,
                                    itemBuilder: (_, i) => ExploreCard(
                                        p: list[i],
                                        onTap: () => _open(list[i])),
                                  ),
                      ),
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