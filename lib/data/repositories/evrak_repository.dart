import '../models/evrak.dart';
import '../models/teslim_kaydi.dart';
import 'base_repository.dart';
import '../../core/constants.dart';

/// Arama filtresi.
class EvrakFilter {
  final String? adSoyad;
  final String? evrakSayisi;
  final String? geldigiKurum;
  final String? durum;
  final String? tarihBaslangic; // yyyy-MM-dd dahil
  final String? tarihBitis; // yyyy-MM-dd dahil
  final String? hizliArama; // çoklu alan araması (evrak + teslim alan)
  final String? teslimAlan; // teslim alan kişi adı
  final String? telefon; // teslim alan telefon
  final String? tcKimlikNo; // teslim alan TC kimlik no
  final bool includeDeleted;

  const EvrakFilter({
    this.adSoyad,
    this.evrakSayisi,
    this.geldigiKurum,
    this.durum,
    this.tarihBaslangic,
    this.tarihBitis,
    this.hizliArama,
    this.teslimAlan,
    this.telefon,
    this.tcKimlikNo,
    this.includeDeleted = false,
  });

  bool get isEmpty =>
      (adSoyad == null || adSoyad!.isEmpty) &&
      (evrakSayisi == null || evrakSayisi!.isEmpty) &&
      (geldigiKurum == null || geldigiKurum!.isEmpty) &&
      (durum == null || durum!.isEmpty) &&
      (tarihBaslangic == null || tarihBaslangic!.isEmpty) &&
      (tarihBitis == null || tarihBitis!.isEmpty) &&
      (hizliArama == null || hizliArama!.isEmpty) &&
      (teslimAlan == null || teslimAlan!.isEmpty) &&
      (telefon == null || telefon!.isEmpty) &&
      (tcKimlikNo == null || tcKimlikNo!.isEmpty);

  EvrakFilter copyWith({
    String? adSoyad,
    String? evrakSayisi,
    String? geldigiKurum,
    String? durum,
    String? tarihBaslangic,
    String? tarihBitis,
    bool? includeDeleted,
  }) =>
      EvrakFilter(
        adSoyad: adSoyad ?? this.adSoyad,
        evrakSayisi: evrakSayisi ?? this.evrakSayisi,
        geldigiKurum: geldigiKurum ?? this.geldigiKurum,
        durum: durum ?? this.durum,
        tarihBaslangic: tarihBaslangic ?? this.tarihBaslangic,
        tarihBitis: tarihBitis ?? this.tarihBitis,
        includeDeleted: includeDeleted ?? this.includeDeleted,
      );
}

/// Sayfalı sonuç.
class PagedResult<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;

  PagedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  int get totalPages => pageSize <= 0 ? 1 : ((total + pageSize - 1) ~/ pageSize);
}

/// Evrak repository'si.
class EvrakRepository extends BaseRepository {
  static const String _table = 'Evraklar';

  /// Yeni evrak ekler (id ataması ile birlikte döner).
  Future<Evrak> insert(Evrak evrak) async {
    final database = await db;
    final id = await database.insert(_table, evrak.toMap());
    return evrak.copyWith(id: id);
  }

