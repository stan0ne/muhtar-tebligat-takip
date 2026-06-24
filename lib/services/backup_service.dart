import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/constants.dart';
import '../core/date_util.dart';
import '../data/database/database_helper.dart';
import 'log_service.dart';

/// SQLite veritabanı dosyasını yedekleme/geri yükleme servisi.
class BackupService {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  /// Mevcut db dosyasının bulunduğu dizin (dahili yedekleme).
  Future<Directory> get backupDir async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'backups'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Harici yedekleme konumunu getir (SharedPreferences'dan).
  Future<String?> getExternalPath() async {
    return Services.settings.get('external_backup_path');
  }

  /// Harici yedekleme konumunu kaydet.
  Future<void> setExternalPath(String path) async {
    await Services.settings.set('external_backup_path', path);
  }

  /// Harici konuma yedek al.
  Future<File> backupToExternal() async {
    final externalPath = await getExternalPath();
    if (externalPath == null || externalPath.isEmpty) {
      throw StateError('Harici yedekleme konumu ayarlanmamış');
    }
    final dir = Directory(externalPath);
    if (!dir.existsSync()) dir.createSync(recursive: true);

    await _helper.database;
    final srcPath = await _helper.dbPath;
    final src = File(srcPath);
    if (!src.existsSync()) {
      throw FileSystemException('Veritabanı dosyası bulunamadı', srcPath);
    }
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final dest = File(p.join(dir.path, 'tebligat_yedek_$stamp.db'));
    await src.copy(dest.path);
    await Services.log.log(LogIslem.yedekleme,
        aciklama: 'Harici konum: ${dest.path}');
    return dest;
  }

  /// Harici konumdaki yedekleri listele.
  Future<List<File>> listExternalBackups() async {
    final externalPath = await getExternalPath();
    if (externalPath == null || externalPath.isEmpty) return [];
    final dir = Directory(externalPath);
    if (!dir.existsSync()) return [];
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.db'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  /// Mevcut db dosyasını zaman damgalı kopya olarak yedekler.
  Future<File> backup() async {
    await _helper.database; // açık olduğundan emin ol
    final srcPath = await _helper.dbPath;
    final src = File(srcPath);
    if (!src.existsSync()) {
      throw FileSystemException('Veritabanı dosyası bulunamadı', srcPath);
    }
    final dir = await backupDir;
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final dest = File(p.join(dir.path, 'tebligat_yedek_$stamp.db'));
    await src.copy(dest.path);
    await Services.log.log(LogIslem.yedekleme,
        aciklama: dest.path);
    return dest;
  }

  /// Belirli bir db dosyasından geri yükler.
  /// Mevcut db kapatılır, dosya üzerine kopyalanır, ardından yeniden açılır.
  Future<void> restore(String fromPath) async {
    final src = File(fromPath);
    if (!src.existsSync()) {
      throw FileSystemException('Yedek dosyası bulunamadı', fromPath);
    }
    await _helper.close();
    final destPath = await _helper.dbPath;
    await src.copy(destPath);
    await _helper.database; // yeniden aç + migrasyon
    await Services.log.log(LogIslem.geriYukleme,
        aciklama: fromPath);
  }

  /// Listelenen yedek dosyaları (en yeni önce).
  Future<List<File>> listBackups() async {
    final dir = await backupDir;
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.db'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  /// Otomatik günlük yedek: bugün daha önce yedek alınmadıysa alır.
  Future<void> maybeAutoBackup() async {
    final today = DateUtil.todayIso();
    final last = await Services.settings.get(AppConstants.prefLastBackup);
    if (last == today) return;
    await backup();
    await Services.settings.set(AppConstants.prefLastBackup, today);
  }

  Future<void> deleteBackup(File file) async {
    if (file.existsSync()) await file.delete();
  }
}
