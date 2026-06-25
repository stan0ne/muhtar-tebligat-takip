import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/constants.dart';
import '../core/date_util.dart';
import 'log_service.dart';

/// Excel'den içe aktarma satırı (normalize edilmiş).
class ImportRow {
  final String tarih;
  final String adSoyad;
  final String? geldigiYer;
  final String? sayi;
  final String? tcKimlikNo;
  final String? telefon;
  final String? evrakiAlan;

  ImportRow({
    required this.tarih,
    required this.adSoyad,
    this.geldigiYer,
    this.sayi,
    this.tcKimlikNo,
    this.telefon,
    this.evrakiAlan,
  });
}

/// İçe aktarma sonucu.
class ImportResult {
  final int toplam;
  final int basarili;
  final List<String> hatalar;

  ImportResult({required this.toplam, required this.basarili, required this.hatalar});
}

/// Excel içe aktarma servisi.
///
/// Beklenen kolon başlıkları (sıra önemli değil, başlık metnine göre eşleşir):
/// Tarih, Ad Soyad, Geldiği Yer, Sayı, T.C. Kimlik No, Telefon No, Evrakı Alan
/// (ikinci "Tarih" kolonu teslim tarihi olarak yorumlanır).
class ImportService {
  /// Boş Excel şablonu oluşturur ve dosya yolunu döndürür.
  Future<String> createTemplate() async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Başlık satırı
    final headers = [
      'Tarih',
      'Ad Soyad',
      'Geldiği Yer',
      'Sayı',
      'T.C. Kimlik No',
      'Telefon No',
      'Evrakı Alan',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(bold: true);
    }

    // Örnek satır
    final example = [
      '24-06-2026',
      'Ahmet Yılmaz',
      'Nüfus Müdürlüğü',
      'E-2026/045',
      '12345678901',
      '0532 123 4567',
      '',
    ];

    for (var i = 0; i < example.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
      cell.value = TextCellValue(example[i]);
    }

    // Kolon genişlikleri
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Kaydet — Downloads klasörüne
    final dir = await getDownloadsDirectory();
    if (dir == null) throw Exception('Downloads klasörü bulunamadı');
    final filePath = p.join(dir.path, 'ice_aktarma_sablonu.xlsx');
    final file = File(filePath);
    file.writeAsBytesSync(excel.encode()!);
    return filePath;
  }

  /// Excel dosyasını okur ve ImportRow listesine dönüştürür.
  Future<List<ImportRow>> readRows(String path) async {
    final bytes = File(path).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null) return [];

    final rows = sheet.rows;
    if (rows.isEmpty) return [];

    // Başlık eşleme
    final header = rows.first.map((c) => (c?.value ?? '').toString().trim()).toList();
    int idx(String key) => header.indexWhere(
        (h) => h.toLowerCase() == key.toLowerCase());

    final iTarih = idx('Tarih');
    final iAd = idx('Ad Soyad');
    final iYer = idx('Geldiği Yer');
    final iSayi = idx('Sayı');
    final iTc = idx('T.C. Kimlik No');
    final iTel = idx('Telefon No');
    final iAlan = idx('Evrakı Alan');

    final out = <ImportRow>[];
    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      String cell(int i) =>
          i >= 0 && i < row.length ? (row[i]?.value ?? '').toString().trim() : '';
      final ad = cell(iAd);
      if (ad.isEmpty) continue;
      out.add(ImportRow(
        tarih: _normalizeDate(cell(iTarih)) ?? DateUtil.todayIso(),
        adSoyad: ad,
        geldigiYer: _nonEmpty(cell(iYer)),
        sayi: _nonEmpty(cell(iSayi)),
        tcKimlikNo: _nonEmpty(cell(iTc)),
        telefon: _nonEmpty(cell(iTel)),
        evrakiAlan: _nonEmpty(cell(iAlan)),
      ));
    }
    return out;
  }

  String? _nonEmpty(String s) => s.isEmpty ? null : s;

  String? _normalizeDate(String raw) {
    if (raw.isEmpty) return null;
    // dd.MM.yyyy -> yyyy-MM-dd
    final m = RegExp(r'^(\d{1,2})[./-](\d{1,2})[./-](\d{4})$').firstMatch(raw);
    if (m != null) {
      final d = m.group(1)!.padLeft(2, '0');
      final mo = m.group(2)!.padLeft(2, '0');
      return '${m.group(3)}-$mo-$d';
    }
    // yyyy-MM-dd
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(raw)) {
      return raw.substring(0, 10);
    }
    return null;
  }

  /// Okunan satırları veritabanına yazar.
  ///
  /// Eğer satırda "Evrakı Alan" varsa, kayıt "Teslim Edildi" durumunda
  /// oluşturulur ve teslim kaydı eklenir.
  Future<ImportResult> apply(List<ImportRow> rows) async {
    final evrakSvc = Services.evrak;
    var basarili = 0;
    final hatalar = <String>[];

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      try {
        final evrak = await evrakSvc.ekle(
          gelisTarihi: row.tarih,
          adSoyad: row.adSoyad,
          geldigiKurum: row.geldigiYer,
          evrakSayisi: row.sayi,
        );
        if (row.evrakiAlan != null && row.evrakiAlan!.isNotEmpty) {
          await evrakSvc.teslimEt(
            evrakId: evrak.id!,
            teslimAlanAdSoyad: row.evrakiAlan!,
            tcKimlikNo: row.tcKimlikNo,
            telefon: row.telefon,
          );
        }
        basarili++;
      } catch (e) {
        hatalar.add('Satır ${i + 2}: $e');
      }
    }

    await Services.log.log(LogIslem.iceAktarma,
        aciklama: '${rows.length} satırdan $basarili başarılı');
    return ImportResult(
        toplam: rows.length, basarili: basarili, hatalar: hatalar);
  }
}
