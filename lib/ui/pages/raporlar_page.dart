import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/date_util.dart';
import '../../services/export_service.dart' show RaporSonuc;
import '../../services/log_service.dart';
import '../widgets/ui_util.dart';

enum RaporTip { gunluk, aylik, yillik, aralik }

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
        break;
      case RaporTip.aylik:
        _bas = DateTime(now.year, now.month, 1);
        _son = now;
        break;
      case RaporTip.yillik:
        _bas = DateTime(now.year, 1, 1);
        _son = now;
        break;
      case RaporTip.aralik:
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
        _tip = RaporTip.aralik;
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
        _tip = RaporTip.aralik;
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
                  ButtonSegment(value: RaporTip.aylik, label: Text('Aylık')),
                  ButtonSegment(value: RaporTip.yillik, label: Text('Yıllık')),
                  ButtonSegment(value: RaporTip.aralik, label: Text('Aralık')),
                ],
                selected: {_tip},
                onSelectionChanged: (s) {
                  setState(() => _tip = s.first);
                  if (_tip != RaporTip.aralik) _applyTip();
                },
              ),
            ],
          ),
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
                UiUtil.infoCard(context,
                    title: 'Toplam', value: _toplam, icon: Icons.summarize, color: Theme.of(context).colorScheme.primary),
                UiUtil.infoCard(context,
                    title: 'Bekleyen', value: _counts[EvrakDurum.bekliyor] ?? 0, icon: Icons.hourglass_empty, color: Colors.orange),
                UiUtil.infoCard(context,
                    title: 'Teslim Edilen', value: _counts[EvrakDurum.teslimEdildi] ?? 0, icon: Icons.check_circle, color: Colors.green),
                UiUtil.infoCard(context,
                    title: 'Arşivlenen', value: _counts[EvrakDurum.arsivlendi] ?? 0, icon: Icons.archive, color: Colors.blueGrey),
              ],
            ),
          const SizedBox(height: 20),
          if (!_loading && _counts.isNotEmpty)
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: _exporting ? null : _exportExcel,
                  icon: const Icon(Icons.table_view),
                  label: const Text('Excel\'e Aktar'),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
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
