import 'evrak.dart';

/// Teslim kaydı modeli (vatandaşa/yalına teslim bilgisini tutar).
class TeslimKaydi {
  final int? id;
  final int evrakId;
  final String teslimAlanAdSoyad;
  final String? tcKimlikNo;
  final String? telefon;
  final String teslimTarihi; // ISO8601 tam
  final String? aciklama;
  final String olusturmaTarihi;

  TeslimKaydi({
    this.id,
    required this.evrakId,
    required this.teslimAlanAdSoyad,
    this.tcKimlikNo,
    this.telefon,
    required this.teslimTarihi,
    this.aciklama,
    required this.olusturmaTarihi,
  });

  factory TeslimKaydi.fromMap(Map<String, Object?> m) => TeslimKaydi(
        id: m['id'] as int?,
        evrakId: (m['evrak_id'] as int?) ?? 0,
        teslimAlanAdSoyad: (m['teslim_alan_ad_soyad'] as String?) ?? '',
        tcKimlikNo: m['tc_kimlik_no'] as String?,
        telefon: m['telefon'] as String?,
        teslimTarihi: (m['teslim_tarihi'] as String?) ?? '',
        aciklama: m['aciklama'] as String?,
        olusturmaTarihi: (m['olusturma_tarihi'] as String?) ?? '',
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'evrak_id': evrakId,
        'teslim_alan_ad_soyad': teslimAlanAdSoyad,
        'tc_kimlik_no': tcKimlikNo,
        'telefon': telefon,
        'teslim_tarihi': teslimTarihi,
        'aciklama': aciklama,
        'olusturma_tarihi': olusturmaTarihi,
      };
}

/// Arama sonuçlarında evrak + son teslim bilgisini birleştiren görünüm.
class EvrakWithTeslim {
  final Evrak evrak;
  final TeslimKaydi? sonTeslim;

  EvrakWithTeslim({required this.evrak, this.sonTeslim});
}
