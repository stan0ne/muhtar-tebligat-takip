import '../models/log_entry.dart';
import 'base_repository.dart';

/// Log repository'si.
class LogRepository extends BaseRepository {
  static const String _table = 'Loglar';

  Future<int> insert(LogEntry entry) async {
    final database = await db;
    return database.insert(_table, entry.toMap());
  }

  /// Sayfalı log listesi (en yeni önce).
  Future<List<LogEntry>> list({
    int limit = 200,
    int offset = 0,
  }) async {
    final database = await db;
    final rows = await database.query(
      _table,
      orderBy: 'tarih DESC, id DESC',
      limit: limit,
      offset: offset < 0 ? 0 : offset,
    );
    return rows.map(LogEntry.fromMap).toList();
  }

  Future<int> count() async {
    final database = await db;
    final rows = await database.rawQuery('SELECT COUNT(*) AS c FROM $_table');
    return (rows.first['c'] as int?) ?? 0;
  }

  /// Belirli tarihten eski logları sil.
  Future<int> deleteOlderThan(String tarih) async {
    final database = await db;
    return database.delete(_table, where: 'tarih < ?', whereArgs: [tarih]);
  }

  /// Tüm logları sil.
  Future<int> deleteAll() async {
    final database = await db;
    return database.delete(_table);
  }

  /// En eski log tarihini getir.
  Future<String?> getOldestDate() async {
    final database = await db;
    final rows = await database.rawQuery('SELECT MIN(tarih) AS t FROM $_table');
    return rows.first['t'] as String?;
  }
}
