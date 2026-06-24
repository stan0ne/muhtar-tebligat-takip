/// Evrak durum değişikliği geçmişi modeli.
class DurumGecmisi {
  final int? id;
  final int evrakId;
  final String? eskiDurum;
  final String yeniDurum;
  final String degisiklikTarihi;
  final String? aciklama;

  const DurumGecmisi({
    this.id,
    required this.evrakId,
    this.eskiDurum,
    required this.yeniDurum,
    required this.degisiklikTarihi,
    this.aciklama,
  });

  factory DurumGecmisi.fromMap(Map<String, Object?> m) => DurumGecmisi(
        id: m['id'] as int?,
        evrakId: m['evrak_id'] as int,
        eskiDurum: m['eski_durum'] as String?,
        yeniDurum: m['yeni_durum'] as String,
        degisiklikTarihi: m['degisiklik_tarihi'] as String,
        aciklama: m['aciklama'] as String?,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'evrak_id': evrakId,
        'eski_durum': eskiDurum,
        'yeni_durum': yeniDurum,
        'degisiklik_tarihi': degisiklikTarihi,
        'aciklama': aciklama,
      };
}
