import 'package:flutter/material.dart';
import '../pages/dashboard_page.dart';
import '../pages/evrak_form_page.dart';
import '../pages/evrak_ara_page.dart';
import '../pages/evrak_liste_page.dart';
import '../pages/raporlar_page.dart';
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
  int _araKey = 0;
  String _hizliAramaDeger = '';

  @override
  void dispose() {
    _hizliAraCtrl.dispose();
    super.dispose();
  }

  void _goTo(MenuPage page) {
    if (page != MenuPage.ara) _hizliAraCtrl.clear();
    setState(() => _selected = page);
  }

  Widget _pageFor(MenuPage page) {
    switch (page) {
      case MenuPage.dashboard:
        return DashboardPage(onNavigate: _goTo);
      case MenuPage.yeniEvrak:
        return const EvrakFormPage(key: ValueKey('yeniEvrak'));
      case MenuPage.ara:
        return EvrakAraPage(hizliArama: _hizliAramaDeger, key: ValueKey('ara-$_araKey'));
      case MenuPage.bekleyen:
        return const EvrakListePage.durumBekleyen(key: ValueKey('bekleyen'));
      case MenuPage.teslimEdilen:
        return const EvrakListePage.durumTeslimEdilen(key: ValueKey('teslimEdilen'));
      case MenuPage.arsivlenen:
        return const EvrakListePage.durumArsivlendi(key: ValueKey('arsivlenen'));
      case MenuPage.raporlar:
        return const RaporlarPage();
      case MenuPage.ayarlar:
        return const AyarlarPage();
    }
  }

  Future<void> _hizliAra() async {
    if (_hizliAraCtrl.text.trim().isEmpty) return;
    _hizliAramaDeger = _hizliAraCtrl.text.trim();
    _hizliAraCtrl.clear();
    setState(() {
      _araKey++;
      _selected = MenuPage.ara;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // Sol menü – tüm NavigationRail hedefleri tek bir
          // FocusTraversal grubuna alınarak form alanlarından önce
          // odaklanmaları garanti altına alınır.
          FocusTraversalGroup(
            child: NavigationRail(
              selectedIndex: _selected.index,
              onDestinationSelected: (i) => _goTo(MenuPage.values[i]),
              extended: MediaQuery.of(context).size.width > 1100,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Image.asset('assets/icon.png', width: 32, height: 32),
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
          ),
          const VerticalDivider(width: 1),
          // Sağ çalışma alanı – form alanları ve diğer içerik de tek
          // bir FocusTraversal grubuna alınarak NavigationRail'den
          // sonra odaklanmaları sağlanır.
          Expanded(
            child: FocusTraversalGroup(
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
                              constraints:
                                  const BoxConstraints(maxWidth: 520),
                              child: TextField(
                                controller: _hizliAraCtrl,
                                onSubmitted: (_) => _hizliAra(),
                                decoration: InputDecoration(
                                  hintText:
                                      'Hızlı arama (Ad Soyad / Evrak No)',
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
          ),
        ],
      ),
    );
  }
}
