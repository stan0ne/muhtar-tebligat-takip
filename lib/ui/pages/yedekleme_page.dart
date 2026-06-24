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
  List<File> _externalBackups = [];
  bool _loading = false;
  String? _externalPath;
  bool _savingExternal = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final files = await Services.backup.listBackups();
      final extPath = await Services.backup.getExternalPath();
      final extFiles = await Services.backup.listExternalBackups();
      if (mounted) {
        setState(() {
          _backups = files;
          _externalPath = extPath;
          _externalBackups = extFiles;
        });
      }
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

  Future<void> _backupToExternal() async {
    if (_externalPath == null || _externalPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce harici yedekleme konumunu seçin.')),
      );
      return;
    }
    try {
      final file = await Services.backup.backupToExternal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Harici yedek alındı: ${p.basename(file.path)}')),
        );
      }
      _load();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _selectExternalDir() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Harici Yedekleme Konumu Seçin',
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _savingExternal = true);
      await Services.backup.setExternalPath(result);
      setState(() {
        _externalPath = result;
        _savingExternal = false;
      });
      _load();
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
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Yedekleme', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          // --- Dahili Yedekleme ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dahili Yedekleme', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
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
          // --- Harici Yedekleme ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.folder, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Harici Yedekleme', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          readOnly: true,
                          controller: TextEditingController(text: _externalPath ?? ''),
                          decoration: InputDecoration(
                            labelText: 'Yedekleme Konumu',
                            hintText: 'Dizin seçilmedi',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.folder_open),
                              onPressed: _selectExternalDir,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: _savingExternal ? null : _backupToExternal,
                        icon: _savingExternal
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.backup),
                        label: const Text('Yedekle'),
                      ),
                    ],
                  ),
                  if (_externalBackups.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Harici Yedekler (${_externalBackups.length})',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _externalBackups.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final f = _externalBackups[i];
                        final stat = f.statSync();
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.storage, color: Colors.green),
                          title: Text(p.basename(f.path), style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                            '${stat.size ~/ 1024} KB • ${stat.modified.toLocal()}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Geri Yükle',
                                icon: const Icon(Icons.restore, size: 18),
                                onPressed: () => _restore(f),
                              ),
                              IconButton(
                                tooltip: 'Sil',
                                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                onPressed: () => _delete(f),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // --- Mevcut Yedekler ---
          Row(
            children: [
              Text('Mevcut Yedekler (${_backups.length})',
                  style: theme.textTheme.titleMedium),
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
