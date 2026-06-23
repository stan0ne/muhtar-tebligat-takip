import '../models/user.dart';
import 'base_repository.dart';

/// Kullanıcı repository'si.
class UserRepository extends BaseRepository {
  static const String _table = 'Kullanicilar';

  Future<User?> findByKullaniciAdi(String adi) async {
    final database = await db;
    final rows = await database.query(
      _table,
      where: 'kullanici_adi = ? COLLATE NOCASE',
      whereArgs: [adi],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  Future<User?> findById(int id) async {
    final database = await db;
    final rows = await database.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  Future<User> insert(User user) async {
    final database = await db;
    final id = await database.insert(_table, user.toMap());
    return User(
      id: id,
      kullaniciAdi: user.kullaniciAdi,
      sifreHash: user.sifreHash,
      rol: user.rol,
      adSoyad: user.adSoyad,
      aktif: user.aktif,
      olusturmaTarihi: user.olusturmaTarihi,
      guncellemeTarihi: user.guncellemeTarihi,
    );
  }

  Future<int> update(User user) async {
    final database = await db;
    return database.update(_table, user.toMap(),
        where: 'id = ?', whereArgs: [user.id]);
  }

  Future<List<User>> all() async {
    final database = await db;
    final rows = await database.query(_table, orderBy: 'id ASC');
    return rows.map(User.fromMap).toList();
  }

  Future<int> count() async {
    final database = await db;
    final rows = await database.rawQuery('SELECT COUNT(*) AS c FROM $_table');
    return (rows.first['c'] as int?) ?? 0;
  }
}
