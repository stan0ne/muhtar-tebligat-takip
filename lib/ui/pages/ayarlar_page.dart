import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/date_util.dart';
import '../../data/database/database_helper.dart';
import '../../services/evrak_service.dart';
import '../../services/log_service.dart';
import '../../services/backup_service.dart';
import '../providers/app_provider.dart';
import '../pages/evrak_detail_page.dart';
import '../pages/ice_aktarma_page.dart';
import 'widgets/log_viewer_dialog.dart';

/// Ayarlar: tema, muhtarlık bilgileri, loglar, veritabanı bilgisi.
class AyarlarPage extends StatefulWidget {
  const AyarlarPage({super.key});

  @override
  State<AyarlarPage> createState() => _AyarlarPageState();
}

class _AyarlarPageState extends State<AyarlarPage> {
  final _muhtarlikAdiCtrl = TextEditingController();
  final _muhtarAdSoyadCtrl = TextEditingController();
  final _ilCtrl = TextEditingController();
  final _ilceCtrl = TextEditingController();
  bool _saving = false;

  // Log yönetimi
  int _logCount = 0;
  String? _oldestLogDate;
  final _gunCtrl = TextEditingController(text: '90');
  bool _cleaning = false;

  // Otomatik arşivleme
  bool _autoArchive = false;
  bool _archiving = false;
  int _archiveMonths = 3;
  bool _archivePrevYears = true;
  String? _lastAutoArchiveRun;
  int _archivePreviewCount = 0;
  bool _previewLoading = false;
  List<Map<String, dynamic>> _previewDetails = [];

  // Veritabanı bilgisi
  String _dbPath = '';
  int _dbSize = 0;

  @override
  void initState() {
    super.initState();
    _loadMuhtarlik();
    _loadLogStats();
    _loadAutoArchiveSettings();
    _loadDbInfo();
  }

