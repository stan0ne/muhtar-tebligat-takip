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

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadMuhtarlik();
  }

  @override
  void dispose() {
    _muhtarlikAdiCtrl.dispose();
    _muhtarAdSoyadCtrl.dispose();
    _ilCtrl.dispose();
    _ilceCtrl.dispose();
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
