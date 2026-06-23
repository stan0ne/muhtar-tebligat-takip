/// Log (iz) kaydı modeli.
class LogEntry {
  final int? id;
  final int? kullaniciId;
  final String? kullaniciAdi;
  final String islem;
  final String? hedefTablo;
  final int? hedefId;
  final String? aciklama;
  final String tarih;

  LogEntry({
    this.id,
    this.kullaniciId,
    this.kullaniciAdi,
    required this.islem,
    this.hedefTablo,
    this.hedefId,
    this.aciklama,
    required this.tarih,
  });

  factory LogEntry.fromMap(Map<String, Object?> m) => LogEntry(
        id: m['id'] as int?,
        kullaniciId: m['kullanici_id'] as int?,
        kullaniciAdi: m['kullanici_adi'] as String?,
        islem: (m['islem'] as String?) ?? '',
        hedefTablo: m['hedef_tablo'] as String?,
        hedefId: m['hedef_id'] as int?,
        aciklama: m['aciklama'] as String?,
        tarih: (m['tarih'] as String?) ?? '',
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'kullanici_id': kullaniciId,
        'kullanici_adi': kullaniciAdi,
        'islem': islem,
        'hedef_tablo': hedefTablo,
        'hedef_id': hedefId,
        'aciklama': aciklama,
        'tarih': tarih,
      };
}