  @override
  void dispose() {
    _muhtarlikAdiCtrl.dispose();
    _muhtarAdSoyadCtrl.dispose();
    _ilCtrl.dispose();
    _ilceCtrl.dispose();
    _gunCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMuhtarlik() async {
    _muhtarlikAdiCtrl.text = await Services.settings.get('muhtarlik_adi') ?? '';
    _muhtarAdSoyadCtrl.text = await Services.settings.get('muhtar_ad_soyad') ?? '';
    _ilCtrl.text = await Services.settings.get('il') ?? '';
    _ilceCtrl.text = await Services.settings.get('ilce') ?? '';
  }

  Future<void> _saveMuhtarlik() async {
    setState(() => _saving = true);
    await Services.settings.set('muhtarlik_adi', _muhtarlikAdiCtrl.text.trim());
    await Services.settings.set('muhtar_ad_soyad', _muhtarAdSoyadCtrl.text.trim());
    await Services.settings.set('il', _ilCtrl.text.trim());
    await Services.settings.set('ilce', _ilceCtrl.text.trim());
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Muhtarlık bilgileri kaydedildi.')),
      );
    }
  }

  Future<void> _loadLogStats() async {
    final count = await Services.log.count();
    final oldest = await Services.log.getOldestDate();
    if (mounted) setState(() { _logCount = count; _oldestLogDate = oldest; });
  }

  Future<void> _cleanOldLogs() async {
    final gun = int.tryParse(_gunCtrl.text.trim());
    if (gun == null || gun < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir gün sayısı girin.')),
      );
      return;
    }
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Temizleme'),
        content: Text('$gun günden eski tüm loglar silinecek. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Temizle')),
        ],
      ),
    );
    if (onay != true) return;

    setState(() => _cleaning = true);
    final tarih = DateTime.now().subtract(Duration(days: gun)).toIso8601String();
    final silinen = await Services.log.deleteOlderThan(tarih);
    await _loadLogStats();
    if (mounted) {
      setState(() => _cleaning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$silinen log kaydı silindi.')),
      );
    }
  }

  Future<void> _cleanAllLogs() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm Logları Sil'),
        content: const Text('Tüm işlem logları silinecek. Bu işlem geri alınamaz. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (onay != true) return;

    setState(() => _cleaning = true);
    final silinen = await Services.log.deleteAll();
    await _loadLogStats();
    if (mounted) {
      setState(() => _cleaning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$silinen log kaydı silindi.')),
      );
    }
  }

  // --- Otomatik Arşivleme Ayarları ---

  Future<void> _loadAutoArchiveSettings() async {
    final enabled = await Services.settings.getBool(AppConstants.prefAutoArchive);
    final monthsStr = await Services.settings.get(AppConstants.prefAutoArchiveMonths);
    final prevYears = await Services.settings.getBool(AppConstants.prefAutoArchivePrevYears, def: true);
    final lastRun = await Services.settings.get(AppConstants.prefAutoArchiveLastRun);

    if (mounted) {
      setState(() {
        _autoArchive = enabled;
        _archiveMonths = int.tryParse(monthsStr ?? '') ?? 3;
        _archivePrevYears = prevYears;
        _lastAutoArchiveRun = lastRun;
      });
      _refreshPreview();
    }
  }

  Future<void> _toggleAutoArchive(bool value) async {
    await Services.settings.setBool(AppConstants.prefAutoArchive, value);
    setState(() => _autoArchive = value);
    if (value) {
      await _runAutoArchive();
    }
  }

  Future<void> _setArchiveMonths(int months) async {
    await Services.settings.set(AppConstants.prefAutoArchiveMonths, months.toString());
    setState(() => _archiveMonths = months);
    _refreshPreview();
  }

  Future<void> _setArchivePrevYears(bool value) async {
    await Services.settings.setBool(AppConstants.prefAutoArchivePrevYears, value);
    setState(() => _archivePrevYears = value);
    _refreshPreview();
  }

  Future<void> _refreshPreview() async {
    setState(() => _previewLoading = true);
    final count = await Services.evrak.autoArchivePreview(
      monthsOld: _archiveMonths,
      prevYearsOnly: _archivePrevYears,
    );
    final details = await Services.evrak.autoArchivePreviewDetails(
      monthsOld: _archiveMonths,
      prevYearsOnly: _archivePrevYears,
    );
    if (mounted) setState(() {
      _archivePreviewCount = count;
      _previewDetails = details;
      _previewLoading = false;
    });
  }

  Future<void> _runAutoArchive() async {
    setState(() => _archiving = true);
    final count = await Services.evrak.autoArchive(
      monthsOld: _archiveMonths,
      prevYearsOnly: _archivePrevYears,
    );
    final now = DateTime.now().toIso8601String();
    await Services.settings.set(AppConstants.prefAutoArchiveLastRun, now);
    setState(() {
      _archiving = false;
      _lastAutoArchiveRun = now;
    });
    await _refreshPreview();
    if (mounted) {
      if (count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count evrak otomatik olarak arşive aktarıldı.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arşivlenecek evrak bulunamadı.')),
        );
      }
    }
  }

  void _showPreviewDetails() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.archive, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Arşivlenecek Evraklar ($_archivePreviewCount)'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bu evraklar arşive aktarılacak:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _previewDetails.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final e = _previewDetails[i];
                      final gelisTarihi = (e['gelis_tarihi'] as String?)?.substring(0, 10) ?? '-';
                      final evrakId = e['id'] as int;
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.orange.withOpacity(0.2),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        title: Text(
                          '${e['evrak_sayisi'] ?? '-'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${e['ad_soyad'] ?? '-'} • ${e['geldigi_kurum'] ?? '-'}',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              gelisTarihi,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EvrakDetailPage(evrakId: evrakId),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _runAutoArchive();
            },
            icon: const Icon(Icons.archive),
            label: const Text('Arşivle'),
          ),
        ],
      ),
    );
  }

  // --- Veritabanı Bilgisi ---

  Future<void> _loadDbInfo() async {
    try {
      final path = await DatabaseHelper.instance.dbPath;
      final file = File(path);
      int size = 0;
      if (await file.exists()) {
        size = await file.length();
      }
      if (mounted) {
        setState(() {
          _dbPath = path;
          _dbSize = size;
        });
      }
    } catch (_) {}
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // --- İçe Aktarma / Dışa Aktarma ---

  void _showImportDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const IceAktarmaPage()),
    );
  }

  Future<void> _exportDatabase() async {
    final externalPath = await Services.backup.getExternalPath();
    if (externalPath == null || externalPath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Önce Yedekleme sayfasından harici konum ayarlayın.')),
        );
      }
      return;
    }

    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Veritabanını Dışa Aktar'),
        content: Text('Veritabanı şu konuma kopyalanacak:\n$externalPath\n\nDevam edilsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aktar')),
        ],
      ),
    );
    if (onay != true) return;

    try {
      final file = await Services.backup.backupToExternal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veritabanı dışa aktarıldı: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ayarlar', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          // --- Görünüm ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Görünüm', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, label: Text('Sistem')),
                      ButtonSegment(value: ThemeMode.light, label: Text('Açık')),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Koyu')),
                    ],
                    selected: {app.themeMode},
                    onSelectionChanged: (s) => app.setThemeMode(s.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // --- Muhtarlık Bilgileri ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Muhtarlık Bilgileri', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _muhtarlikAdiCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Muhtarlık Adı',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _muhtarAdSoyadCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Muhtar Adı Soyadı',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ilCtrl,
                          decoration: const InputDecoration(
                            labelText: 'İl',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _ilceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'İlçe',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _saveMuhtarlik,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // --- Veritabanı Bilgisi ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Veritabanı', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _dbInfoRow('Dosya Adı', AppConstants.dbName),
                  _dbInfoRow('Konum', _dbPath.isNotEmpty ? p.dirname(_dbPath) : '-'),
                  _dbInfoRow('Boyut', _dbSize > 0 ? _formatBytes(_dbSize) : '-'),
                  _dbInfoRow('Şema Sürümü', AppConstants.dbVersion.toString()),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showImportDialog(),
                          icon: const Icon(Icons.file_upload),
                          label: const Text('İçe Aktarma'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _exportDatabase(),
                          icon: const Icon(Icons.file_download),
                          label: const Text('Dışa Aktar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // --- Loglar ---
          Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: const Text('İşlem Logları'),
              subtitle: const Text('Tüm kullanıcı işlemlerini görüntüle.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showDialog(
                context: context,
                builder: (_) => const LogViewerDialog(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // --- Log Yönetimi ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Log Yönetimi', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 8),
                      Text('Toplam $_logCount log kaydı'),
                      if (_oldestLogDate != null) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.access_time, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        const SizedBox(width: 8),
                        Text('En eski: ${_oldestLogDate!.substring(0, 10)}'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _gunCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Gün',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('günden eski logları temizle'),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: _cleaning ? null : _cleanOldLogs,
                        icon: _cleaning
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.cleaning_services),
                        label: const Text('Temizle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _cleaning ? null : _cleanAllLogs,
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text('Tüm Logları Sil', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // --- Otomatik Arşivleme ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.archive, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Otomatik Arşivleme', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Açma/kapama + durum
                  Row(
                    children: [
                      if (_archiving)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Switch(
                          value: _autoArchive,
                          onChanged: _toggleAutoArchive,
                        ),
                      const SizedBox(width: 8),
                      Text(_autoArchive ? 'Açık' : 'Kapalı'),
                      if (_lastAutoArchiveRun != null) ...[
                        const Spacer(),
                        Icon(Icons.access_time, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          'Son çalışma: ${DateUtil.displayDateTime(_lastAutoArchiveRun!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Kriterler başlığı
                  Text('Kriterler', style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  )),
                  const SizedBox(height: 12),

                  // --- Geçmiş Yıllar ---
                  Row(
                    children: [
                      Icon(Icons.history, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 8),
                      Checkbox(
                        value: _archivePrevYears,
                        onChanged: (v) => _setArchivePrevYears(v ?? true),
                      ),
                      const SizedBox(width: 4),
                      const Text('Geçmiş Yıllar'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sadece önceki yıllara ait evrakları kapsar',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // --- Ay eşik değeri ---
                  Row(
                    children: [
                      Icon(Icons.timelapse, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 8),
                      const Text('Geliş tarihi:'),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: DropdownButtonFormField<int>(
                          value: _archiveMonths,
                          isDense: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1 ay')),
                            DropdownMenuItem(value: 2, child: Text('2 ay')),
                            DropdownMenuItem(value: 3, child: Text('3 ay')),
                            DropdownMenuItem(value: 6, child: Text('6 ay')),
                            DropdownMenuItem(value: 9, child: Text('9 ay')),
                            DropdownMenuItem(value: 12, child: Text('12 ay')),
                          ],
                          onChanged: (v) {
                            if (v != null) _setArchiveMonths(v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('dan eski olanlar'),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // --- Önizleme ---
                  Row(
                    children: [
                      Icon(Icons.preview, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 8),
                      Text('Önizleme:', style: theme.textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _archivePreviewCount > 0 ? _showPreviewDetails : null,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _archivePreviewCount > 0
                              ? Colors.orange.withOpacity(0.5)
                              : theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (_previewLoading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else ...[
                            Icon(
                              _archivePreviewCount > 0 ? Icons.info : Icons.check_circle,
                              size: 16,
                              color: _archivePreviewCount > 0
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              _previewLoading
                                  ? 'Hesaplanıyor...'
                                  : _archivePreviewCount > 0
                                      ? '$_archivePreviewCount evrak arşivlenecek'
                                      : 'Arşivlenecek evrak yok',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: _archivePreviewCount > 0
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (!_previewLoading && _archivePreviewCount > 0)
                            Icon(Icons.chevron_right, size: 18, color: Colors.orange.shade700),
                          if (!_previewLoading)
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 18),
                              onPressed: _refreshPreview,
                              tooltip: 'Yenile',
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // --- Çalıştır butonu ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: (_archiving || _archivePreviewCount == 0)
                          ? null
                          : _runAutoArchive,
                      icon: _archiving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.archive),
                      label: Text(_archiving ? 'Arşivleniyor...' : 'Hemen Çalıştır'),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    _archivePrevYears
                        ? 'Koşul: Önceki yıllara ait OLMALI ve geliş tarihi seçili aydan eski OLMALI.'
                        : 'Koşul: Geliş tarihi seçili aydan eski olan tüm Bekliyor evrakları.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'v${AppConstants.appVersion}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _dbInfoRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 13,
            )),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
