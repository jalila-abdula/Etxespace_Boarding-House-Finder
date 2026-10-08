import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/report_data.dart';
import '../models/reservation.dart';

typedef Rec = Map<String, dynamic>;

class ReportService {
  final _db = FirebaseFirestore.instance;
  static final _date = DateFormat('MMM d, y');
  static final _month = DateFormat('MMM y');
  static final _money = NumberFormat('#,##0');

  // ---------- helpers ----------
  Future<List<Rec>> _all(String c) async {
    final s = await _db.collection(c).get();
    return s.docs
        .map((d) => <String, dynamic>{...d.data(), '_id': d.id})
        .toList();
  }

  DateTime? _dt(Object? v) => v is Timestamp ? v.toDate() : null;
  int _n(Object? v) => v is num ? v.toInt() : 0;
  double _d(Object? v) => v is num ? v.toDouble() : 0.0;
  String _s(Object? v) => (v ?? '').toString();
  String _peso(double v) => '₱${_money.format(v)}';
  String _fmt(DateTime? d) => d == null ? '-' : _date.format(d);
  String _cut(String s, int n) => s.length <= n ? s : '${s.substring(0, n)}...';
  String _label(String s) =>
      s.isEmpty ? '-' : s[0].toUpperCase() + s.substring(1);
  String _name(Rec u) =>
      _s(u['name']).isEmpty ? _s(u['email']) : _s(u['name']);

  int _newest(Rec a, Rec b) => (_dt(b['createdAt']) ?? DateTime(2000))
      .compareTo(_dt(a['createdAt']) ?? DateTime(2000));

  List<Rec> _inPeriod(List<Rec> list, ReportPeriod p) {
    final r = p.range;
    if (r == null) return list;
    return list.where((x) {
      final d = _dt(x['createdAt']);
      return d != null && !d.isBefore(r.$1) && d.isBefore(r.$2);
    }).toList();
  }

  String _periodText(ReportPeriod p) {
    final r = p.range;
    if (r == null) return 'All time';
    final end = r.$2.subtract(const Duration(days: 1));
    return '${_date.format(r.$1)} - ${_date.format(end)}';
  }

  List<(String, String)> _breakdown(Iterable<String> keys, {int? top}) {
    final m = <String, int>{};
    for (final k in keys) {
      final key = k.isEmpty ? '-' : k;
      m[key] = (m[key] ?? 0) + 1;
    }
    final e = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final shown = top == null ? e : e.take(top).toList();
    return shown.map((x) => (x.key, '${x.value}')).toList();
  }

  List<(String, String)> _byMonth(Iterable<DateTime?> dates) {
    final m = <String, int>{};
    for (final d in dates) {
      if (d == null) continue;
      final k = DateFormat('yyyy-MM').format(d);
      m[k] = (m[k] ?? 0) + 1;
    }
    final keys = m.keys.toList()..sort();
    return keys
        .map((k) => (_month.format(DateTime.parse('$k-01')), '${m[k]}'))
        .toList();
  }

  String _city(String address) {
    final parts = address
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Unknown';
    return parts.length >= 2 ? parts[parts.length - 2] : parts.first;
  }

  // ---------- entry point ----------
  Future<ReportData> build(ReportType type, ReportPeriod period) {
    switch (type) {
      case ReportType.summary:
        return _summary();
      case ReportType.users:
        return _users(period);
      case ReportType.properties:
        return _properties();
      case ReportType.reservations:
        return _reservations(period);
      case ReportType.subscriptions:
        return _subscriptions(period);
      case ReportType.reviews:
        return _reviews(period);
      case ReportType.reported:
        return _reported(period);
    }
  }

