import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/report_data.dart';

class ReportPdf {
  static String _t(String s) => s.replaceAll('₱', 'PHP ');

  static pw.Widget _table(List<String> headers, List<List<String>> rows) {
    pw.Widget cell(String s, {bool bold = false}) => pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            _t(s),
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers.map((h) => cell(h, bold: true)).toList(),
        ),
        ...rows.map((r) => pw.TableRow(children: r.map(cell).toList())),
      ],
    );
  }

  static pw.Widget _heading(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
        child: pw.Text(_t(t),
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      );

  static Future<void> share(ReportData r) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          pw.Text('ETXESPACE',
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange800)),
          pw.Text(_t(r.title),
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Period: ${_t(r.period)}', style: const pw.TextStyle(fontSize: 9)),
          pw.Text('Generated: ${r.generatedText}',
              style: const pw.TextStyle(fontSize: 9)),
          if (r.note.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(_t(r.note),
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            ),
          _heading('Key figures'),
          _table(['Metric', 'Value'],
              r.metrics.map((m) => [m.$1, m.$2]).toList()),
          for (final s in r.sections) ...[
            _heading(s.title),
            if (s.rows.isEmpty)
              pw.Text('No data.', style: const pw.TextStyle(fontSize: 9))
            else
              _table(['Item', 'Value'], s.rows.map((x) => [x.$1, x.$2]).toList()),
          ],
          if (r.headers.isNotEmpty) ...[
            _heading('Details (${r.rows.length})'),
            if (r.rows.isEmpty)
              pw.Text('No records.', style: const pw.TextStyle(fontSize: 9))
            else
              _table(r.headers, r.rows),
          ],
        ],
      ),
    );

    final d = r.generatedAt;
    final stamp =
        '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
    final slug = r.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'etxespace_${slug}_$stamp.pdf',
    );
  }
}