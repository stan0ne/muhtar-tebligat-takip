/// Uygulama genelinde kullanılan sabitler.
class AppConstants {
  AppConstants._();

  static const String appName = 'Muhtarlık Tebligat Takip Sistemi';
  static const String appVersion = '1.5.4';

  /// Veritabanı dosya adı.
  static const String dbName = 'tebligat.db';

  /// Mevcut şema sürümü.
  static const int dbVersion = 2;

  /// Sayfalama için varsayılan sayfa boyutu.
  static const int defaultPageSize = 50;

  /// Otomatik yedekleme anahtarı (SharedPreferences).
  static const String prefAutoBackup = 'auto_backup';
  static const String prefThemeMode = 'theme_mode';
  static const String prefLastBackup = 'last_backup';
  static const String prefRememberUser = 'remember_user';
  static const String prefAutoArchive = 'auto_archive';
  static const String prefAutoArchiveMonths = 'auto_archive_months';
  static const String prefAutoArchivePrevYears = 'auto_archive_prev_years';
  static const String prefAutoArchiveLastRun = 'auto_archive_last_run';
}

/// Evrak durumları.
class EvrakDurum {
  EvrakDurum._();

  static const String bekliyor = 'Bekliyor';
  static const String teslimEdildi = 'Teslim Edildi';
  static const String arsivlendi = 'Arşivlendi';

  static const List<String> all = [bekliyor, teslimEdildi, arsivlendi];
}

/// Kullanıcı rolleri.
class UserRole {
  UserRole._();

  static const String yonetici = 'Yönetici';
  static const String personel = 'Personel';

  static const List<String> all = [yonetici, personel];
}

/// Log işlem tipleri.
class LogIslem {
  LogIslem._();

  static const String evrakEkleme = 'Evrak Ekleme';
  static const String evrakGuncelleme = 'Evrak Güncelleme';
  static const String evrakTeslim = 'Evrak Teslim Etme';
  static const String evrakArsivleme = 'Evrak Arşivleme';
  static const String evrakGeriAlma = 'Evrak Geri Alma';
  static const String evrakSilme = 'Evrak Silme';
  static const String kullaniciGiris = 'Kullanıcı Girişi';
  static const String kullaniciCikis = 'Kullanıcı Çıkışı';
  static const String yedekleme = 'Yedekleme';
  static const String geriYukleme = 'Geri Yükleme';
  static const String iceAktarma = 'İçe Aktarma';
}
