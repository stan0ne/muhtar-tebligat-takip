import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await Services.auth.listUsers();
    if (mounted) setState(() => _users = users);
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
          // --- Hesap / Parola ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hesap', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(app.user?.adSoyad ?? app.user?.kullaniciAdi ?? ''),
                    subtitle: Text(
                        'Kullanıcı: ${app.user?.kullaniciAdi ?? ""} • Rol: ${app.user?.rol ?? ""}'),
                  ),
                  if (isYonetici) ...[
                    const Divider(),
                    FilledButton.tonalIcon(
                      onPressed: () => _showUserDialog(app.user!),
                      icon: const Icon(Icons.key),
                      label: const Text('Parola Değiştir'),
                    ),
                  ],
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
