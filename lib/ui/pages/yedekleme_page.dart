import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../../core/constants.dart';
import '../../services/log_service.dart';
import '../providers/app_provider.dart';

/// Yedekleme / geri yükleme / otomatik yedek ayarları.
class YedeklemePage extends StatefulWidget {
  const YedeklemePage({super.key});

  @override
  State<YedeklemePage> createState() => _YedeklemePageState();
}

class _YedeklemePageState extends State<YedeklemePage> {
  List<File> _backups = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final files = await Services.backup.listBackups();
      if (mounted) setState(() => _backups = files);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _backupNow() async {
    try {
      final file = await Services.backup.backup();
      await Services.settings.set(AppConstants.prefLastBackup, DateTime.now().toIso8601String().substring(0, 10));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yedek alındı: ${p.basename(file.path)}')),
        );
      }
      _load();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _restore(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Geri Yükle'),
        content: Text(
            'Seçili yedek geri yüklenecek. Mevcut veriler üzerine yazılacak. '
            'Devam edilsin mi?\n\n${p.basename(file.path)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Geri Yükle')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Services.backup.restore(file.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geri yükleme tamamlandı.')),
        );
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _delete(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yedeği Sil'),
        content: Text(p.basename(file.path)),
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
      await Services.backup.deleteBackup(file);
      _load();
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
    final app = context.watch<AppProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Yedekleme', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _backupNow,
                        icon: const Icon(Icons.backup),
                        label: const Text('Şimdi Yedek Al'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final res = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['db'],
                          );
                          if (res != null && res.paths.isNotEmpty) {
                            await _restore(File(res.paths.first!));
                          }
                        },
                        icon: const Icon(Icons.restore),
                        label: const Text('Dosyadan Geri Yükle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Otomatik Günlük Yedek'),
                    subtitle: const Text(
                        'Girişte, bugün alınmamışsa otomatik yedek alınır.'),
                    value: app.autoBackup,
                    onChanged: (v) => app.setAutoBackup(v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Mevcut Yedekler (${_backups.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_backups.isEmpty)
            const Card(child: ListTile(title: Text('Henüz yedek yok.')))
          else
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _backups.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final f = _backups[i];
                  final stat = f.statSync();
                  return ListTile(
                    leading: const Icon(Icons.storage, color: Colors.blueGrey),
                    title: Text(p.basename(f.path)),
                    subtitle: Text(
                      '${stat.size ~/ 1024} KB • ${stat.modified.toLocal()}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Geri Yükle',
                          icon: const Icon(Icons.restore),
                          onPressed: () => _restore(f),
                        ),
                        IconButton(
                          tooltip: 'Sil',
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _delete(f),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
