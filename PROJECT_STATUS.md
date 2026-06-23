# Proje Durumu

> Bu dosya **canlı** bir kontrol panelidir. Her işlemden önce/sonra güncellenir.
> Yapılacaklar, tamamlananlar ve bilinen sorunlar buradan takip edilir.

**Son güncelleme:** 2026-06-23
**Sürüm:** 1.0.0
**Durum:** ✅ Çalışır durumda — Windows release derlemesi üretildi ve açılışı doğrulandı.
**Git:** `045eb1d` — `feat: Muhtarlik Tebligat Takip Sistemi v1.0.0` (ilk commit, `main` dalı)

---

## ✅ Tamamlananlar

### Temel
- [x] Flutter Windows projesi + pubspec bağımlılıkları
- [x] SQLite (`sqflite_common_ffi`) + şema + indeksler + migrasyon çatısı
- [x] Katmanlı mimari + Repository Pattern
- [x] Provider durum yönetimi

### Veri katmanı
- [x] Modeller: Evrak, TeslimKaydi, User, LogEntry
- [x] Repository'ler: Evrak, Teslim, User, Log

### Servis katmanı
- [x] AuthService (giriş, seed admin, kullanıcı CRUD, parola)
- [x] EvrakService (ekle/güncelle/teslim/arsivle/geri al/sil + loglama)
- [x] BackupService (manuel/otomatik/geri yükle/liste)
- [x] ExportService (Excel + PDF)
- [x] ImportService (Excel sihirbazı)
- [x] LogService + SettingsService

### UI
- [x] Tema (açık/koyu/sistem)
- [x] Giriş ekranı
- [x] HomeShell (NavigationRail + hızlı arama + çıkış)
- [x] Dashboard (4 kart)
- [x] Yeni Evrak / Düzenleme formu
- [x] Evrak Arama (canlı filtre + sayfalama + detay)
- [x] Bekleyen / Teslim Edilen / Arşivlenen listeleri
- [x] Evrak Detay + teslim geçmişi + işlemler
- [x] Teslim diyaloğu
- [x] Raporlar (filtreler + Excel/PDF)
- [x] İçe Aktarma sihirbazı
- [x] Yedekleme ekranı
- [x] Ayarlar (tema, parola, kullanıcı yönetimi, log görüntüleyici)

### Doğrulama
- [x] `flutter analyze` — 0 hata
- [x] `flutter build windows --release` — başarılı

### Dokümanlar
- [x] README.md
- [x] ARCHITECTURE.md
- [x] CHANGELOG.md
- [x] PROJECT_STATUS.md (bu dosya)

---

## 🔜 Yapılacaklar / İyileştirmeler

### Öncelik: Orta
- [ ] **Türkçe karakter duyarsız arama** — `LIKE` şu anda `COLLATE NOCASE` kullanıyor ama i/İ, ı/I normalize etmiyor. FTS5 veya ICU collation eklenebilir.
- [ ] **Log arşivleme/temizleme** — loglar sonsuz büyür; otomatik arşiv veya eski log silme politikası.
- [ ] **Rapor grafikleri** — sayısal raporlara görsel grafik (chart) ekleme.

### Öncelik: Düşük
- [ ] Otomatik yedek için zamanlayıcı (şu an sadece girişte tetikleniyor).
- [ ] Excel içe aktarmada kolon eşleme eşleştirme tolereansı (yakın başlık adları).
- [ ] Çoklu kullanıcıda aynı anda düzenleme çakışma kontrolü.
- [ ] Veri aktarımı (backup) için şifreli/ sıkıştırılmış yedek.
- [ ] Klavye kısayolları (F2 düzenle, Del arşivle vb.).

### Test
- [ ] Birim testleri (repository/service katmanı, bellek içi SQLite).
- [ ] Widget testleri (giriş akışı, form doğrulama).
- [ ] Entegrasyon testi (500.000 kayıt ile performans).

---

## 🐞 Bilinen Sorunlar / Sınırlamalar

1. **Windows Geliştirici Modu**: Plugin derlemesi symlink gerektirir; Geliştirici Modu kapalıyken `flutter build windows` başarısız olur. (Çözüm: `ms-settings:developers` → açık.)
2. **Arama Türkçe karakter**: bkz. Yapılacaklar.
3. **Ağ/çoklu kullanıcı**: Aynı DB dosyasını paylaşan lokal kullanıcılar desteklenir; ağ üzerinden eşzamanlı erişim/senkronizasyon **yok**.
4. `withOpacity` deprecated uyarıları (Flutter 3.41+) — `withValues()`'e geçilebilir (kozmetik).

---

## 📊 Sağlık Kontrolleri

| Kontrol | Sonuç | Tarih |
|---|---|---|
| `flutter analyze` | ✅ 0 hata (8 info/uyarı) | 2026-06-23 |
| `flutter build windows --release` | ✅ Başarılı | 2026-06-23 |
| EXE üretildi | ✅ `build\windows\x64\runner\Release\muhtar_tebligat_takip.exe` | 2026-06-23 |
| EXE doğrudan çalıştırma | ✅ Çökmedi, ayakta kaldı | 2026-06-23 |
| `flutter run -d windows --release` | ✅ Uygulama açıldı (main/DB/seed admin/ekran) | 2026-06-23 |
| İlk giriş (admin/admin) | ✅ Seed admin oluşturuluyor | 2026-06-23 |
| Git ilk commit | ✅ `045eb1d` (main) | 2026-06-23 |

---

## 📁 Önemli Dosya Haritası

| Dosya | Açıklama |
|---|---|
| `Prompt.md` | Orijinal gereksinimler |
| `README.md` | Proje özeti + kurulum |
| `ARCHITECTURE.md` | Mimari + şema |
| `CHANGELOG.md` | Sürüm geçmişi |
| `PROJECT_STATUS.md` | Bu dosya — canlı durum |
| `lib/main.dart` | Giriş noktası |
| `lib/services/log_service.dart` | `Services` lokatoru + log |
| `lib/data/database/database_helper.dart` | SQLite şema/migrasyon |
| `lib/ui/shell/home_shell.dart` | Ana menü iskeleti |
