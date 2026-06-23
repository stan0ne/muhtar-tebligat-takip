# Changelog

Bu projedeki tüm önemli değişiklikler bu dosyada kayıt altına alınır.
Format [Keep a Changelog](https://keepachangelog.com/tr/1.1.0/) esas alınır.

## [Unreleased]

### Beklenen
- Türkçe karakter duyarsız arama (FTS5 / ICU collation)
- Log arşivleme / otomatik temizleme
- Tarih aralığı raporlarında grafik görselleştirme

---

## [1.0.0] — 2026-06-23

### Eklendi
- **Proje iskeleti**: Flutter Desktop (Windows) + SQLite (`sqflite_common_ffi`), tek EXE derleme.
- **Katmanlı mimari + Repository Pattern**: `core / data / services / ui` katmanları.
- **Veritabanı**: `Evraklar`, `TeslimKayitlari`, `Kullanicilar`, `Loglar`, `Ayarlar` tabloları; indeksler (ad_soyad, evrak_sayisi, durum, tarih, silindi_mi); UTF-8 encoding; migrasyon çatısı.
- **Modeller**: `Evrak`, `TeslimKaydi`, `User`, `LogEntry` (`fromMap`/`toMap`/`copyWith`).
- **Servisler**:
  - `AuthService` — giriş, seed admin (admin/admin), kullanıcı CRUD, parola değiştirme (SHA-256 + tuz).
  - `EvrakService` — ekle/güncelle/teslim et/arsivle/geri al/yumuşak sil; her işlem loglanır.
  - `BackupService` — manuel + otomatik günlük yedek, geri yükleme, yedek listesi/silme.
  - `ExportService` — Excel (Syncfusion XlsIO) + PDF (pdf paketi) rapor çıktıları.
  - `ImportService` — Excel okuma + normalize + toplu aktarım sihirbazı.
  - `LogService` — merkezi loglama + aktif kullanıcı takibi.
  - `SettingsService` — SharedPreferences anahtar-değer.
- **UI**:
  - Giriş ekranı (kullanıcı adı + şifre, göster/gizle).
  - `HomeShell`: NavigationRail menü + üst hızlı arama + kullanıcı bilgisi/çıkış.
  - Dashboard: Bekleyen / Teslim Edilen / Arşivlenen / Toplam kartları.
  - Yeni Evrak Kaydı / Evrak Düzenleme formu.
  - Evrak Arama: canlı filtre (350ms debounce), DataTable, sayfalama (50/sayfa), detay navigasyonu.
  - Bekleyen / Teslim Edilen / Arşivlenen listeleri.
  - Evrak Detay: bilgi + teslim geçmişi + işlemler (teslim, düzenle, arşivle, geri al, sil).
  - Teslim diyaloğu.
  - Raporlar: günlük/aylık/yıllık/tarih aralığı + Excel/PDF çıktı.
  - İçe Aktarma sihirbazı (dosya seç, önizle, aktar).
  - Yedekleme ekranı (yedek al, geri yükle, otomatik yedek anahtarı, yedek listesi).
  - Ayarlar: tema (açık/koyu/sistem), parola değiştirme, kullanıcı yönetimi (Yönetici), log görüntüleyici.
- **Tema**: açık/koyu/sistem desteği.
- **Roller**: Yönetici / Personel (silme yalnız Yönetici).
- **Yumuşak silme**: `silindi_mi`, `silinme_tarihi`.
- **Performans**: indeksler + sayfalama.

### Değişti
- `README.md` Flutter şablonu → tam proje dokümantasyonu.

### Doğrulama
- `flutter analyze`: 0 hata.
- `flutter build windows --release`: başarılı (`build\windows\x64\runner\Release\muhtar_tebligat_takip.exe`).
