import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../pages/dashboard_page.dart';
import '../pages/evrak_form_page.dart';
import '../pages/evrak_ara_page.dart';
import '../pages/evrak_liste_page.dart';
import '../pages/raporlar_page.dart';
import '../pages/ice_aktarma_page.dart';
import '../pages/yedekleme_page.dart';
import '../pages/ayarlar_page.dart';
import 'menu_page.dart';

/// Sol menü + üst hızlı arama + sağ çalışma alanından oluşan ana iskelet.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  MenuPage _selected = MenuPage.dashboard;
  final _hizliAraCtrl = TextEditingController();

  @override
  void dispose() {
    _hizliAraCtrl.dispose();
    super.dispose();
  }

  void _goTo(MenuPage page) => setState(() => _selected = page);

  Widget _pageFor(MenuPage page) {
    switch (page) {
      case MenuPage.dashboard:
        return DashboardPage(onNavigate: _goTo);
      case MenuPage.yeniEvrak:
        return const EvrakFormPage();
      case MenuPage.ara:
        return EvrakAraPage(hizliArama: _hizliAraCtrl.text);
      case MenuPage.bekleyen:
        return const EvrakListePage.durumBekleyen();
      case MenuPage.teslimEdilen:
        return const EvrakListePage.durumTeslimEdilen();
      case MenuPage.arsivlenen:
        return const EvrakListePage.durumArsivlendi();
      case MenuPage.raporlar:
        return const RaporlarPage();
      case MenuPage.iceAktarma:
        return const IceAktarmaPage();
      case MenuPage.yedekleme:
        return const YedeklemePage();
      case MenuPage.ayarlar:
        return const AyarlarPage();
    }
  }

  Future<void> _hizliAra() async {
    if (_hizliAraCtrl.text.trim().isEmpty) return;
    setState(() => _selected = MenuPage.ara);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final user = app.user;

    return Scaffold(
      body: Row(
        children: [
          // Sol menü
          NavigationRail(
            selectedIndex: _selected.index,
            onDestinationSelected: (i) => _goTo(MenuPage.values[i]),
            extended: MediaQuery.of(context).size.width > 1100,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(Icons.mark_email_unread,
                      size: 32, color: theme.colorScheme.primary),
                  const SizedBox(height: 4),
                  Text('Tebligat',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            destinations: [
              for (final p in MenuPage.values)
                NavigationRailDestination(
                  icon: Icon(p.icon),
                  selectedIcon: Icon(p.selectedIcon),
                  label: Text(p.title),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          // Sağ çalışma alanı
          Expanded(
            child: Column(
              children: [
                // Üst bar: hızlı arama + kullanıcı
                Material(
                  elevation: 1,
                  color: theme.appBarTheme.backgroundColor ??
                      theme.colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: TextField(
                              controller: _hizliAraCtrl,
                              onSubmitted: (_) => _hizliAra(),
                              decoration: InputDecoration(
                                hintText: 'Hızlı arama (Ad Soyad / Evrak No)',
                                prefixIcon: const Icon(Icons.search),
                                isDense: true,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Chip(
                          avatar: const Icon(Icons.person, size: 18),
                          label: Text(
                            '${user?.adSoyad ?? user?.kullaniciAdi ?? ''} '
                            '(${user?.rol ?? ""})',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Çıkış',
                          icon: const Icon(Icons.logout),
                          onPressed: () async {
                            await app.logout();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // İçerik
                Expanded(
                  child: _pageFor(_selected),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
