# Mimarî ve Teknik Tasarım

## Genel Yaklaşım

- **Katmanlı mimari**: `data` (erişim) → `services` (iş kuralları) → `ui` (sunum)
- **Repository Pattern**: tüm DB erişimi repository'ler üzerinden, servisler iş mantığını kapsüller
- **Provider** ile durum yönetimi (`AppProvider`: auth, tema, otomatik yedek)
- **Servis lokatoru**: `Services` statik sınıfı tüm servisleri tek yerden sunar (`Services.evrak`, `Services.auth`, ...)

## Katmanlar

### 1. `core/`
Sabitler (`AppConstants`, `EvrakDurum`, `UserRole`, `LogIslem`) ve yardımcılar (`DateUtil`).

### 2. `data/`
- **`database/database_helper.dart`**: SQLite açma, şema oluşturma, migrasyon, `PRAGMA encoding = "UTF-8"`, `foreign_keys = ON`. Singleton.
- **`models/`**: `Evrak`, `TeslimKaydi`, `User`, `LogEntry` — `fromMap`/`toMap`/`copyWith`.
- **`repositories/`**: `BaseRepository` (DB erişimi) + `EvrakRepository`, `TeslimRepository`, `UserRepository`, `LogRepository`.

### 3. `services/`
İş kuraları + dış dünya entegrasyonları:
- `AuthService`: giriş, seed admin, kullanıcı CRUD, parola değiştirme (SHA-256 + tuz)
- `EvrakService`: ekle/güncelle/teslim et/arsivle/geri al/sil — her işlemi loglar
- `BackupService`: yedek al / geri yükle / listele / otomatik günlük yedek
- `ExportService`: Excel (Syncfusion XlsIO) + PDF (pdf paketi) rapor üretimi
- `ImportService`: Excel okuma (excel paketi) → normalize → toplu aktarım
- `LogService`: merkezi loglama, aktif kullanıcı takibi
- `SettingsService`: SharedPreferences anahtar-değer
- `CryptoUtil`: şifre hashleme

### 4. `ui/`
- `theme/`: `AppTheme.light()` / `AppTheme.dark()`
- `providers/`: `AppProvider`
- `auth/`: `LoginScreen`
- `shell/`: `HomeShell` (NavigationRail + hızlı arama + içerik), `MenuPage` enum
- `pages/`: dashboard, evrak form/ara/detay/liste, raporlar, içe aktarma, yedekleme, ayarlar
- `widgets/`: `UiUtil` (durum chip, info card)

## Veritabanı Şeması

### `Evraklar`
| Kolon | Tip | Not |
|---|---|---|
| id | INTEGER PK | autoincrement |
| gelis_tarihi | TEXT | yyyy-MM-dd |
| ad_soyad | TEXT | **indeks** |
| geldigi_kurum | TEXT | |
| evrak_sayisi | TEXT | **indeks** |
| durum | TEXT | **indeks** (Bekliyor/Teslim Edildi/Arşivlendi) |
| teslim_tarihi | TEXT | |
| olusturma_tarihi | TEXT | ISO tam |
| guncelleme_tarihi | TEXT | ISO tam |
| silindi_mi | INTEGER | 0/1, **indeks** |
| silinme_tarihi | TEXT | |

**İndeksler:** `idx_evrak_ad_soyad`, `idx_evrak_evrak_sayisi`, `idx_evrak_durum`, `idx_evrak_gelis_tarihi`, `idx_evrak_silindi_mi`.

### `TeslimKayitlari`
`id`, `evrak_id` (FK → Evraklar), `teslim_alan_ad_soyad`, `tc_kimlik_no`, `telefon`, `teslim_tarihi`, `aciklama`, `olusturma_tarihi`. İndeks: `idx_teslim_evrak_id`.

### `Kullanicilar`
`id`, `kullanici_adi` (UNIQUE), `sifre_hash`, `rol`, `ad_soyad`, `aktif`, `olusturma_tarihi`, `guncelleme_tarihi`.

### `Loglar`
`id`, `kullanici_id`, `kullanici_adi`, `islem`, `hedef_tablo`, `hedef_id`, `aciklama`, `tarih`. İndeksler: `idx_log_tarih`, `idx_log_kullanici_id`.

### `Ayarlar`
`anahtar` (PK), `deger`.

## Migrasyon

`DatabaseHelper` `onCreate` (v1 şeması) ve `onUpgrade` (kademeli migrasyon çatısı) uygular. Sürüm `AppConstants.dbVersion`'dan okunur. Gelecekteki sürümler `_migrateToVx` fonksiyonları ile eklenir.

## Performans

- Sayfalama: `LIMIT/OFFSET` + toplam sayım ayrı sorgu (`COUNT(*)`).
- Filtreler `LIKE ... COLLATE NOCASE` (Türkçe karakter duyarsız değil — sınırlama, bkz. PROJECT_STATUS).
- 500.000+ kayıt için: indeksler + sayfalama temel önlem; büyük veri için ilave optimizasyonlar planlanmadı.

## Güvenlik

- Şifreler SHA-256 + sabit tuz ile hashlenir (`CryptoUtil`).
- Silme yalnızca Yönetici rolüne açık.
- Tüm işlemler loglanır (kullanıcı + hedef + zaman).

## Sınırlamalar / Bilinen İyileştirme Alanları

- `LIKE` arama Türkçe karakter normalize etmez (örn. i/İ, ı/I). FTS5 veya ICU collation eklenebilir.
- Otomatik yedek yalnızca girişte tetiklenir (zamanlayıcı değil).
- Loglar sonsuz büyür — arşivleme/temizleme yok.
- Çoklu kullanıcı = aynı DB dosyasını paylaşan lokal kullanıcılar (ağ/senkronizasyon yok).
