import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';
import '../../core/date_util.dart';
import '../../data/models/evrak.dart';
import '../../data/models/teslim_kaydi.dart';
import '../../data/models/durum_gecmisi.dart';
import '../../services/log_service.dart';
import '../widgets/ui_util.dart';
import 'evrak_form_page.dart';
import 'widgets/teslim_dialog.dart';

/// Evrak detay ekranı (bilgi + teslim geçmiş + işlemler).
class EvrakDetailPage extends StatefulWidget {
  final int evrakId;
  const EvrakDetailPage({super.key, required this.evrakId});

  @override
  State<EvrakDetailPage> createState() => _EvrakDetailPageState();
}

class _EvrakDetailPageState extends State<EvrakDetailPage> {
  Evrak? _evrak;
  List<TeslimKaydi> _teslim = [];
  List<DurumGecmisi> _gecmis = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await Services.evrak.getById(widget.evrakId, includeDeleted: true);
    final t = await Services.evrak.teslimKayitlari(widget.evrakId);
    final g = await Services.evrak.durumGecmisi(widget.evrakId);
    if (!mounted) return;
    setState(() {
      _evrak = e;
      _teslim = t;
      _gecmis = g;
      _loading = false;
    });
  }

  Future<void> _teslimEt() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => TeslimDialog(evrakId: widget.evrakId),
    );
    if (ok == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _arsivle() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arşivle'),
        content: const Text('Seçili evrak arşivlensin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Arşivle')),
        ],
      ),
    );
    if (confirm == true) {
      await Services.evrak.arsivle(widget.evrakId);
      if (mounted) _load();
    }
  }

  Future<void> _geriAl() async {
    await Services.evrak.geriAl(widget.evrakId);
    if (mounted) _load();
  }

  Future<void> _sil() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sil'),
        content: const Text(
            'Kayıt yumuşak silinsin mi? (Arşivden kalıcı silme yapılmaz.)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await Services.evrak.sil(widget.evrakId);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  Future<void> _duzenle() async {
    if (_evrak == null) return;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EvrakFormPage(evrak: _evrak),
      ),
    );
    if (updated == true && mounted) _load();
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Geri',
            onPressed: _goBack,
          ),
          title: const Text('Yükleniyor...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_evrak == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Geri',
            onPressed: _goBack,
          ),
          title: const Text('Hata'),
        ),
        body: const Center(child: Text('Evrak bulunamadı.')),
      );
    }
    final e = _evrak!;
    final theme = Theme.of(context);
    final isBekleyen = e.durum == EvrakDurum.bekliyor;
    final isArsiv = e.durum == EvrakDurum.arsivlendi;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _goBack();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Geri',
            onPressed: _goBack,
          ),
          title: Text(e.adSoyad),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(e.adSoyad,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      UiUtil.durumChip(context, e.durum),
                    ],
                  ),
                  const Divider(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _row('Geliş Tarihi', DateUtil.displayDate(e.gelisTarihi)),
                          _row('Ad Soyad', e.adSoyad),
                          _row('Geldiği Kurum', e.geldigiKurum ?? '-'),
                          _row('Evrak Sayısı', e.evrakSayisi ?? '-'),
                          _row('Teslim Tarihi', DateUtil.displayDateTime(e.teslimTarihi)),
                          _row('Oluşturma', DateUtil.displayDateTime(e.olusturmaTarihi)),
                          _row('Güncelleme', DateUtil.displayDateTime(e.guncellemeTarihi)),
                          if (e.silindiMi == 1)
                            _row('Silinme', DateUtil.displayDateTime(e.silinmeTarihi),
                                color: Colors.red),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Teslim Geçmişi (${_teslim.length})',
                        style: theme.textTheme.titleMedium),
                  ),
                  const SizedBox(height: 8),
                  if (_teslim.isEmpty)
                    const Text('Henüz teslim kaydı yok.')
                  else
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _teslim.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final t = _teslim[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.check_circle, color: Colors.green),
                            title: Text(t.teslimAlanAdSoyad),
                            subtitle: Text(DateUtil.displayDateTime(t.teslimTarihi)),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (t.tcKimlikNo != null) Text('TC: ${t.tcKimlikNo}'),
                                if (t.telefon != null) Text('Tel: ${t.telefon}'),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  // --- Durum Geçmişi ---
                  if (_gecmis.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Durum Geçmişi',
                          style: theme.textTheme.titleMedium),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildTimeline(theme),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (isBekleyen)
                        FilledButton.icon(
                          onPressed: _teslimEt,
                          icon: const Icon(Icons.local_shipping),
                          label: const Text('Teslim Et'),
                        ),
                      FilledButton.icon(
                        onPressed: _duzenle,
                        icon: const Icon(Icons.edit),
                        label: const Text('Düzenle'),
                      ),
                      if (isBekleyen)
                        FilledButton.icon(
                          onPressed: _arsivle,
                          icon: const Icon(Icons.archive),
                          label: const Text('Arşivle'),
                        ),
                      if (isArsiv)
                        FilledButton.icon(
                          onPressed: _geriAl,
                          icon: const Icon(Icons.restore),
                          label: const Text('Bekleyene Geri Al'),
                        ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: _sil,
                        icon: const Icon(Icons.delete),
                        label: const Text('Sil'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(ThemeData theme) {
    return Column(
      children: [
        for (int i = 0; i < _gecmis.length; i++) ...[
          _buildTimelineItem(theme, _gecmis[i], i < _gecmis.length - 1),
        ],
      ],
    );
  }

  Widget _buildTimelineItem(ThemeData theme, DurumGecmisi gecmis, bool showLine) {
    final Color color;
    final IconData icon;
    switch (gecmis.yeniDurum) {
      case EvrakDurum.bekliyor:
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case EvrakDurum.teslimEdildi:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case EvrakDurum.arsivlendi:
        color = Colors.grey;
        icon = Icons.archive;
        break;
      default:
        color = Colors.blue;
        icon = Icons.info;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            if (showLine)
              Container(
                width: 2,
                height: 40,
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    gecmis.eskiDurum != null
                        ? '${gecmis.eskiDurum} → ${gecmis.yeniDurum}'
                        : gecmis.yeniDurum,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                DateUtil.displayDateTime(gecmis.degisiklikTarihi),
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              if (gecmis.aciklama != null && gecmis.aciklama!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  gecmis.aciklama!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}
