import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';
import '../../models/report_data.dart';
import '../../services/report_pdf.dart';
import '../../services/report_service.dart';
import '../../widgets/admin_ui.dart';

class GenerateReportsScreen extends StatefulWidget {
  const GenerateReportsScreen({super.key});
  @override
  State<GenerateReportsScreen> createState() => _GenerateReportsScreenState();
}

class _GenerateReportsScreenState extends State<GenerateReportsScreen> {
  ReportType _type = ReportType.summary;
  ReportPeriod _period = ReportPeriod.thisMonth;
  ReportData? _report;
  bool _busy = false;
  bool _pdfBusy = false;
  String? _error;

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await ReportService().build(_type, _period);
      if (mounted) setState(() => _report = r);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not generate the report.\n$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyCsv(ReportData r) async {
    await Clipboard.setData(ClipboardData(text: r.toCsv()));
    if (mounted) {
      toast(context, 'CSV copied. Paste it into Excel, Sheets or Notes.');
    }
  }

  Future<void> _sharePdf(ReportData r) async {
    setState(() => _pdfBusy = true);
    try {
      await ReportPdf.share(r);
    } catch (e) {
      if (mounted) toast(context, 'Could not create the PDF: $e');
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 10),
        child: Text(t,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      );

  Widget _typeCard(ReportType t) {
    final sel = _type == t;
    return GestureDetector(
      onTap: () => setState(() {
        _type = t;
        _report = null;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: sel ? Colors.orange.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: sel ? AppColors.orange : Colors.grey.shade200,
              width: sel ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(t.icon, color: sel ? AppColors.orange : Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(t.description,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (sel) const Icon(Icons.check_circle, color: AppColors.orange),
          ],
        ),
      ),
    );
  }

  Widget _metricTile(String label, String value, double width) => Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: cardDeco(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      );

  Widget _result(ReportData r) {
    final tileW = (MediaQuery.of(context).size.width - 32 - 10) / 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text(r.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        Text('Period: ${r.period}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        Text('Generated: ${r.generatedText}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        if (r.note.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(r.note,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44)),
                onPressed: () => _copyCsv(r),
                icon: const Icon(Icons.copy_all_outlined, size: 18),
                label: const Text('Copy CSV'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.greenDark,
                    minimumSize: const Size.fromHeight(44)),
                onPressed: _pdfBusy ? null : () => _sharePdf(r),
                icon: _pdfBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Share PDF'),
              ),
            ),
          ],
        ),
        _title('Key figures'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: r.metrics.map((m) => _metricTile(m.$1, m.$2, tileW)).toList(),
        ),
        for (final s in r.sections) ...[
          _title(s.title),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: cardDeco(14),
            child: s.rows.isEmpty
                ? Text('No data.', style: TextStyle(color: Colors.grey.shade600))
                : Column(
                    children: s.rows
                        .map((x) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                      child: Text(x.$1,
                                          style: const TextStyle(fontSize: 13))),
                                  const SizedBox(width: 12),
                                  Text(x.$2,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ],
        if (r.headers.isNotEmpty) ...[
          _title('Details (${r.rows.length} records)'),
          if (r.rows.isEmpty)
            Text('No records for this period.',
                style: TextStyle(color: Colors.grey.shade600))
          else ...[
            Container(
              width: double.infinity,
              decoration: cardDeco(14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  headingRowHeight: 38,
                  dataRowMinHeight: 34,
                  dataRowMaxHeight: 44,
                  columns: r.headers
                      .map((h) => DataColumn(
                          label: Text(h,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700))))
                      .toList(),
                  rows: r.rows
                      .take(15)
                      .map((row) => DataRow(
                          cells: row
                              .map((c) => DataCell(
                                  Text(c, style: const TextStyle(fontSize: 12))))
                              .toList()))
                      .toList(),
                ),
              ),
            ),
            if (r.rows.length > 15)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    'Showing the first 15 of ${r.rows.length}. The CSV and PDF include every record.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ),
          ],
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Generate Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _title('1. Choose a report'),
          ...ReportType.values.map(_typeCard),
          const SizedBox(height: 8),
          _title('2. Choose a period'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReportPeriod.values
                .map((p) => ChoiceChip(
                      label: Text(p.label),
                      selected: _period == p && _type.usesPeriod,
                      selectedColor: AppColors.orange,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                          color: _period == p && _type.usesPeriod
                              ? Colors.white
                              : Colors.black87),
                      onSelected: _type.usesPeriod
                          ? (_) => setState(() {
                                _period = p;
                                _report = null;
                              })
                          : null,
                    ))
                .toList(),
          ),
          if (!_type.usesPeriod)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('This report shows the current state, so no period is needed.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
            onPressed: _busy ? null : _generate,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.analytics_outlined),
            label: Text(_busy ? 'Generating...' : 'Generate report'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          if (_report != null) _result(_report!),
        ],
      ),
    );
  }
}