  // ---------- reports ----------
  Future<ReportData> _summary() async {
    final users = await _all('users');
    final props = await _all('properties');
    final res = await _all('reservations');
    final subs = await _all('subscriptions');
    final reviews = await _all('reviews');
    final reports = await _all('reports');

    final members = users
        .where((u) => u['role'] == Roles.tenant || u['role'] == Roles.landlord)
        .toList();
    final landlords = members.where((u) => u['role'] == Roles.landlord).length;
    final rooms = props.fold<int>(0, (t, p) => t + _n(p['totalRooms']));
    final available = props.fold<int>(0, (t, p) => t + _n(p['availableRooms']));
    final occupied = rooms - available;
    final double rate = rooms == 0 ? 0 : occupied / rooms * 100;
    final bookedRes = res.where((r) =>
        r['status'] == ReservationStatus.confirmed ||
        r['status'] == ReservationStatus.completed);
    final revenue = subs
        .where((s) => s['status'] == 'active')
        .fold<double>(0, (t, s) => t + _d(s['price']));
    final avg = reviews.isEmpty
        ? '-'
        : (reviews.fold<int>(0, (t, r) => t + _n(r['rating'])) / reviews.length)
            .toStringAsFixed(1);

    final metrics = <(String, String)>[
      ('Registered users', '${members.length}'),
      ('Tenants', '${members.length - landlords}'),
      ('Landlords', '$landlords'),
      ('Boarding houses', '${props.length}'),
      ('Total rooms', '$rooms'),
      ('Occupied rooms', '$occupied'),
      ('Occupancy rate', '${rate.toStringAsFixed(0)}%'),
      ('Reservations', '${res.length}'),
      ('Confirmed / completed', '${bookedRes.length}'),
      ('Subscription revenue', _peso(revenue)),
      ('Reviews', '${reviews.length}'),
      ('Average rating', avg),
      ('Pending payments',
          '${subs.where((s) => s['status'] == 'pending').length}'),
      ('Pending reports',
          '${reports.where((r) => r['status'] == 'pending').length}'),
    ];

    return ReportData(
      title: 'System Summary',
      period: 'Current state (all time)',
      note: 'This report always shows the whole platform as of now.',
      metrics: metrics,
      headers: const ['Metric', 'Value'],
      rows: metrics.map((m) => [m.$1, m.$2]).toList(),
    );
  }

  Future<ReportData> _users(ReportPeriod p) async {
    final all = (await _all('users')).where((u) => u['role'] != Roles.admin).toList();
    final list = _inPeriod(all, p)..sort(_newest);

    final tenants = list.where((u) => u['role'] == Roles.tenant).length;
    final landlords = list.where((u) => u['role'] == Roles.landlord).length;
    final noRole = list.where((u) => _s(u['role']).isEmpty).length;
    final active = list.where((u) => u['active'] != false).length;

    return ReportData(
      title: 'Users Report',
      period: _periodText(p),
      note: 'Accounts registered in the selected period.',
      metrics: [
        ('Registered users', '${list.length}'),
        ('Tenants', '$tenants'),
        ('Landlords', '$landlords'),
        ('Role not chosen yet', '$noRole'),
        ('Active accounts', '$active'),
        ('Inactive (banned)', '${list.length - active}'),
      ],
      sections: [
        ReportSection('Registrations by month',
            _byMonth(list.map((u) => _dt(u['createdAt'])))),
      ],
      headers: const ['Name', 'Email', 'Role', 'Status', 'Joined'],
      rows: list
          .map((u) => [
                _s(u['name']),
                _s(u['email']),
                _label(_s(u['role'])),
                u['active'] == false ? 'Inactive' : 'Active',
                _fmt(_dt(u['createdAt'])),
              ])
          .toList(),
    );
  }

