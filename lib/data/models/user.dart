/// Kullanıcı modeli.
class User {
  final int? id;
  final String kullaniciAdi;
  final String sifreHash;
  final String rol;
  final String? adSoyad;
  final bool aktif;
  final String olusturmaTarihi;
  final String guncellemeTarihi;

  User({
    this.id,
    required this.kullaniciAdi,
    required this.sifreHash,
    required this.rol,
    this.adSoyad,
    this.aktif = true,
    required this.olusturmaTarihi,
    required this.guncellemeTarihi,
  });

  factory User.fromMap(Map<String, Object?> m) => User(
        id: m['id'] as int?,
        kullaniciAdi: (m['kullanici_adi'] as String?) ?? '',
        sifreHash: (m['sifre_hash'] as String?) ?? '',
        rol: (m['rol'] as String?) ?? 'Personel',
        adSoyad: m['ad_soyad'] as String?,
        aktif: ((m['aktif'] as int?) ?? 1) == 1,
        olusturmaTarihi: (m['olusturma_tarihi'] as String?) ?? '',
        guncellemeTarihi: (m['guncelleme_tarihi'] as String?) ?? '',
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'kullanici_adi': kullaniciAdi,
        'sifre_hash': sifreHash,
        'rol': rol,
        'ad_soyad': adSoyad,
        'aktif': aktif ? 1 : 0,
        'olusturma_tarihi': olusturmaTarihi,
        'guncelleme_tarihi': guncellemeTarihi,
      };

  bool get isYonetici => rol == 'Yönetici';
}
