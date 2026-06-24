import '../core/constants.dart';
import '../core/date_util.dart';
import '../data/models/log_entry.dart';
import '../data/models/user.dart';
import '../data/repositories/log_repository.dart';
import 'auth_service.dart';
import 'evrak_service.dart';
import 'backup_service.dart';
import 'export_service.dart';
import 'import_service.dart';
import 'settings_service.dart';

/// Merkezi loglama servisi. Aktif kullanıcı bilgisini tutar ve tüm
/// işlem tiplerini `Loglar` tablosuna yazar.
class LogService {
  final LogRepository _repo;
  User? _currentUser;

  LogService(this._repo);

  void setCurrentUser(User? user) => _currentUser = user;

  User? get currentUser => _currentUser;

  Future<void> log(
    String islem, {
    String? hedefTablo,
    int? hedefId,
    String? aciklama,
  }) async {
    final entry = LogEntry(
      kullaniciId: _currentUser?.id,
      kullaniciAdi: _currentUser?.kullaniciAdi ?? 'Sistem',
      islem: islem,
      hedefTablo: hedefTablo,
      hedefId: hedefId,
      aciklama: aciklama,
      tarih: DateUtil.nowIso(),
    );
    await _repo.insert(entry);
  }

  Future<List<LogEntry>> list({int limit = 200, int offset = 0}) =>
      _repo.list(limit: limit, offset: offset);

  Future<int> count() => _repo.count();

  Future<int> deleteOlderThan(String tarih) => _repo.deleteOlderThan(tarih);

  Future<int> deleteAll() => _repo.deleteAll();

  Future<String?> getOldestDate() => _repo.getOldestDate();

  Future<void> logLogin(User user) => log(LogIslem.kullaniciGiris,
      hedefTablo: 'Kullanicilar', hedefId: user.id, aciklama: user.kullaniciAdi);
  Future<void> logLogout(User user) => log(LogIslem.kullaniciCikis,
      hedefTablo: 'Kullanicilar', hedefId: user.id, aciklama: user.kullaniciAdi);
}

/// Uygulama genelinde tekil servis erişimi.
class Services {
  Services._();

  static late final LogService log;
  static late final AuthService auth;
  static late final EvrakService evrak;
  static late final BackupService backup;
  static late final ExportService export;
  static late final ImportService import;
  static late final SettingsService settings;

  static Future<void> init() async {
    final logRepo = LogRepository();
    log = LogService(logRepo);
    auth = AuthService();
    evrak = EvrakService();
    backup = BackupService();
    export = ExportService();
    import = ImportService();
    settings = SettingsService();

    await auth.ensureSeedAdmin();
    // Giriş öncesi loglar "Sistem" kullanıcısı ile yazılır.
    log.setCurrentUser(null);
  }
}