  Future<ReportData> _properties() async {
    final props = await _all('properties');
    final users = await _all('users');
    final res = await _all('reservations');
    final owners = {for (final u in users) _s(u['_id']): _name(u)};
    final city = {for (final x in props) _s(x['_id']): _city(_s(x['address']))};

    final rooms = props.fold<int>(0, (t, x) => t + _n(x['totalRooms']));
    final available = props.fold<int>(0, (t, x) => t + _n(x['availableRooms']));
    final occupied = rooms - available;
    final double rate = rooms == 0 ? 0 : occupied / rooms * 100;
    final active = props.where((x) => x['active'] != false).length;
    final views = props.fold<int>(0, (t, x) => t + _n(x['views']));

    // Popular locations: [properties, reservations] per location.
    final stats = <String, List<int>>{};
    for (final x in props) {
      final e = stats.putIfAbsent(city[_s(x['_id'])]!, () => [0, 0]);
      e[0]++;
    }
    for (final r in res) {
      final c = city[_s(r['propertyId'])];
      if (c == null) continue;
      final e = stats.putIfAbsent(c, () => [0, 0]);
      e[1]++;
    }
    final popular = stats.entries.toList()
      ..sort((a, b) {
        final c = b.value[1].compareTo(a.value[1]);
        return c != 0 ? c : b.value[0].compareTo(a.value[0]);
      });

    final byViews = [...props]
      ..sort((a, b) => _n(b['views']).compareTo(_n(a['views'])));

    final sorted = [...props]..sort(_newest);

    return ReportData(
      title: 'Properties & Rooms Report',
      period: 'Current state (all time)',
      note: 'Listings and occupancy as of now.',
      metrics: [
        ('Boarding houses', '${props.length}'),
        ('Visible to tenants', '$active'),
        ('Hidden', '${props.length - active}'),
        ('Total rooms', '$rooms'),
        ('Available rooms', '$available'),
        ('Occupied rooms', '$occupied'),
        ('Occupancy rate', '${rate.toStringAsFixed(0)}%'),
        ('Total listing views', '$views'),
      ],
      sections: [
        ReportSection(
            'Popular locations',
            popular
                .take(8)
                .map((e) =>
                    (e.key, '${e.value[0]} properties, ${e.value[1]} reservations'))
                .toList()),
        ReportSection(
            'Most viewed listings',
            byViews
                .where((x) => _n(x['views']) > 0)
                .take(5)
                .map((x) => (_s(x['name']), '${_n(x['views'])} views'))
                .toList()),
      ],
      headers: const [
        'Property', 'Owner', 'Location', 'Price', 'Rooms', 'Available',
        'Status', 'Rating'
      ],
      rows: sorted
          .map((x) => [
                _s(x['name']),
                owners[_s(x['ownerId'])] ?? '-',
                city[_s(x['_id'])] ?? '-',
                _peso(_d(x['price'])),
                '${_n(x['totalRooms'])}',
                '${_n(x['availableRooms'])}',
                x['active'] == false ? 'Hidden' : 'Visible',
                _n(x['ratingCount']) == 0
                    ? '-'
                    : (_n(x['ratingSum']) / _n(x['ratingCount']))
                        .toStringAsFixed(1),
              ])
          .toList(),
    );
  }

  Future<ReportData> _reservations(ReportPeriod p) async {
    final list = _inPeriod(await _all('reservations'), p)..sort(_newest);

    int count(String s) => list.where((r) => r['status'] == s).length;
    final booked = list.where((r) =>
        r['status'] == ReservationStatus.confirmed ||
        r['status'] == ReservationStatus.completed);
    final revenue = booked.fold<double>(0, (t, r) => t + _d(r['price']));

    return ReportData(
      title: 'Reservations Report',
      period: _periodText(p),
      note: 'Reservation requests made in the selected period. '
          'Booked revenue is the monthly rent of confirmed and completed reservations.',
      metrics: [
        ('Total reservations', '${list.length}'),
        ('Pending', '${count(ReservationStatus.pending)}'),
        ('Confirmed', '${count(ReservationStatus.confirmed)}'),
        ('Completed', '${count(ReservationStatus.completed)}'),
        ('Declined', '${count(ReservationStatus.declined)}'),
        ('Cancelled', '${count(ReservationStatus.cancelled)}'),
        ('Booked monthly revenue', _peso(revenue)),
      ],
      sections: [
        ReportSection('By room type',
            _breakdown(list.map((r) => _s(r['roomType'])))),
        ReportSection('Top properties',
            _breakdown(list.map((r) => _s(r['propertyName'])), top: 5)),
        ReportSection('Requests by month',
            _byMonth(list.map((r) => _dt(r['createdAt'])))),
      ],
      headers: const [
        'Tenant', 'Property', 'Room type', 'Move-in', 'Months', 'Rent',
        'Status', 'Requested'
      ],
      rows: list
          .map((r) => [
                _s(r['tenantName']),
                _s(r['propertyName']),
                _s(r['roomType']),
                _fmt(_dt(r['moveInDate'])),
                '${_n(r['months'])}',
                _peso(_d(r['price'])),
                _label(_s(r['status'])),
                _fmt(_dt(r['createdAt'])),
              ])
          .toList(),
    );
  }

