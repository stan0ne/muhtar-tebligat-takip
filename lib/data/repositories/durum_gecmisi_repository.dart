import '../models/durum_gecmisi.dart';
import 'base_repository.dart';

/// Durum değişikliği geçmişi repository'si.
class DurumGecmisiRepository extends BaseRepository {
  static const String _table = 'DurumGecmisleri';

  Future<int> insert(DurumGecmisi entry) async {
    final database = await db;
    return database.insert(_table, entry.toMap());
  }

  /// Bir evrakın tüm durum değişikliklerini getir (en yeniden en eskiye).
  Future<List<DurumGecmisi>> listForEvrak(int evrakId) async {
    final database = await db;
    final rows = await database.query(
      _table,
      where: 'evrak_id = ?',
      whereArgs: [evrakId],
      orderBy: 'degisiklik_tarihi DESC, id DESC',
    );
    return rows.map(DurumGecmisi.fromMap).toList();
  }
}
