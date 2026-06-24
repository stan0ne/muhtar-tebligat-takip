import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/constants.dart';

/// SQLite veritabanı yöneticisi.
///
/// Windows masaüstünde `sqflite_common_ffi` ile initialize edilir ve
/// tek bir `.db` dosyası üzerinde tüm şema migrasyonlarını çalıştırır.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;
  bool _migrated = false;

  /// Veritabanı dosyasının tam yolu.
  Future<String> get dbPath async {
    final dir = await getApplicationSupportDirectory();
    final newPath = p.join(dir.path, AppConstants.dbName);

    // Eski yoldan yeni yola otomatik göç.
    if (!_migrated) {
      _migrated = true;
      try {
        final oldDir = Directory(p.join(dir.parent.path,
            'com.muhtar', 'muhtar_tebligat_takip'));
        final oldFile = File(p.join(oldDir.path, AppConstants.dbName));
        final newFile = File(newPath);
        if (await oldFile.exists() && !await newFile.exists()) {
          await oldFile.copy(newPath);
        }
      } catch (_) {
        // Eski yol yoksa göç gerekmez, sessizce devam et.
      }
    }

    return newPath;
  }

  /// Veritabanını açar (lazım oluşturur) ve migrasyonları uygular.
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final path = await dbPath;
    _db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppConstants.dbVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
          await db.execute('PRAGMA encoding = "UTF-8";');
        },
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int newVersion) async {
    await _createV1(db);
    // Gelecekteki sürümler için kademeli migrasyonlar buraya eklenecek.
    for (int v = 2; v <= newVersion; v++) {
      // await _migrateToVx(db, v);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (int v = oldVersion + 1; v <= newVersion; v++) {
      await _migrateToVx(db, v);
    }
  }

  Future<void> _migrateToVx(Database db, int version) async {
    switch (version) {
      case 2:
        // DurumGecmisleri tablosu ekle
        await db.execute('''
          CREATE TABLE IF NOT EXISTS DurumGecmisleri (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            evrak_id INTEGER NOT NULL,
            eski_durum TEXT,
            yeni_durum TEXT NOT NULL,
            degisiklik_tarihi TEXT NOT NULL,
            aciklama TEXT,
            FOREIGN KEY (evrak_id) REFERENCES Evraklar(id) ON DELETE RESTRICT
          )
        ''');
        await db.execute(
            "CREATE INDEX IF NOT EXISTS idx_durum_gecmisi_evrak_id ON DurumGecmisleri(evrak_id);");
        break;
    }
  }

  Future<void> _createV1(Database db) async {
    // --- Kullanicilar ---
    await db.execute('''
      CREATE TABLE Kullanicilar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kullanici_adi TEXT NOT NULL UNIQUE,
        sifre_hash TEXT NOT NULL,
        rol TEXT NOT NULL,
        ad_soyad TEXT,
        aktif INTEGER NOT NULL DEFAULT 1,
        olusturma_tarihi TEXT NOT NULL,
        guncelleme_tarihi TEXT NOT NULL
      )
    ''');

    // --- Evraklar ---
    await db.execute('''
      CREATE TABLE Evraklar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gelis_tarihi TEXT NOT NULL,
        ad_soyad TEXT NOT NULL,
        geldigi_kurum TEXT,
        evrak_sayisi TEXT,
        durum TEXT NOT NULL DEFAULT 'Bekliyor',
        teslim_tarihi TEXT,
        olusturma_tarihi TEXT NOT NULL,
        guncelleme_tarihi TEXT NOT NULL,
        silindi_mi INTEGER NOT NULL DEFAULT 0,
        silinme_tarihi TEXT
      )
    ''');

    // Performans: indeksler
    await db.execute(
        "CREATE INDEX idx_evrak_ad_soyad ON Evraklar(ad_soyad);");
    await db.execute(
        "CREATE INDEX idx_evrak_evrak_sayisi ON Evraklar(evrak_sayisi);");
    await db.execute("CREATE INDEX idx_evrak_durum ON Evraklar(durum);");
    await db.execute(
        "CREATE INDEX idx_evrak_gelis_tarihi ON Evraklar(gelis_tarihi);");
    await db.execute(
        "CREATE INDEX idx_evrak_silindi_mi ON Evraklar(silindi_mi);");

    // --- TeslimKayitlari ---
    await db.execute('''
      CREATE TABLE TeslimKayitlari (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        evrak_id INTEGER NOT NULL,
        teslim_alan_ad_soyad TEXT NOT NULL,
        tc_kimlik_no TEXT,
        telefon TEXT,
        teslim_tarihi TEXT NOT NULL,
        aciklama TEXT,
        olusturma_tarihi TEXT NOT NULL,
        FOREIGN KEY (evrak_id) REFERENCES Evraklar(id) ON DELETE RESTRICT
      )
    ''');
    await db.execute(
        "CREATE INDEX idx_teslim_evrak_id ON TeslimKayitlari(evrak_id);");

    // --- Loglar ---
    await db.execute('''
      CREATE TABLE Loglar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kullanici_id INTEGER,
        kullanici_adi TEXT,
        islem TEXT NOT NULL,
        hedef_tablo TEXT,
        hedef_id INTEGER,
        aciklama TEXT,
        tarih TEXT NOT NULL
      )
    ''');
    await db.execute(
        "CREATE INDEX idx_log_tarih ON Loglar(tarih);");
    await db.execute(
        "CREATE INDEX idx_log_kullanici_id ON Loglar(kullanici_id);");

    // --- Ayarlar ---
    await db.execute('''
      CREATE TABLE Ayarlar (
        anahtar TEXT PRIMARY KEY,
        deger TEXT
      )
    ''');

    // --- DurumGecmisleri ---
    await db.execute('''
      CREATE TABLE DurumGecmisleri (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        evrak_id INTEGER NOT NULL,
        eski_durum TEXT,
        yeni_durum TEXT NOT NULL,
        degisiklik_tarihi TEXT NOT NULL,
        aciklama TEXT,
        FOREIGN KEY (evrak_id) REFERENCES Evraklar(id) ON DELETE RESTRICT
      )
    ''');
    await db.execute(
        "CREATE INDEX idx_durum_gecmisi_evrak_id ON DurumGecmisleri(evrak_id);");
  }

  /// Veritabanını kapatır.
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
