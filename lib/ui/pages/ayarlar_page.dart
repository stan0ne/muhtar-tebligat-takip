import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../data/models/user.dart';
import '../../services/log_service.dart';
import '../providers/app_provider.dart';
import 'widgets/user_dialog.dart';
import 'widgets/log_viewer_dialog.dart';

/// Ayarlar: tema, parola değiştirme, kullanıcı yönetimi, loglar.
class AyarlarPage extends StatefulWidget {
  const AyarlarPage({super.key});

  @override
  State<AyarlarPage> createState() => _AyarlarPageState();
}

class _AyarlarPageState extends State<AyarlarPage> {
  List<User> _users = [];
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

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadMuhtarlik();
    _loadLogStats();
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

  Future<void> _loadUsers() async {
    final users = await Services.auth.listUsers();
    if (mounted) setState(() => _users = users);
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

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isYonetici = app.user?.isYonetici ?? false;

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
          // --- Kullanıcı Yönetimi ---
          if (isYonetici)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Kullanıcı Yönetimi', style: theme.textTheme.titleMedium),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () => _showUserDialog(null),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Yeni Kullanıcı'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final u = _users[i];
                        return ListTile(
                          leading: Icon(u.aktif ? Icons.check_circle : Icons.block,
                              color: u.aktif ? Colors.green : Colors.grey),
                          title: Text(u.kullaniciAdi),
                          subtitle: Text('${u.rol} • ${u.adSoyad ?? "-"}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showUserDialog(u),
                          ),
                        );
                      },
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

  Future<void> _showUserDialog(User? user) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => UserDialog(user: user),
    );
    if (res == true) _loadUsers();
  }
}