  Future<ReportData> _subscriptions(ReportPeriod p) async {
    final all = await _all('subscriptions');
    final list = _inPeriod(all, p)..sort(_newest);

    final approved = list.where((s) => s['status'] == 'active').toList();
    final pending = list.where((s) => s['status'] == 'pending').length;
    final rejected = list.where((s) => s['status'] == 'rejected').length;
    final revenue = approved.fold<double>(0, (t, s) => t + _d(s['price']));

    final now = DateTime.now();
    final activeNow = all
        .where((s) {
          final e = _dt(s['expiresAt']);
          return s['status'] == 'active' && e != null && e.isAfter(now);
        })
        .map((s) => _s(s['landlordId']))
        .toSet()
        .length;

    final plans = <String, List<double>>{};
    for (final s in approved) {
      final e = plans.putIfAbsent(_s(s['planName']), () => [0.0, 0.0]);
      e[0] += 1;
      e[1] += _d(s['price']);
    }
    final byPlan = plans.entries.toList()
      ..sort((a, b) => b.value[1].compareTo(a.value[1]));

    return ReportData(
      title: 'Subscriptions & Revenue Report',
      period: _periodText(p),
      note: 'Payment requests submitted in the selected period. '
          'Revenue counts approved payments only.',
      metrics: [
        ('Payment requests', '${list.length}'),
        ('Approved', '${approved.length}'),
        ('Pending', '$pending'),
        ('Rejected', '$rejected'),
        ('Revenue', _peso(revenue)),
        ('Active subscribers now', '$activeNow'),
      ],
      sections: [
        ReportSection(
            'Income by plan',
            byPlan
                .map((e) => (e.key,
                    '${e.value[0].toInt()} approved, ${_peso(e.value[1])}'))
                .toList()),
      ],
      headers: const ['Landlord', 'Plan', 'Amount', 'Status', 'Date'],
      rows: list
          .map((s) => [
                _s(s['landlordName']),
                _s(s['planName']),
                _peso(_d(s['price'])),
                s['status'] == 'active' ? 'Approved' : _label(_s(s['status'])),
                _fmt(_dt(s['createdAt'])),
              ])
          .toList(),
    );
  }

  Future<ReportData> _reviews(ReportPeriod p) async {
    final list = _inPeriod(await _all('reviews'), p)..sort(_newest);
    final ratings = list.map((r) => _n(r['rating'])).toList();
    final avg = ratings.isEmpty
        ? '-'
        : (ratings.fold<int>(0, (a, b) => a + b) / ratings.length)
            .toStringAsFixed(1);

    final byProp = <String, List<int>>{};
    for (final r in list) {
      byProp.putIfAbsent(_s(r['propertyName']), () => []).add(_n(r['rating']));
    }
    final lowest = byProp.entries
        .map((e) => (
              e.key,
              e.value.fold<int>(0, (a, b) => a + b) / e.value.length,
              e.value.length
            ))
        .toList()
      ..sort((a, b) => a.$2.compareTo(b.$2));

    return ReportData(
      title: 'Reviews Report',
      period: _periodText(p),
      note: 'Reviews written in the selected period.',
      metrics: [
        ('Reviews', '${list.length}'),
        ('Average rating', avg),
      ],
      sections: [
        ReportSection('Rating distribution', [
          for (var i = 5; i >= 1; i--)
            ('$i stars', '${ratings.where((x) => x == i).length}')
        ]),
        ReportSection(
            'Lowest rated properties',
            lowest
                .take(5)
                .map((e) => (e.$1,
                    '${e.$2.toStringAsFixed(1)} from ${e.$3} review(s)'))
                .toList()),
      ],
      headers: const ['Property', 'Tenant', 'Rating', 'Comment', 'Date'],
      rows: list
          .map((r) => [
                _s(r['propertyName']),
                _s(r['tenantName']),
                '${_n(r['rating'])}',
                _cut(_s(r['comment']), 60),
                _fmt(_dt(r['createdAt'])),
              ])
          .toList(),
    );
  }

  Future<ReportData> _reported(ReportPeriod p) async {
    final list = _inPeriod(await _all('reports'), p)..sort(_newest);
    int count(String s) => list.where((r) => r['status'] == s).length;

    return ReportData(
      title: 'Reported Listings Report',
      period: _periodText(p),
      note: 'Listing reports submitted in the selected period.',
      metrics: [
        ('Reports received', '${list.length}'),
        ('Pending', '${count('pending')}'),
        ('Resolved (listing hidden)', '${count('resolved')}'),
        ('Dismissed', '${count('dismissed')}'),
      ],
      sections: [
        ReportSection('By reason', _breakdown(list.map((r) => _s(r['reason'])))),
        ReportSection('Most reported listings',
            _breakdown(list.map((r) => _s(r['propertyName'])), top: 5)),
      ],
      headers: const [
        'Property', 'Reason', 'Reporter', 'Status', 'Details', 'Date'
      ],
      rows: list
          .map((r) => [
                _s(r['propertyName']),
                _s(r['reason']),
                _s(r['reporterName']),
                _label(_s(r['status'])),
                _cut(_s(r['details']), 50),
                _fmt(_dt(r['createdAt'])),
              ])
          .toList(),
    );
  }
}