import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  List<ImportRow> _rows = [];
  bool _loading = false;
  bool _importing = false;
  ImportResult? _result;

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (res == null || res.paths.isEmpty) return;
    final path = res.paths.first!;
    setState(() {
      _filePath = path;
      _rows = [];
      _result = null;
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
    setState(() {
      _importing = true;
      _result = null;
    });
    try {
      final result = await Services.import.apply(_rows);
      setState(() => _result = result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result.basarili}/${result.toplam} kayıt aktarıldı.')),
        );
      }
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
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Beklenen kolon başlıkları: Tarih, Ad Soyad, Geldiği Yer, '
                'Sayı, T.C. Kimlik No, Telefon No, Evrakı Alan.\n'
                '"Evrakı Alan" dolu satırlar "Teslim Edildi" olarak işaretlenir.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _loading ? null : _pick,
                icon: const Icon(Icons.attach_file),
                label: const Text('Excel Dosyası Seç'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _filePath ?? 'Dosya seçilmedi',
                  style: const TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_rows.isNotEmpty) ...[
            Text('Okunan kayıtlar: ${_rows.length}',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: SizedBox(
                height: 280,
                child: ListView.separated(
                  itemCount: _rows.length > 100 ? 100 : _rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = _rows[i];
                    return ListTile(
                      dense: true,
                      title: Text('${r.adSoyad} - ${r.tarih}'),
                      subtitle: Text(
                        [r.geldigiYer, r.sayi, r.evrakiAlan]
                            .whereType<String>()
                            .join(' • '),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_rows.length > 100)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '... ve ${_rows.length - 100} kayıt daha',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _importing ? null : _apply,
              icon: const Icon(Icons.upload_file),
              label: const Text('Veritabanına Aktar'),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sonuç: ${_result!.basarili}/${_result!.toplam} başarılı',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_result!.hatalar.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Hatalar:', style: TextStyle(color: Colors.red)),
                      ..._result!.hatalar.map((h) => Text('• $h',
                          style: const TextStyle(fontSize: 12))),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
