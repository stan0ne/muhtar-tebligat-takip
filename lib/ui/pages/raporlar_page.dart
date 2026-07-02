import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/date_util.dart';
import '../../data/models/evrak.dart';
import '../../data/repositories/evrak_repository.dart' show EvrakFilter;
import '../../services/export_service.dart' show RaporSonuc;
import '../../services/log_service.dart';
import '../widgets/ui_util.dart';
import 'evrak_detail_page.dart';

enum RaporTip { gunluk, haftalik, aylik, yillik, diger }

/// Raporlar ekranı: filtreler + sayımlar + Excel/PDF çıktı.
class RaporlarPage extends StatefulWidget {
  const RaporlarPage({super.key});

  @override
  State<RaporlarPage> createState() => _RaporlarPageState();
}

class _RaporlarPageState extends State<RaporlarPage> {
  RaporTip _tip = RaporTip.aylik;
  DateTime _bas = DateTime.now().subtract(const Duration(days: 30));
  DateTime _son = DateTime.now();
  Map<String, int> _counts = {};
  int _toplam = 0;
  bool _loading = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _applyTip();
  }

  void _applyTip() {
    final now = DateTime.now();
    switch (_tip) {
      case RaporTip.gunluk:
        _bas = DateTime(now.year, now.month, now.day);
        _son = now;
        _load();
        break;
      case RaporTip.haftalik:
        final weekday = now.weekday;
        _bas = DateTime(now.year, now.month, now.day - (weekday - 1));
        _son = now;
        _load();
        break;
      case RaporTip.aylik:
        _bas = DateTime(now.year, now.month, 1);
        _son = now;
        _load();
        break;
      case RaporTip.yillik:
        _bas = DateTime(now.year, 1, 1);
        _son = now;
        _load();
        break;
      case RaporTip.diger:
        // Kullanıcı tarih seçecek, hesapla butonuna basacak
        break;
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final df = DateFormat('yyyy-MM-dd');
    final bas = df.format(_bas);
    final son = df.format(_son);
    final counts = await Services.evrak.durumCountsInRange(bas, son);
    final evrak = await Services.evrak.listInRange(bas, son);
    if (!mounted) return;
    setState(() {
      _counts = counts;
      _toplam = evrak.length;
      _loading = false;
    });
  }

  Future<void> _pickBas() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _bas,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('tr', 'TR'),
    );
    if (p != null) {
      setState(() {
        _bas = p;
        _tip = RaporTip.diger;
      });
    }
  }

  Future<void> _pickSon() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _son,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('tr', 'TR'),
    );
    if (p != null) {
      setState(() {
        _son = p;
        _tip = RaporTip.diger;
      });
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _exporting = true);
    try {
      final df = DateFormat('yyyy-MM-dd');
      final bas = df.format(_bas);
      final son = df.format(_son);
      final evrak = await Services.evrak.listInRange(bas, son);
      final rapor = RaporSonuc(
        baslik: 'Muhtarlık Tebligat Raporu',
        baslangic: _bas,
        bitis: _son,
        toplam: evrak.length,
        bekleyen: _counts[EvrakDurum.bekliyor] ?? 0,
        teslimEdilen: _counts[EvrakDurum.teslimEdildi] ?? 0,
        arsivlenen: _counts[EvrakDurum.arsivlendi] ?? 0,
        evraklar: evrak,
      );
      final path = await Services.export.exportExcel(rapor);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel oluşturuldu: $path')),
        );
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      final df = DateFormat('yyyy-MM-dd');
      final bas = df.format(_bas);
      final son = df.format(_son);
      final evrak = await Services.evrak.listInRange(bas, son);
      final rapor = RaporSonuc(
        baslik: 'Muhtarlık Tebligat Raporu',
        baslangic: _bas,
        bitis: _son,
        toplam: evrak.length,
        bekleyen: _counts[EvrakDurum.bekliyor] ?? 0,
        teslimEdilen: _counts[EvrakDurum.teslimEdildi] ?? 0,
        arsivlenen: _counts[EvrakDurum.arsivlendi] ?? 0,
        evraklar: evrak,
      );
      final path = await Services.export.exportPdf(rapor);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF oluşturuldu: $path')),
        );
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showError(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showFilteredDocs(String? durum) async {
    final df = DateFormat('yyyy-MM-dd');
    final bas = df.format(_bas);
    final son = df.format(_son);
    
    List<Evrak> evraklar;
    if (durum == null) {
      // Toplam - tümünü getir
      evraklar = await Services.evrak.listInRange(bas, son);
    } else {
      // Belirli durumdakileri filtrele
      final result = await Services.evrak.search(
        filter: EvrakFilter(durum: durum, tarihBaslangic: bas, tarihBitis: son),
        pageSize: 500,
      );
      evraklar = result.items;
    }

    if (!mounted) return;
    
    final baslik = durum == null ? 'Toplam Evraklar' : durum;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$baslik (${evraklar.length})'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: evraklar.isEmpty
              ? const Center(child: Text('Bu dönemde kayıp yok.'))
              : ListView.separated(
                  itemCount: evraklar.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final e = evraklar[i];
                    return ListTile(
                      dense: true,
                      title: Text(e.adSoyad, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('${e.geldigiKurum ?? "-"} • ${DateUtil.displayDate(e.gelisTarihi)}'),
                      trailing: UiUtil.durumChip(context, e.durum),
                      onTap: () {
                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          builder: (_) => EvrakDetailPage(evrakId: e.id!),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
              Row(
                children: [
                  Text('Raporlar',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  SegmentedButton<RaporTip>(
                    segments: const [
                      ButtonSegment(value: RaporTip.gunluk, label: Text('Günlük')),
                      ButtonSegment(value: RaporTip.haftalik, label: Text('Haftalık')),
                      ButtonSegment(value: RaporTip.aylik, label: Text('Aylık')),
                      ButtonSegment(value: RaporTip.yillik, label: Text('Yıllık')),
                      ButtonSegment(value: RaporTip.diger, label: Text('Diğer')),
                    ],
                    selected: {_tip},
                    onSelectionChanged: (s) {
                      setState(() => _tip = s.first);
                      if (_tip != RaporTip.diger) _applyTip();
                    },
                  ),
                ],
              ),
              if (_tip == RaporTip.diger) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Başlangıç: ${DateUtil.displayDate(DateFormat('yyyy-MM-dd').format(_bas))}'),
                    IconButton(
                        onPressed: _pickBas, icon: const Icon(Icons.event)),
                    const SizedBox(width: 16),
                    Text('Bitiş: ${DateUtil.displayDate(DateFormat('yyyy-MM-dd').format(_son))}'),
                    IconButton(
                        onPressed: _pickSon, icon: const Icon(Icons.event)),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _loading ? null : _load,
                      icon: const Icon(Icons.calculate),
                      label: const Text('Hesapla'),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 12),
                Text(
                  'Aralık: ${DateUtil.displayDate(DateFormat('yyyy-MM-dd').format(_bas))} - ${DateUtil.displayDate(DateFormat('yyyy-MM-dd').format(_son))}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_counts.isEmpty && _toplam == 0)
            const Card(child: ListTile(title: Text('Rapor oluşturmak için "Hesapla"ya basın.')))
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showFilteredDocs(null),
                  child: UiUtil.infoCard(context,
                      title: 'Toplam', value: _toplam, icon: Icons.summarize, color: Theme.of(context).colorScheme.primary),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showFilteredDocs(EvrakDurum.bekliyor),
                  child: UiUtil.infoCard(context,
                      title: 'Bekleyen', value: _counts[EvrakDurum.bekliyor] ?? 0, icon: Icons.hourglass_empty, color: Colors.orange),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showFilteredDocs(EvrakDurum.teslimEdildi),
                  child: UiUtil.infoCard(context,
                      title: 'Teslim Edilen', value: _counts[EvrakDurum.teslimEdildi] ?? 0, icon: Icons.check_circle, color: Colors.green),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showFilteredDocs(EvrakDurum.arsivlendi),
                  child: UiUtil.infoCard(context,
                      title: 'Arşivlenen', value: _counts[EvrakDurum.arsivlendi] ?? 0, icon: Icons.archive, color: Colors.blueGrey),
                ),
              ],
            ),
          const SizedBox(height: 20),
          if (!_loading && _counts.isNotEmpty)
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _exporting ? null : _exportExcel,
                  icon: const Icon(Icons.table_view),
                  label: const Text('Excel\'e Aktar'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _exporting ? null : _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF\'e Aktar'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
