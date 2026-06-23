import '../models/teslim_kaydi.dart';
import 'base_repository.dart';

/// Teslim kayıtları repository'si.
class TeslimRepository extends BaseRepository {
  static const String _table = 'TeslimKayitlari';

  Future<TeslimKaydi> insert(TeslimKaydi kayit) async {
    final database = await db;
    final id = await database.insert(_table, kayit.toMap());
    return TeslimKaydi(
      id: id,
      evrakId: kayit.evrakId,
      teslimAlanAdSoyad: kayit.teslimAlanAdSoyad,
      tcKimlikNo: kayit.tcKimlikNo,
      telefon: kayit.telefon,
      teslimTarihi: kayit.teslimTarihi,
      aciklama: kayit.aciklama,
      olusturmaTarihi: kayit.olusturmaTarihi,
    );
  }

  Future<TeslimKaydi?> getLatestForEvrak(int evrakId) async {
    final database = await db;
    final rows = await database.query(
      _table,
      where: 'evrak_id = ?',
      whereArgs: [evrakId],
      orderBy: 'teslim_tarihi DESC, id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TeslimKaydi.fromMap(rows.first);
  }
}
