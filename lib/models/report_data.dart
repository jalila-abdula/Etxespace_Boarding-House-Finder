import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ReportPeriod {
  thisMonth('This Month'),
  lastMonth('Last Month'),
  last30('Last 30 Days'),
  thisYear('This Year'),
  allTime('All Time');

  final String label;
  const ReportPeriod(this.label);

  /// Start (inclusive) and end (exclusive). Null means no date limit.
  (DateTime, DateTime)? get range {
    final n = DateTime.now();
    switch (this) {
      case ReportPeriod.thisMonth:
        return (DateTime(n.year, n.month, 1), DateTime(n.year, n.month + 1, 1));
      case ReportPeriod.lastMonth:
        return (DateTime(n.year, n.month - 1, 1), DateTime(n.year, n.month, 1));
      case ReportPeriod.last30:
        return (
          DateTime(n.year, n.month, n.day).subtract(const Duration(days: 29)),
          DateTime(n.year, n.month, n.day + 1)
        );
      case ReportPeriod.thisYear:
        return (DateTime(n.year, 1, 1), DateTime(n.year + 1, 1, 1));
      case ReportPeriod.allTime:
        return null;
    }
  }
}

enum ReportType {
  summary('System Summary', 'Key figures across the whole platform',
      Icons.dashboard_outlined, false),
  users('Users Report', 'Tenants, landlords and registrations',
      Icons.people_outline, true),
  properties('Properties & Rooms',
      'Listings, occupancy and popular locations', Icons.apartment, false),
  reservations('Reservations Report', 'Status, room types and booked revenue',
      Icons.assignment_outlined, true),
  subscriptions('Subscriptions & Revenue', 'Plans, payments and income',
      Icons.diamond_outlined, true),
  reviews('Reviews Report', 'Ratings and tenant feedback',
      Icons.star_outline, true),
  reported('Reported Listings', 'Reports and how they were handled',
      Icons.flag_outlined, true);

  final String label;
  final String description;
  final IconData icon;
  final bool usesPeriod;
  const ReportType(this.label, this.description, this.icon, this.usesPeriod);
}

class ReportSection {
  final String title;
  final List<(String, String)> rows;
  const ReportSection(this.title, this.rows);
}

String _q(String s) => '"${s.replaceAll('"', '""')}"';

class ReportData {
  final String title;
  final String period;
  final String note;
  final DateTime generatedAt;
  final List<(String, String)> metrics;
  final List<ReportSection> sections;
  final List<String> headers;
  final List<List<String>> rows;

  ReportData({
    required this.title,
    required this.period,
    this.note = '',
    required this.metrics,
    this.sections = const [],
    this.headers = const [],
    this.rows = const [],
  }) : generatedAt = DateTime.now();

  String get generatedText =>
      DateFormat('MMM d, y h:mm a').format(generatedAt);

  String toCsv() {
    final b = StringBuffer();
    b.writeln(_q('ETXESPACE - $title'));
    b.writeln('${_q('Period')},${_q(period)}');
    b.writeln('${_q('Generated')},${_q(generatedText)}');
    b.writeln();
    b.writeln(_q('Key figures'));
    for (final m in metrics) {
      b.writeln('${_q(m.$1)},${_q(m.$2)}');
    }
    for (final s in sections) {
      b.writeln();
      b.writeln(_q(s.title));
      for (final r in s.rows) {
        b.writeln('${_q(r.$1)},${_q(r.$2)}');
      }
    }
    if (headers.isNotEmpty) {
      b.writeln();
      b.writeln(_q('Details'));
      b.writeln(headers.map(_q).join(','));
      for (final r in rows) {
        b.writeln(r.map(_q).join(','));
      }
    }
    return b.toString();
  }
}