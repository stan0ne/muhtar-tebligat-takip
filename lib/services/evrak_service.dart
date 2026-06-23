import '../core/constants.dart';
import '../core/date_util.dart';
import '../data/models/evrak.dart';
import '../data/models/teslim_kaydi.dart';
import '../data/repositories/evrak_repository.dart';
import '../data/repositories/teslim_repository.dart';
import 'log_service.dart';

/// Evrak iş kuraları servisi: ekleme, teslim, arşivleme, geri alma,
/// silme ve raporlama akışlarını yönetir. Tüm işlem loglanır.
class EvrakService {
  final EvrakRepository _repo = EvrakRepository();
  final TeslimRepository _teslimRepo = TeslimRepository();

  Future<Evrak> ekle({
    required String gelisTarihi,
    required String adSoyad,
    String? geldigiKurum,
    String? evrakSayisi,
  }) async {
    final now = DateUtil.nowIso();
    final evrak = Evrak(
      gelisTarihi: gelisTarihi,
      adSoyad: adSoyad.trim(),
      geldigiKurum: geldigiKurum?.trim().isEmpty == true ? null : geldigiKurum?.trim(),
      evrakSayisi: evrakSayisi?.trim().isEmpty == true ? null : evrakSayisi?.trim(),
      durum: EvrakDurum.bekliyor,
      olusturmaTarihi: now,
      guncellemeTarihi: now,
    );
    final created = await _repo.insert(evrak);
    await Services.log.log(LogIslem.evrakEkleme,
        hedefTablo: 'Evraklar', hedefId: created.id, aciklama: adSoyad);
    return created;
  }

  /// Evrakı günceller (temel alanlar). Teslim bilgileri `teslimEt` ile.
  Future<int> guncelle(Evrak evrak) async {
    final updated = evrak.copyWith(guncellemeTarihi: DateUtil.nowIso());
    final n = await _repo.update(updated);
    await Services.log.log(LogIslem.evrakGuncelleme,
        hedefTablo: 'Evraklar', hedefId: evrak.id, aciklama: evrak.adSoyad);
    return n;
  }

  /// Teslim işlemi: durumu "Teslim Edildi" yap, teslim tarihi ata,
  /// TeslimKayitlari tablosuna kayıt ekle.
  Future<void> teslimEt({
    required int evrakId,
    required String teslimAlanAdSoyad,
    String? tcKimlikNo,
    String? telefon,
    String? aciklama,
  }) async {
    final teslimTarihi = DateUtil.nowIso();
    final evrak = await _repo.getById(evrakId);
    if (evrak == null) return;

    await _repo.setDurum(evrakId, EvrakDurum.teslimEdildi,
        teslimTarihi: teslimTarihi);

    final kayit = TeslimKaydi(
      evrakId: evrakId,
      teslimAlanAdSoyad: teslimAlanAdSoyad.trim(),
      tcKimlikNo: tcKimlikNo?.trim().isEmpty == true ? null : tcKimlikNo?.trim(),
      telefon: telefon?.trim().isEmpty == true ? null : telefon?.trim(),
      teslimTarihi: teslimTarihi,
      aciklama: aciklama?.trim().isEmpty == true ? null : aciklama?.trim(),
      olusturmaTarihi: teslimTarihi,
    );
    await _teslimRepo.insert(kayit);

    await Services.log.log(LogIslem.evrakTeslim,
        hedefTablo: 'Evraklar',
        hedefId: evrakId,
        aciklama: '${evrak.adSoyad} -> $teslimAlanAdSoyad');
  }

  /// Arşivle (manuel).
  Future<void> arsivle(int evrakId) async {
    await _repo.setDurum(evrakId, EvrakDurum.arsivlendi);
    final evrak = await _repo.getById(evrakId, includeDeleted: true);
    await Services.log.log(LogIslem.evrakArsivleme,
        hedefTablo: 'Evraklar',
        hedefId: evrakId,
        aciklama: evrak?.adSoyad);
  }

  /// Arşivden geri al -> Bekliyor.
  Future<void> geriAl(int evrakId) async {
    await _repo.setDurum(evrakId, EvrakDurum.bekliyor);
    final evrak = await _repo.getById(evrakId, includeDeleted: true);
    await Services.log.log(LogIslem.evrakGeriAlma,
        hedefTablo: 'Evraklar',
        hedefId: evrakId,
        aciklama: evrak?.adSoyad);
  }

  /// Toplu arşivle.
  Future<void> arsivleToplu(List<int> ids) async {
    for (final id in ids) {
      await arsivle(id);
    }
  }

  /// Yumuşak silme.
  Future<void> sil(int evrakId) async {
    await _repo.softDelete(evrakId);
    final evrak = await _repo.getById(evrakId, includeDeleted: true);
    await Services.log.log(LogIslem.evrakSilme,
        hedefTablo: 'Evraklar',
        hedefId: evrakId,
        aciklama: evrak?.adSoyad);
  }

  // --- Sorgu yöntemleri (UI katmanına proxy) ---

  Future<PagedResult<Evrak>> search({
    EvrakFilter filter = const EvrakFilter(),
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) =>
      _repo.search(filter: filter, page: page, pageSize: pageSize);

  Future<PagedResult<Evrak>> listByDurum(String durum,
          {int page = 1, int pageSize = AppConstants.defaultPageSize}) =>
      _repo.listByDurum(durum, page: page, pageSize: pageSize);

  Future<Evrak?> getById(int id, {bool includeDeleted = false}) =>
      _repo.getById(id, includeDeleted: includeDeleted);

  Future<List<TeslimKaydi>> teslimKayitlari(int evrakId) =>
      _repo.teslimKayitlari(evrakId);

  Future<Map<String, int>> durumCounts() => _repo.durumCounts();

  Future<int> totalCount() => _repo.totalCount();

  Future<Map<String, int>> durumCountsInRange(String bas, String son) =>
      _repo.durumCountsInRange(bas, son);

  Future<List<Evrak>> listInRange(String bas, String son) =>
      _repo.listInRange(bas, son);
}
