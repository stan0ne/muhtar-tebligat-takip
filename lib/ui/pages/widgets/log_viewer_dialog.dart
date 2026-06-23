import 'package:flutter/material.dart';
import '../../../core/date_util.dart';
import '../../../data/models/log_entry.dart';
import '../../../services/log_service.dart';

/// İşlem loglarını görüntüleyen diyalog.
class LogViewerDialog extends StatefulWidget {
  const LogViewerDialog({super.key});

  @override
  State<LogViewerDialog> createState() => _LogViewerDialogState();
}

class _LogViewerDialogState extends State<LogViewerDialog> {
  List<LogEntry> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = await Services.log.list(limit: 500);
    if (mounted) setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Text('İşlem Logları'),
          const Spacer(),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      content: SizedBox(
        width: 720,
        height: 480,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _logs.isEmpty
                ? const Center(child: Text('Log kaydı yok.'))
                : ListView.separated(
                    itemCount: _logs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final l = _logs[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.history, size: 20),
                        title: Text('${l.islem} — ${l.kullaniciAdi ?? "Sistem"}'),
                        subtitle: Text(
                          '${DateUtil.displayDateTime(l.tarih)}'
                          '${l.aciklama == null ? "" : " • ${l.aciklama}"}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}
