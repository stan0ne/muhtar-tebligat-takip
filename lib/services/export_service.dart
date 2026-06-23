import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import '../core/date_util.dart';
import '../data/models/evrak.dart';

/// Rapor/sayısal sonuç modeli.
class RaporSonuc {
  final String baslik;
  final DateTime baslangic;
  final DateTime bitis;
  final int toplam;
  final int bekleyen;
  final int teslimEdilen;
  final int arsivlenen;
  final List<Evrak> evraklar;

  RaporSonuc({
    required this.baslik,
    required this.baslangic,
    required this.bitis,
    required this.toplam,
    required this.bekleyen,
    required this.teslimEdilen,
    required this.arsivlenen,
    required this.evraklar,
  });
}

/// Rapor çıktıları (Excel/PDF) servisi.
class ExportService {
  /// Excel raporu üretir ve dosya yolunu döner.
  Future<String> exportExcel(RaporSonuc rapor) async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Rapor';

    sheet.getRangeByIndex(1, 1).setText(rapor.baslik);
    sheet.getRangeByIndex(2, 1).setText(
        'Dönem: ${DateFormat('dd.MM.yyyy').format(rapor.baslangic)} - '
        '${DateFormat('dd.MM.yyyy').format(rapor.bitis)}');
    sheet.getRangeByIndex(3, 1).setText('Toplam: ${rapor.toplam}');
    sheet.getRangeByIndex(3, 2).setText('Bekleyen: ${rapor.bekleyen}');
    sheet.getRangeByIndex(3, 3).setText('Teslim Edilen: ${rapor.teslimEdilen}');
    sheet.getRangeByIndex(3, 4).setText('Arşivlenen: ${rapor.arsivlenen}');

    final headers = [
      'Ad Soyad',
      'Geldiği Kurum',
      'Evrak Sayısı',
      'Geliş Tarihi',
      'Durum',
      'Teslim Tarihi'
    ];
    for (var i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(5, i + 1).setText(headers[i]);
    }

    for (var i = 0; i < rapor.evraklar.length; i++) {
      final e = rapor.evraklar[i];
      final row = 6 + i;
      sheet.getRangeByIndex(row, 1).setText(e.adSoyad);
      sheet.getRangeByIndex(row, 2).setText(e.geldigiKurum ?? '');
      sheet.getRangeByIndex(row, 3).setText(e.evrakSayisi ?? '');
      sheet.getRangeByIndex(row, 4).setText(DateUtil.displayDate(e.gelisTarihi));
      sheet.getRangeByIndex(row, 5).setText(e.durum);
      sheet.getRangeByIndex(row, 6).setText(DateUtil.displayDate(e.teslimTarihi));
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(dir.path, 'rapor_$stamp.xlsx'));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// PDF raporu üretir ve dosya yolunu döner.
  Future<String> exportPdf(RaporSonuc rapor) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          pw.Text(rapor.baslik,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(
            'Dönem: ${DateFormat('dd.MM.yyyy').format(rapor.baslangic)} - '
            '${DateFormat('dd.MM.yyyy').format(rapor.bitis)}',
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _pill('Toplam', rapor.toplam),
              pw.SizedBox(width: 12),
              _pill('Bekleyen', rapor.bekleyen),
              pw.SizedBox(width: 12),
              _pill('Teslim Edilen', rapor.teslimEdilen),
              pw.SizedBox(width: 12),
              _pill('Arşivlenen', rapor.arsivlenen),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: [
              'Ad Soyad',
              'Geldiği Kurum',
              'Evrak Sayısı',
              'Geliş',
              'Durum',
              'Teslim'
            ],
            data: rapor.evraklar
                .map((e) => [
                      e.adSoyad,
                      e.geldigiKurum ?? '',
                      e.evrakSayisi ?? '',
                      DateUtil.displayDate(e.gelisTarihi),
                      e.durum,
                      DateUtil.displayDate(e.teslimTarihi),
                    ])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(
                color: PdfColor(0.85, 0.85, 0.85)),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(dir.path, 'rapor_$stamp.pdf'));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  pw.Widget _pill(String label, int value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor(0.7, 0.7, 0.7)),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text('$label: $value'),
    );
  }
}
