import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/date_util.dart';
import '../../services/import_service.dart';
import '../../services/log_service.dart';

/// Excel içe aktarma sihirbazı.
class IceAktarmaPage extends StatefulWidget {
  const IceAktarmaPage({super.key});

  @override
  State<IceAktarmaPage> createState() => _IceAktarmaPageState();
}

class _IceAktarmaPageState extends State<IceAktarmaPage> {
  String? _filePath;
  String? _fileName;
  List<ImportRow> _rows = [];
  bool _loading = false;
  bool _importing = false;
  bool _creatingTemplate = false;

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (res == null || res.paths.isEmpty) return;
    final path = res.paths.first!;
    final name = res.files.first.name;
    setState(() {
      _filePath = path;
      _fileName = name;
      _rows = [];
      _loading = true;
    });
    try {
      final rows = await Services.import.readRows(path);
      setState(() => _rows = rows);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _apply() async {
    if (_rows.isEmpty) return;
    setState(() => _importing = true);
    try {
      final result = await Services.import.apply(_rows);
      if (mounted) _showResultDialog(result);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _showError(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _createTemplate() async {
    setState(() => _creatingTemplate = true);
    try {
      final path = await Services.import.createTemplate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Şablon kaydedildi: $path'),
            action: SnackBarAction(
              label: 'Dosyayı Aç',
              onPressed: () async {
                await Process.run('cmd', ['/c', 'start', '', path]);
              },
            ),
          ),
        );
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _creatingTemplate = false);
    }
  }

  void _reset() {
    setState(() {
      _filePath = null;
      _fileName = null;
      _rows = [];
      _loading = false;
      _importing = false;
    });
  }

  void _showResultDialog(ImportResult result) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.hatalar.isEmpty ? Icons.check_circle : Icons.warning,
              color: result.hatalar.isEmpty ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('İçe Aktarma Sonucu'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: result.hatalar.isEmpty
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: result.hatalar.isEmpty
                        ? Colors.green.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      result.hatalar.isEmpty ? Icons.check_circle : Icons.info,
                      color: result.hatalar.isEmpty ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${result.basarili}/${result.toplam} kayıt başarıyla aktarıldı.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (result.hatalar.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Hatalar (${result.hatalar.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: result.hatalar.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.error_outline, size: 16, color: Colors.red.shade400),
                        title: Text(
                          result.hatalar[i],
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (result.hatalar.isEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Tüm kayıtlar başarıyla aktarıldı.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _reset();
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Excel\'den İçe Aktarma', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Beklenen kolon başlıkları: Tarih, Ad Soyad, Geldiği Yer, '
                    'Sayı, T.C. Kimlik No, Telefon No, Evrakı Alan.\n'
                    '"Evrakı Alan" dolu satırlar "Teslim Edildi" olarak işaretlenir.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _creatingTemplate ? null : _createTemplate,
                    icon: _creatingTemplate
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.download),
                    label: const Text('Boş Şablon İndir'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dosya seçim alanı
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dosya Seç', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _loading ? null : _pick,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Excel Dosyası Seç'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.table_chart, size: 16, color: Colors.grey.shade500),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _fileName ?? 'Dosya seçilmedi',
                                  style: TextStyle(
                                    color: _fileName != null
                                        ? theme.colorScheme.onSurface
                                        : Colors.grey,
                                    fontWeight: _fileName != null ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_fileName != null)
                                Icon(Icons.check_circle, size: 16, color: Colors.green.shade500),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Yükleniyor
          if (_loading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Dosya okunuyor...'),
                    ],
                  ),
                ),
              ),
            ),

          // Önizleme
          if (!_loading && _rows.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.preview, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Önizleme', style: theme.textTheme.titleMedium),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_rows.length} kayıt',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _rows.length > 100 ? 100 : _rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final r = _rows[i];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            title: Text(
                              '${r.adSoyad}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              [r.tarih, r.geldigiYer, r.sayi, r.evrakiAlan]
                                  .whereType<String>()
                                  .where((s) => s.isNotEmpty)
                                  .join(' • '),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_rows.length > 100)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '... ve ${_rows.length - 100} kayıt daha',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // İçe Aktar butonu
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _importing ? null : _apply,
                icon: _importing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(_importing ? 'İçe Aktarılıyor...' : 'Veritabanına Aktar'),
              ),
            ),
          ],

          // Boş durum
          if (!_loading && _filePath != null && _rows.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.warning_amber, size: 48, color: Colors.orange.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'Dosyada aktarılacak kayıt bulunamadı.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lütfen kolon başlıklarını kontrol edin.',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
