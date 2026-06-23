# Muhtarlık Tebligat Takip Sistemi

Windows ortamında çalışan, modern, hızlı ve sade bir **muhtarlık tebligat takip** uygulaması.
Flutter Desktop + SQLite ile geliştirilmiştir. Sunucu gerektirmez, tek EXE olarak dağıtılabilir.

## Özellikler

- **Evrak kaydı**: geliş tarihi, ad soyad, geldiği kurum, evrak sayısı (otomatik "Bekliyor" durumu)
- **Canlı arama**: ad soyad / evrak no / kurum / tarih aralığı / durum filtreleri (debounce'lu)
- **Durum yönetimi**: Bekliyor → Teslim Edildi / Arşivlendi, arşivden geri alma
- **Teslim işlemi**: teslim alan, T.C. kimlik, telefon, açıklama → otomatik teslim kaydı + tarih
- **Arşivleme**: manuel arşivle / geri al, kayıtlar silinmez
- **Raporlar**: günlük/aylık/yıllık/tarih aralığı + **Excel** ve **PDF** çıktıları
- **Yedekleme**: manuel + otomatik günlük yedek, geri yükleme, yedek listesi
- **Excel içe aktarma**: sihirbaz (başlık eşleme, önizleme, "Evrakı Alan" → Teslim Edildi)
- **Kullanıcı yönetimi**: Yönetici / Personel rolleri, parola değiştirme, aktif/pasif
- **Log sistemi**: tüm işlemler (ekleme, güncelleme, teslim, arşivleme, silme, giriş/çıkış, yedekleme, içe aktarma)
- **Yumuşak silme**: kayıtlar fiziksel silinmez (`silindi_mi`, `silinme_tarihi`)
- **Tema**: açık / koyu / sistem
- **Performans**: indeksler (ad_soyad, evrak_sayisi, durum, tarih) + sayfalama (50/sayfa) → 500.000+ kayıt hedefi
- **Türkçe arayüz**, UTF-8 desteği

## Kurulum & Çalıştırma

### Gereksinimler
- Flutter 3.41+ (stable)
- Windows 10/11
- **Geliştirici Modu** açık olmalı (plugin symlink için): `ms-settings:developers`

### Geliştirme
```bash
flutter pub get
flutter run -d windows
```

### Release derleme (tek EXE + DLL)
```bash
flutter build windows --release
```
Çıktı: `build\windows\x64\runner\Release\muhtar_tebligat_takip.exe`

Dağıtım için `Release` klasörünün tamamı (EXE + DLL + data) kopyalanır.

### İlk Giriş
- Kullanıcı: `admin`
- Şifre: `admin`
- Giriş sonrası **Ayarlar** → parola değiştirme önerilir.

## Mimari

Katmanlı mimari + Repository Pattern. Ayrıntılar: [ARCHITECTURE.md](./ARCHITECTURE.md)

```
lib/
├── core/              # Sabitler, tarih yardımcıları
├── data/
│   ├── database/      # SQLite yöneticisi, şema, migrasyon, indeksler
│   ├── models/        # Evrak, TeslimKaydi, User, LogEntry
│   └── repositories/  # Repository Pattern (Evrak/Teslim/User/Log)
├── services/          # İş katmanı: Auth, Evrak, Backup, Export, Import, Log, Settings
└── ui/
    ├── auth/          # Giriş ekranı
    ├── pages/         # Tüm ekranlar + widget'lar
    ├── providers/     # Provider ile durum yönetimi
    ├── shell/         # Ana menü iskeleti
    ├── theme/         # Açık/koyu tema
    └── widgets/       # Ortak UI yardımcıları
```

## Veritabanı

SQLite (tek `tebligat.db` dosyası, `ApplicationSupportDirectory` altında).

**Tablolar:** `Evraklar`, `TeslimKayitlari`, `Kullanicilar`, `Loglar`, `Ayarlar`

Detaylı şema ve indeksler: [ARCHITECTURE.md](./ARCHITECTURE.md#veritabanı-şeması)

## Dokümanlar

- [PROJECT_STATUS.md](./PROJECT_STATUS.md) — güncel durum, yapılacaklar, kontrol listesi
- [CHANGELOG.md](./CHANGELOG.md) — sürüm değişiklikleri
- [ARCHITECTURE.md](./ARCHITECTURE.md) — mimari ve teknik tasarım
- [Prompt.md](./Prompt.md) — orijinal gereksinimler
