import '../core/constants.dart';
import '../core/date_util.dart';
import '../data/models/user.dart';
import '../data/repositories/user_repository.dart';
import 'crypto_util.dart';
import 'log_service.dart';

/// Kimlik doğrulama ve kullanıcı yönetimi servisi.
class AuthService {
  final UserRepository _repo = UserRepository();
  User? _current;

  User? get currentUser => _current;
  bool get isLoggedIn => _current != null;

  /// İlk çalıştırmada varsayılan yönetici oluşturur.
  Future<void> ensureSeedAdmin() async {
    final count = await _repo.count();
    if (count > 0) return;
    final now = DateUtil.nowIso();
    final admin = User(
      kullaniciAdi: 'admin',
      sifreHash: CryptoUtil.hash('admin'),
      rol: UserRole.yonetici,
      adSoyad: 'Sistem Yöneticisi',
      olusturmaTarihi: now,
      guncellemeTarihi: now,
    );
    await _repo.insert(admin);
  }

  /// Kullanıcı adı + şifre ile giriş. Başarılıysa currentUser atanır
  /// ve giriş loglanır.
  Future<User?> login(String kullaniciAdi, String sifre) async {
    final user = await _repo.findByKullaniciAdi(kullaniciAdi);
    if (user == null || !user.aktif) return null;
    if (!CryptoUtil.verify(sifre, user.sifreHash)) return null;
    _current = user;
    Services.log.setCurrentUser(user);
    await Services.log.logLogin(user);
    return user;
  }

  Future<void> logout() async {
    if (_current != null) {
      await Services.log.logLogout(_current!);
    }
    _current = null;
    Services.log.setCurrentUser(null);
  }

  Future<User> createUser({
    required String kullaniciAdi,
    required String sifre,
    required String rol,
    String? adSoyad,
  }) async {
    final now = DateUtil.nowIso();
    final user = User(
      kullaniciAdi: kullaniciAdi,
      sifreHash: CryptoUtil.hash(sifre),
      rol: rol,
      adSoyad: adSoyad,
      olusturmaTarihi: now,
      guncellemeTarihi: now,
    );
    return _repo.insert(user);
  }

  Future<int> changePassword(int userId, String yeniSifre) async {
    final user = await _repo.findById(userId);
    if (user == null) return 0;
    final updated = User(
      id: user.id,
      kullaniciAdi: user.kullaniciAdi,
      sifreHash: CryptoUtil.hash(yeniSifre),
      rol: user.rol,
      adSoyad: user.adSoyad,
      aktif: user.aktif,
      olusturmaTarihi: user.olusturmaTarihi,
      guncellemeTarihi: DateUtil.nowIso(),
    );
    return _repo.update(updated);
  }

  Future<List<User>> listUsers() => _repo.all();

  Future<int> updateUser(User user) async {
    final updated = User(
      id: user.id,
      kullaniciAdi: user.kullaniciAdi,
      sifreHash: user.sifreHash,
      rol: user.rol,
      adSoyad: user.adSoyad,
      aktif: user.aktif,
      olusturmaTarihi: user.olusturmaTarihi,
      guncellemeTarihi: DateUtil.nowIso(),
    );
    return _repo.update(updated);
  }
}
