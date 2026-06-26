# Changelog

Bu projedeki tüm önemli değişiklikler bu dosyada kayıt altına alınır.
Format [Keep a Changelog](https://keepachangelog.com/tr/1.1.0/) esas alınır.

## [Unreleased]

### Beklenen
- Türkçe karakter duyarsız arama (FTS5 / ICU collation)
- Tarih aralığı raporlarında grafik görselleştirme
- Bulut yedekleme OAuth 2.0 akışı (Google Drive / OneDrive)

### Eklendi (Bugün)
- **Otomatik arşivleme**: Ayarlar sayfasından açılıp kapatılabilir. Checkbox açıksa uygulama açılışında otomatik çalışır. Kriter: geliş tarihi bu yılın 1 Ocak'ından önce (Geçmiş Yıllar) VE geliş tarihi seçili aydan eski. Ayarlar: ay eşiği (1-12), Geçmiş Yıllar checkbox'ı, son çalışma zamanı, önizleme (tıklanabilir detay listesi), "Hemen Çalıştır" butonu.
- **Tarih formatı**: Tüm tarih seçicilerde DD-MM-YYYY formatı (Flutter Türkçe locale desteği eklendi).
- **Manuel arşivleme**: EvrakDetailPage'den herhangi bir evrak elle arşive aktarılabilir.
- **İçe Aktarma şablonu**: İçe Aktarma sayfasına "Boş Şablon İndir" butonu eklendi. Downloads klasörüne kaydedilir, "Dosyayı Aç" ile doğrudan açılabilir.
- **İçe Aktarma akışı**: Dosya seçimi → önizleme (sıra numaralı liste, kayıt sayısı) → "Veritabanına Aktar" butonu → sonuç dialog'u (başarılı/hata detayı). Aktarma sonrası ekran sıfırlanır.
- **Teslim Edilenler sütunu**: Teslim Edilen Evraklar sayfasında Geliş Tarihi yerine Teslim Tarihi sütunu gösterilir.
- **Pencere boyutu**: Uygulama 1170x900 px olarak açılıyor.
- **ESC desteği**: Tüm uygulamada ESC tuşu ile bir önceki sayfaya geri dönme desteği.
- **Responsive Dashboard**: Dashboard kartları ekran boyutuna göre orantılı ölçeklenir.
- **Windows Installer**: Inno Setup ile kurulum dosyası oluşturulabilir. `create_installer.bat` çalıştırılarak otomatik build + installer üretimi.
- **Bağımlılık güncellemeleri**: flutter_localizations, intl, syncfusion_flutter_xlsio, file_picker, googleapis, googleapis_auth güncellendi.

---

## [1.3.0] — 2026-06-24

### Eklendi
- **Log arşivleme/temizleme**: Ayarlar sayfasına Log Yönetimi paneli eklendi. Toplam log sayısı, en eski log tarihi, X günden eski logları temizle, tüm logları sil seçenekleri.
- **Toplu teslim**: Bekleyen Evraklar listesinde çoklu seçim ile birden fazla evrakı aynı anda tek teslim kaydıyla teslim etme desteği.
- **Durum geçmişi**: Evrakların durum değişiklikleri zaman çizelgesi ile takip ediliyor (Bekliyor → Teslim Edildi → Arşivlendi). Veritabanı v2'ye yükseltildi.
- **Harici yedekleme konumu**: Yedekleme sayfasına harici dizin seçimi eklendi (D:\backup\ gibi). Seçilen konuma yedek alma ve o konumdan geri yükleme desteği.
- **Bulut yedekleme**: Google Drive ve OneDrive entegrasyonu için temel yapı oluşturuldu. Arayüz hazır, OAuth 2.0 akışı yakında eklenecek.

### Değişti
- Veritabanı sürümü 1 → 2'ye yükseltildi (DurumGecmisleri tablosu eklendi).
- Yedekleme sayfası yeniden yapılandırıldı (Dahili, Harici, Bulut bölümleri).

---

## [1.2.0] — 2026-06-24

### Düzeltildi
- **Hızlı arama sonuç güncellenmeme**: Aynı sayfada tekrar arama yapıldığında sonuçlar artık güncelleniyor (dinamik ValueKey ile rebuild).
- **Hızlı arama sonrası temizlik**: Arama yapıldıktan sonra input alanı otomatik temizleniyor.
- **SQL arama hatası**: `addClause` closure kaldırıldı, inline kod ile değiştirildi. Tablo adları doğrudan string olarak yazıldı.
- **ESC tuşu ile geri dönüş**: `CallbackShortcuts` yerine `Focus(autofocus: true, onKeyEvent:)` kullanılarak düzeltildi.
- **EvrakDetay sayfası geri dönüş**: AppBar geri butonu eklendi.
- **Teslim Et sonrası dönüş**: Teslim işleminden sonra otomatik olarak ana sayfaya (liste) dönülüyor.
- **Sil butonu aktif**: Tüm kullanıcılar için aktif, onay dialogu ile çalışıyor.
- **Hızlı arama çoklu alan**: Ad Soyad, Evrak No, Geldiği Kurum, Teslim Alan Kişi, Telefon ve TC Kimlik No alanlarında OR araması yapıyor.
- **Evrak Ara filtreleri**: Teslim Alan, Telefon ve TC Kimlik No filtreleri eklendi, filtre değişikliğinde canlı arama tetikleniyor, filtre temizlenince sonuçlar da temizleniyor.
- **Türkçe karakter arama**: `COLLATE NOCASE` ve `LOWER()` yerine SQL `REPLACE` zincirleri + Dart `toLowerTurkce()` ile İ→i, Ü→ü, Ş→ş, Ö→ö, Ç→ç, Ğ→ğ dönüşümleri yapılıyor.

### Eklendi
- **Muhtarlık bilgileri**: Ayarlar sayfasına Muhtarlık Adı, Muhtar Adı Soyadı, İl ve İlçe alanları eklendi (SharedPreferences ile kayıtlı).
- **Dashboard footer**: Ana sayfada "%muhtarlık-adı% Muhtarlığı" şeklinde silik yazı gösteriliyor.
- **Login ekranı kaldırıldı**: Uygulama doğrudan ana ekrana açılıyor.
- **Kullanıcı bilgi alanı kaldırıldı**: Sağ üstteki kullanıcı simgesi ve çıkış butonu kaldırıldı.

### Değişti
- Hızlı arama alanı menü geçişlerinde otomatik temizleniyor
- Ayarlar sayfasından Hesap bölümü kaldırıldı

---

## [1.1.0] — 2026-06-24

### Düzeltildi
- **"Kayıt bulunamadı" hatası**: `EvrakRepository` LIKE filtrelerinde `null` değerler `%null%` stringine dönüştüğü için hiçbir kayıt eşleşmiyordu. Artık `null`/boş filtreler atlanıyor.
- **Evrak arama çalışmama**: `database.query()` → `database.rawQuery()` ile sqflite_common_ffi parametre sorunu giderildi.
- **TAB sırası**: `HomeShell` ve `EvrakFormPage` `FocusTraversalGroup` ile sarılarak formda ve sayfalar arası geçiş düzeltildi.
- **EvrakListePage durum değişkenliği**: `didUpdateWidget` + `ValueKey` ile sayfalar arası geçişlerde doğru veri yüklenmesi sağlandı.

### Eklendi
- **EvrakDetay sayfası geri dönüş**: AppBar geri butonu + ESC tuşu ile detay sayfasından çıkış desteği.
- **Login ekranı kaldırıldı**: Uygulama doğrudan ana ekrana açılıyor, kimlik doğrulaması gerekmiyor.
- **PDF Türkçe karakter desteği**: Arial fontu gömülü olarak eklendi, tüm PDF metinleri Arial ile oluşturuluyor.
- **Uygulama adı**: "Muhtar Tebligat Takip" olarak değiştirildi (pencere başlığı, EXE bilgileri).
- **Uygulama verisi yolu**: `%appdata%\MuhtarTebligat` konumuna taşındı, eski yoldan otomatik migrasyon.
- **Uygulama ikonu**: Yeni turuncu temalı ikon eklendi (16x16 — 256x256 boyutları).
- **Hata yakalama**: Arama ve liste sayfalarında `_load()` / `_search()` hataları SnackBar ile gösteriliyor.

### Değişti
- Form alanları sırası: Ad Soyad → Geldiği Kurum → Evrak Sayısı → Geliş Tarihi

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
- EXE doğrudan çalıştırma + `flutter run -d windows --release`: uygulama açıldı, çökmedi.
- Git: ilk commit `045eb1d` (`main` dalı).
