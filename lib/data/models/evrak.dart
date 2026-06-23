import 'dart:core';

/// Evrak (tebligat) modeli.
class Evrak {
  final int? id;
  final String gelisTarihi; // ISO8601 (yyyy-MM-dd)
  final String adSoyad;
  final String? geldigiKurum;
  final String? evrakSayisi;
  final String durum;
  final String? teslimTarihi; // ISO8601 tam
  final String olusturmaTarihi; // ISO8601 tam
  final String guncellemeTarihi; // ISO8601 tam
  final int silindiMi;
  final String? silinmeTarihi;

  Evrak({
    this.id,
    required this.gelisTarihi,
    required this.adSoyad,
    this.geldigiKurum,
    this.evrakSayisi,
    this.durum = 'Bekliyor',
    this.teslimTarihi,
    required this.olusturmaTarihi,
    required this.guncellemeTarihi,
    this.silindiMi = 0,
    this.silinmeTarihi,
  });

  factory Evrak.fromMap(Map<String, Object?> m) => Evrak(
        id: m['id'] as int?,
        gelisTarihi: (m['gelis_tarihi'] as String?) ?? '',
        adSoyad: (m['ad_soyad'] as String?) ?? '',
        geldigiKurum: m['geldigi_kurum'] as String?,
        evrakSayisi: m['evrak_sayisi'] as String?,
        durum: (m['durum'] as String?) ?? 'Bekliyor',
        teslimTarihi: m['teslim_tarihi'] as String?,
        olusturmaTarihi: (m['olusturma_tarihi'] as String?) ?? '',
        guncellemeTarihi: (m['guncelleme_tarihi'] as String?) ?? '',
        silindiMi: (m['silindi_mi'] as int?) ?? 0,
        silinmeTarihi: m['silinme_tarihi'] as String?,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'gelis_tarihi': gelisTarihi,
        'ad_soyad': adSoyad,
        'geldigi_kurum': geldigiKurum,
        'evrak_sayisi': evrakSayisi,
        'durum': durum,
        'teslim_tarihi': teslimTarihi,
        'olusturma_tarihi': olusturmaTarihi,
        'guncelleme_tarihi': guncellemeTarihi,
        'silindi_mi': silindiMi,
        'silinme_tarihi': silinmeTarihi,
      };

  Evrak copyWith({
    int? id,
    String? gelisTarihi,
    String? adSoyad,
    String? geldigiKurum,
    String? evrakSayisi,
    String? durum,
    String? teslimTarihi,
    String? olusturmaTarihi,
    String? guncellemeTarihi,
    int? silindiMi,
    String? silinmeTarihi,
  }) =>
      Evrak(
        id: id ?? this.id,
        gelisTarihi: gelisTarihi ?? this.gelisTarihi,
        adSoyad: adSoyad ?? this.adSoyad,
        geldigiKurum: geldigiKurum ?? this.geldigiKurum,
        evrakSayisi: evrakSayisi ?? this.evrakSayisi,
        durum: durum ?? this.durum,
        teslimTarihi: teslimTarihi ?? this.teslimTarihi,
        olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
        guncellemeTarihi: guncellemeTarihi ?? this.guncellemeTarihi,
        silindiMi: silindiMi ?? this.silindiMi,
        silinmeTarihi: silinmeTarihi ?? this.silinmeTarihi,
      );
}