  /// ID'ye göre getir (silinenler hariç).
  Future<Evrak?> getById(int id, {bool includeDeleted = false}) async {
    final database = await db;
    final where =
        'id = ? ${includeDeleted ? '' : "AND silindi_mi = 0"}';
    final rows = await database.query(_table, where: where, whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Evrak.fromMap(rows.first);
  }

  /// Günceller.
  Future<int> update(Evrak evrak) async {
    final database = await db;
    return database.update(_table, evrak.toMap(),
        where: 'id = ?', whereArgs: [evrak.id]);
  }

  /// Filtre + sayfalama ile arama. Toplam sayıyı da döndürür.
  Future<PagedResult<Evrak>> search({
    EvrakFilter filter = const EvrakFilter(),
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    final database = await db;
    final where = StringBuffer();
    final args = <Object?>[];

    if (!filter.includeDeleted) {
      where.write('silindi_mi = 0');
    }

    bool hasVal(String? s) => s != null && s.isNotEmpty;

    // SQLite LOWER() Turkce karakterleri (İ, Ü, Ş, Ö, Ç, Ğ) kucultmez.
    // SQL tarafinda REPLACE ile, Dart tarafinda toLowerTurkce ile cozuyoruz.
    String toLowerTurkce(String s) => s
        .replaceAll('İ', 'i')
        .replaceAll('Ü', 'ü')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ç', 'ç')
        .replaceAll('Ğ', 'ğ')
        .toLowerCase();

    // SQL icin: kolon adini Turkce kucultme ile sarmaliyoruz.
    String tl(String col) =>
        "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE($col,"
        "'İ','i'),'Ü','ü'),'Ş','ş'),'Ö','ö'),'Ç','ç'),'Ğ','ğ')";

    if (hasVal(filter.adSoyad)) {
      if (where.isNotEmpty) where.write(' AND ');
      where.write('${tl("ad_soyad")} LIKE ?');
      args.add('%${toLowerTurkce(filter.adSoyad!)}%');
    }
    if (hasVal(filter.evrakSayisi)) {
      if (where.isNotEmpty) where.write(' AND ');
      where.write('${tl("evrak_sayisi")} LIKE ?');
      args.add('%${toLowerTurkce(filter.evrakSayisi!)}%');
    }
    if (hasVal(filter.geldigiKurum)) {
      if (where.isNotEmpty) where.write(' AND ');
      where.write('${tl("geldigi_kurum")} LIKE ?');
      args.add('%${toLowerTurkce(filter.geldigiKurum!)}%');
    }
    if (hasVal(filter.teslimAlan)) {
      if (where.isNotEmpty) where.write(' AND ');
      where.write(
        "EXISTS (SELECT 1 FROM TeslimKayitlari t WHERE t.evrak_id = Evraklar.id"
        " AND ${tl("t.teslim_alan_ad_soyad")} LIKE ?)",
      );
      args.add('%${toLowerTurkce(filter.teslimAlan!)}%');
    }
    if (hasVal(filter.telefon)) {
      if (where.isNotEmpty) where.write(' AND ');
      where.write(
        "EXISTS (SELECT 1 FROM TeslimKayitlari t WHERE t.evrak_id = Evraklar.id"
        " AND ${tl("t.telefon")} LIKE ?)",
      );
      args.add('%${toLowerTurkce(filter.telefon!)}%');
    }
    if (hasVal(filter.tcKimlikNo)) {
      if (where.isNotEmpty) where.write(' AND ');
      where.write(
        "EXISTS (SELECT 1 FROM TeslimKayitlari t WHERE t.evrak_id = Evraklar.id"
        " AND t.tc_kimlik_no LIKE ?)",
      );
      args.add('%${filter.tcKimlikNo!}%');
    }
    if (hasVal(filter.hizliArama)) {
      final q = '%${toLowerTurkce(filter.hizliArama!)}%';
      final qRaw = '%${filter.hizliArama!}%';
      if (where.isNotEmpty) where.write(' AND ');
      where.write('('
          '${tl("ad_soyad")} LIKE ?'
          ' OR ${tl("evrak_sayisi")} LIKE ?'
          ' OR ${tl("geldigi_kurum")} LIKE ?'
          ' OR EXISTS (SELECT 1 FROM TeslimKayitlari t WHERE t.evrak_id = Evraklar.id'
          '   AND (${tl("t.teslim_alan_ad_soyad")} LIKE ?'
          '        OR ${tl("t.telefon")} LIKE ?'
          '        OR t.tc_kimlik_no LIKE ?))'
          ')');
      args.addAll([q, q, q, q, q, qRaw]);
    }
    if (hasVal(filter.durum)) {
      if (where.isNotEmpty) where.write(' AND ');
      where.write('durum = ?');
      args.add(filter.durum);
    }
    if (hasVal(filter.tarihBaslangic)) {
      if (where.isNotEmpty) where.write(' AND ');
      where.write('gelis_tarihi >= ?');
      args.add(filter.tarihBaslangic);
    }
    if (hasVal(filter.tarihBitis)) {
      if (where.isNotEmpty) where.write(' AND ');
      where.write('gelis_tarihi < ?');
      args.add('${filter.tarihBitis} 23:59:59');
    }

    final whereStr = where.toString();
    final offset = (page - 1) * pageSize;
    final effectiveOffset = offset < 0 ? 0 : offset;

    final whereClause = whereStr.isEmpty ? '' : ' WHERE $whereStr';
    final countSql = 'SELECT COUNT(*) AS c FROM Evraklar$whereClause';
    final dataSql = 'SELECT * FROM Evraklar$whereClause'
        ' ORDER BY olusturma_tarihi DESC, id DESC'
        ' LIMIT $pageSize OFFSET $effectiveOffset';

    final dynamicParams = args.isEmpty ? null : args;
    final countRows = await database.rawQuery(countSql, dynamicParams);
    final total = (countRows.first['c'] as int?) ?? 0;

    final rows = await database.rawQuery(dataSql, dynamicParams);

    final items = rows.map(Evrak.fromMap).toList();
    return PagedResult(items: items, total: total, page: page, pageSize: pageSize);
  }

  /// Belirli bir durumdaki evrakları sayfalı listeler.
  Future<PagedResult<Evrak>> listByDurum(String durum,
      {int page = 1, int pageSize = AppConstants.defaultPageSize}) {
    return search(
      filter: EvrakFilter(durum: durum),
      page: page,
      pageSize: pageSize,
    );
  }

  /// Durum günceller (arsivleme, geri alma, teslim).
  Future<int> setDurum(int id, String durum, {String? teslimTarihi}) async {
    final existing = await getById(id, includeDeleted: true);
    if (existing == null) return 0;
    final updated = existing.copyWith(
      durum: durum,
      teslimTarihi: teslimTarihi ?? existing.teslimTarihi,
      guncellemeTarihi: DateTime.now().toIso8601String(),
    );
    return update(updated);
  }

  /// Birden fazla evrakı ID ile getir.
  Future<List<Evrak>> getByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final database = await db;
    final placeholders = ids.map((_) => '?').join(',');
    final rows = await database.query(
      _table,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    return rows.map(Evrak.fromMap).toList();
  }

  /// Toplu durum güncelleme (transaction içinde).
  Future<void> setDurumToplu(List<int> ids, String durum, {String? teslimTarihi}) async {
    if (ids.isEmpty) return;
    final database = await db;
    final now = DateTime.now().toIso8601String();
    await database.transaction((txn) async {
      for (final id in ids) {
        final existing = await getById(id, includeDeleted: true);
        if (existing == null) continue;
        final updated = existing.copyWith(
          durum: durum,
          teslimTarihi: teslimTarihi ?? existing.teslimTarihi,
          guncellemeTarihi: now,
        );
        await txn.update(_table, updated.toMap(), where: 'id = ?', whereArgs: [id]);
      }
    });
  }

  /// Yumuşak silme (silindi_mi = 1).
  Future<int> softDelete(int id) async {
    final existing = await getById(id, includeDeleted: true);
    if (existing == null) return 0;
    final now = DateTime.now().toIso8601String();
    final updated = existing.copyWith(
      silindiMi: 1,
      silinmeTarihi: now,
      guncellemeTarihi: now,
    );
    return update(updated);
  }

  /// Durum sayımları (dashboard/raporlar için).
  Future<Map<String, int>> durumCounts() async {
    final database = await db;
    final rows = await database.rawQuery(
      'SELECT durum, COUNT(*) AS c FROM $_table WHERE silindi_mi = 0 GROUP BY durum',
    );
    final map = <String, int>{};
    for (final r in rows) {
      map[(r['durum'] as String?) ?? ''] = (r['c'] as int?) ?? 0;
    }
    return map;
  }

  /// Toplam (silinmemiş) kayıt.
  Future<int> totalCount() async {
    final database = await db;
    final rows = await database.rawQuery(
      'SELECT COUNT(*) AS c FROM $_table WHERE silindi_mi = 0',
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  /// Tarih aralığına göre durum sayımları (raporlar).
  Future<Map<String, int>> durumCountsInRange(String bas, String son) async {
    final database = await db;
    final rows = await database.rawQuery(
      'SELECT durum, COUNT(*) AS c FROM $_table '
      'WHERE silindi_mi = 0 AND gelis_tarihi >= ? AND gelis_tarihi <= ? '
      'GROUP BY durum',
      [bas, son],
    );
    final map = <String, int>{
      EvrakDurum.bekliyor: 0,
      EvrakDurum.teslimEdildi: 0,
      EvrakDurum.arsivlendi: 0,
    };
    for (final r in rows) {
      map[(r['durum'] as String?) ?? ''] = (r['c'] as int?) ?? 0;
    }
    return map;
  }

  /// Tarih aralığındaki tüm evraklar (rapor çıktıları için, sayfalama yok).
  Future<List<Evrak>> listInRange(String bas, String son) async {
    final database = await db;
    final rows = await database.query(
      _table,
      where: 'silindi_mi = 0 AND gelis_tarihi >= ? AND gelis_tarihi <= ?',
      whereArgs: [bas, son],
      orderBy: 'gelis_tarihi DESC, id DESC',
    );
    return rows.map(Evrak.fromMap).toList();
  }

  /// Bir evrakın teslim kayıtlarını getir (en yeni önce).
  Future<List<TeslimKaydi>> teslimKayitlari(int evrakId) async {
    final database = await db;
    final rows = await database.query(
      'TeslimKayitlari',
      where: 'evrak_id = ?',
      whereArgs: [evrakId],
      orderBy: 'teslim_tarihi DESC, id DESC',
    );
    return rows.map(TeslimKaydi.fromMap).toList();
  }
}
