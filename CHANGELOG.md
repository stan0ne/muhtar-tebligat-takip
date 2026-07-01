# Changelog

Bu projedeki tüm önemli değişiklikler bu dosyada kayıt altına alınır.
Format [Keep a Changelog](https://keepachangelog.com/tr/1.1.0/) esas alınır.

## [1.4.0] — 2026-06-26

### Eklendi
- **Otomatik arşivleme**: Ayarlar sayfasından açılıp kapatılabilir. Checkbox açıksa uygulama açılışında otomatik çalışır. Kriter: geliş tarihi bu yılın 1 Ocak'ından önce VE geliş tarihi seçili aydan eski. Ayarlar: ay eşiği (1-12), Geçmiş Yıllar checkbox'ı, son çalışma zamanı, önizleme, "Hemen Çalıştır" butonu.
- **Tarih formatı**: Tüm tarih seçicilerde DD-MM-YYYY formatı (Flutter Türkçe locale desteği eklendi).
- **İçe Aktarma şablonu**: "Boş Şablon İndir" butonu eklendi. Downloads klasörüne kaydedilir.
- **İçe Aktarma akışı**: Dosya seçimi → önizleme → "Veritabanına Aktar" → sonuç dialog'u → ekran sıfırlama.
- **Teslim Edilenler sütunu**: Teslim Edilen Evraklar sayfasında Geliş Tarihi yerine Teslim Tarihi gösterilir.
- **Pencere boyutu**: 1170×900 px.
- **ESC desteği**: Tüm uygulamada ESC tuşu ile geri dönme desteği.
- **Responsive Dashboard**: Kartlar ekran boyutuna göre orantılı ölçeklenir.
- **Windows Installer (MSI)**: WiX v7 ile .msi paketi. Program Files'a kurulum, Program Ekle/Kaldır'da görünür.
- **Windows Installer (EXE)**: Inno Setup 6 ile .exe kurucu. Admin yetkisi ile Program Files'a kurulum.
- **MSIX paketi**: `dart run msix:create` ile modern Windows paketleme.
- **Veritabanı bilgisi**: Ayarlar sayfasında dosya adı, konum, boyut ve şema sürümü gösterilir.
- **Veritabanı Dışa Aktar**: Ayarlar > Veritabanı bölümünden harici konuma veritabanı kopyalanabilir.
- **Hızlı arama sıralaması**: Bekliyor durumundaki evraklar üstte (geliş tarihi en yeni), Teslim Edilenler altta (teslim tarihi en yeni).
- **Bağımlılık güncellemeleri**: flutter_localizations, intl, syncfusion_flutter_xlsio, file_picker, googleapis, googleapis_auth.
- **GitHub Actions CI/CD**: `v*` tag push'unda otomatik build + release.

### Değişti
- Login ekranı kaldırıldı — uygulama doğrudan açılır.
- Kullanıcı bilgi alanı / çıkış butonu kaldırıldı.
- Auth servisleri (AuthService, UserRepository, CryptoUtil) kaldırıldı — artık kullanılmıyor.
- İçe Aktarma menüden kaldırıldı, Ayarlar > Veritabanı altına taşındı.
- **Açık tema iyileştirmesi**: Metin renkleri koyulaştırıldı (#1A1A1A), tüm başlık ve gövde metinleri w500/w700 ağırlığına yükseltildi. NavigationRail menü fontları kalınlaştırıldı.
- **Dashboard kartları**: Başlık ve değer fontları okunur hale getirildi (w500/w700).
- **Evrak listeleri**: Sütun başlıkları koyu arka plan + bold; zebra striping (alternatif satır rengi) eklendi; hücre metinleri w500 ağırlığında.
- Veritabanı v1 → v2 (DurumGecmisleri tablosu eklendi).
- Yedekleme sayfası yeniden yapılandırıldı (Dahili, Harici, Bulut bölümleri).

### Temizlendi
- GEMINI.md, AGENTS.md, PROJECT_STATUS.md, Prompt.md repodan kaldırıldı.
- Auth ile ilgili dosyalar silindi (user.dart, user_repository.dart, auth_service.dart, crypto_util.dart, login_screen.dart, user_dialog.dart).
- Otomatik üretilen dosyalar (.gitignore'a eklendi).

---

## [1.2.0] — 2026-06-24

### Düzeltildi
- **Hızlı arama sonuç güncellenmeme**: Dinamik ValueKey ile rebuild sağlanıyor.
- **Hızlı arama sonrası temizlik**: Input alanı otomatik temizleniyor.
- **SQL arama hatası**: `addClause` closure kaldırıldı, inline kod ile değiştirildi.
- **ESC tuşu ile geri dönüş**: `Focus(autofocus: true, onKeyEvent:)` ile düzeltildi.
- **EvrakDetay sayfası geri dönüş**: AppBar geri butonu eklendi.
- **Teslim Et sonrası dönüş**: Otomatik olarak ana sayfaya dönülüyor.
- **Sil butonu aktif**: Tüm kullanıcılar için aktif, onay dialogu ile çalışıyor.
- **Hızlı arama çoklu alan**: Ad Soyad, Evrak No, Geldiği Kurum, Teslim Alan, Telefon ve TC Kimlik No'da OR araması.
- **Evrak Ara filtreleri**: Teslim Alan, Telefon ve TC Kimlik No filtreleri eklendi.
- **Türkçe karakter arama**: SQL REPLACE zincirleri + Dart `toLowerTurkce()` ile İ→i, Ü→ü, Ş→ş, Ö→ö, Ç→ç, Ğ→ğ dönüşümleri.

### Eklendi
- **Muhtarlık bilgileri**: Ayarlar sayfasına Muhtarlık Adı, Muhtar Adı Soyadı, İl ve İlçe alanları.
- **Dashboard footer**: "%muhtarlık-adı% Muhtarlığı" gösterimi.

---

## [1.1.0] — 2026-06-24

### Düzeltildi
- **"Kayıt bulunamadı" hatası**: `null`/boş filtreler artık atlanıyor.
- **Evrak arama çalışmama**: `database.rawQuery()` ile sqflite_common_ffi parametre sorunu giderildi.
- **TAB sırası**: `FocusTraversalGroup` ile formda ve sayfalar arası geçiş düzeltildi.
- **EvrakListePage durum değişkenliği**: `didUpdateWidget` + `ValueKey` ile doğru veri yüklenmesi.

### Eklendi
- **PDF Türkçe karakter desteği**: Arial fontu gömülü olarak eklendi.
- **Uygulama adı**: "Muhtar Tebligat Takip" olarak değiştirildi.
- **Uygulama ikonu**: Yeni turuncu temalı ikon eklendi.
- **Hata yakalama**: Arama ve liste sayfalarında hatalar SnackBar ile gösteriliyor.

### Değişti
- Form alanları sırası: Ad Soyad → Geldiği Kurum → Evrak Sayısı → Geliş Tarihi

---

## [1.0.0] — 2026-06-23

### Eklendi
- **Proje iskeleti**: Flutter Desktop (Windows) + SQLite (`sqflite_common_ffi`).
- **Katmanlı mimari + Repository Pattern**: `core / data / services / ui` katmanları.
- **Veritabanı**: `Evraklar`, `TeslimKayitlari`, `Loglar`, `Ayarlar` tabloları; indeksler; UTF-8 encoding.
- **Modeller**: `Evrak`, `TeslimKaydi`, `LogEntry`.
- **Servisler**: `EvrakService`, `BackupService`, `ExportService`, `ImportService`, `LogService`, `SettingsService`.
- **UI**: Dashboard, Evrak form/ara/detay/liste, Raporlar, İçe Aktarma, Yedekleme, Ayarlar.
- **Tema**: açık/koyu/sistem desteği.
- **Yumuşak silme**: `silindi_mi`, `silinme_tarihi`.
- **Performans**: indeksler + sayfalama.
