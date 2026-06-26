# Mimarî ve Teknik Tasarım

## Genel Yaklaşım

- **Katmanlı mimari**: `data` (erişim) → `services` (iş kuralları) → `ui` (sunum)
- **Repository Pattern**: tüm DB erişimi repository'ler üzerinden, servisler iş mantığını kapsüller
- **Provider** ile durum yönetimi (`AppProvider`: tema, otomatik arşivleme)
- **Servis lokatoru**: `Services` statik sınıfı tüm servisleri tek yerden sunar (`Services.evrak`, `Services.backup`, ...)

## Katmanlar

### 1. `core/`
Sabitler (`AppConstants`, `EvrakDurum`, `LogIslem`) ve yardımcılar (`DateUtil`).

### 2. `data/`
- **`database/database_helper.dart`**: SQLite açma, şema oluşturma, migrasyon, `PRAGMA encoding = "UTF-8"`, `foreign_keys = ON`. Singleton. v2: `DurumGecmisleri` tablosu eklendi.
- **`models/`**: `Evrak`, `TeslimKaydi`, `DurumGecmisi`, `LogEntry` — `fromMap`/`toMap`/`copyWith`.
- **`repositories/`**: `BaseRepository` (DB erişimi) + `EvrakRepository`, `TeslimRepository`, `DurumGecmisiRepository`, `LogRepository`.

### 3. `services/`
İş kuraları + dış dünya entegrasyonları:
- `EvrakService`: ekle/güncelle/teslim et/arsivle/geri al/sil — her işlemi loglar; toplu teslim; otomatik arşivleme
- `BackupService`: yedek al / geri yükle / listele / harici dizin desteği
- `CloudBackupService`: Google Drive / OneDrive skeleton (OAuth 2.0 henüz uygulanmadı)
- `ExportService`: Excel (Syncfusion XlsIO) + PDF (pdf paketi, Arial font) rapor üretimi
- `ImportService`: Excel okuma (excel paketi) → normalize → toplu aktarım; boş şablon oluşturma
- `LogService`: merkezi loglama; arşivleme / temizleme
- `SettingsService`: SharedPreferences anahtar-değer

### 4. `ui/`
- **`theme/`**: `AppTheme.light()` / `AppTheme.dark()`
- **`providers/`**: `AppProvider`
- **`shell/`**: `HomeShell` (NavigationRail + hızlı arama + içerik), `MenuPage` enum
- **`pages/`**: dashboard, evrak form/ara/detay/liste, raporlar, içe aktarma, yedekleme, ayarlar
- **`widgets/`**: `UiUtil` (durum chip, info card — responsive ölçekleme)

## Veritabanı Şeması (v2)

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
| teslim_alan_ad_soyad | TEXT | |
| tc_kimlik_no | TEXT | |
| telefon | TEXT | |
| aciklama | TEXT | |
| olusturma_tarihi | TEXT | ISO tam |
| guncelleme_tarihi | TEXT | ISO tam |
| silindi_mi | INTEGER | 0/1, **indeks** |
| silinme_tarihi | TEXT | |

**İndeksler:** `idx_evrak_ad_soyad`, `idx_evrak_evrak_sayisi`, `idx_evrak_durum`, `idx_evrak_gelis_tarihi`, `idx_evrak_silindi_mi`.

### `TeslimKayitlari`
| Kolon | Tip | Not |
|---|---|---|
| id | INTEGER PK | autoincrement |
| evrak_id | INTEGER FK | → Evraklar |
| teslim_alan_ad_soyad | TEXT | |
| tc_kimlik_no | TEXT | |
| telefon | TEXT | |
| teslim_tarihi | TEXT | |
| aciklama | TEXT | |
| olusturma_tarihi | TEXT | |

İndeks: `idx_teslim_evrak_id`.

### `DurumGecmisleri`
| Kolon | Tip | Not |
|---|---|---|
| id | INTEGER PK | autoincrement |
| evrak_id | INTEGER FK | → Evraklar |
| eski_durum | TEXT | |
| yeni_durum | TEXT | |
| degisiklik_tarihi | TEXT | |

İndeks: `idx_durum_gecmisi_evrak_id`.

### `Loglar`
| Kolon | Tip | Not |
|---|---|---|
| id | INTEGER PK | autoincrement |
| kullanici_id | INTEGER | |
| kullanici_adi | TEXT | |
| islem | TEXT | |
| hedef_tablo | TEXT | |
| hedef_id | INTEGER | |
| aciklama | TEXT | |
| tarih | TEXT | |

İndeksler: `idx_log_tarih`, `idx_log_kullanici_id`.

### `Ayarlar`
`anahtar` (PK), `deger`.

## Migrasyon

`DatabaseHelper` `onCreate` (v1 şeması) ve `onUpgrade` (kademeli migrasyon çatısı) uygular. Sürüm `AppConstants.dbVersion`'dan okunur. v2: `DurumGecmisleri` tablosu eklendi.

## Arama

Türkçe karakter duyarlı arama: SQL'de `REPLACE` zincirleri (İ→i, I→ı, Ş→s, Ü→u, Ö→o, Ç→c, Ğ→g) + Dart tarafında `toLowerTurkice()` yardımcı fonksiyonu. `EXISTS` alt sorguları ile birden fazla kolonda arama yapılır.

## Performans

- Sayfalama: `LIMIT/OFFSET` + toplam sayım ayrı sorgu (`COUNT(*)`).
- 500.000+ kayıt için: indeksler + sayfalama temel önlem.

## Güvenlik

- Uygulama giriş gerektirmez, doğrudan açılır.
- Silme yalnızca yetkili kullanıcılar tarafından yapılabilir.
- Tüm işlemler loglanır (işlem + hedef + zaman).

## Sınırlamalar / Bilinen İyileştirme Alanları

- Bulut yedekleme (Google Drive / OneDrive) henüz uygulanmadı.
- Ağ/senkronizasyon desteği yok.
