import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/log_service.dart';
import '../shell/menu_page.dart';
import '../widgets/ui_util.dart';

/// Ana sayfa: özet kartlar + hızlı erişim.
class DashboardPage extends StatefulWidget {
  final void Function(MenuPage)? onNavigate;
  const DashboardPage({super.key, this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _bekleyen = 0;
  int _teslim = 0;
  int _arsiv = 0;
  int _toplam = 0;
  bool _loading = true;
  String _muhtarlikAdi = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final counts = await Services.evrak.durumCounts();
    final total = await Services.evrak.totalCount();
    final muhtarlikAdi = await Services.settings.get('muhtarlik_adi') ?? '';
    if (!mounted) return;
    setState(() {
      _bekleyen = counts[EvrakDurum.bekliyor] ?? 0;
      _teslim = counts[EvrakDurum.teslimEdildi] ?? 0;
      _arsiv = counts[EvrakDurum.arsivlendi] ?? 0;
      _toplam = total;
      _muhtarlikAdi = muhtarlikAdi;
      _loading = false;
    });

    // Otomatik arşivleme — açılışta bir kez çalıştır
    final autoArchive = await Services.settings.getBool(AppConstants.prefAutoArchive);
    if (autoArchive && mounted) {
      final monthsStr = await Services.settings.get(AppConstants.prefAutoArchiveMonths);
      final prevYears = await Services.settings.getBool(AppConstants.prefAutoArchivePrevYears, def: true);
      final months = int.tryParse(monthsStr ?? '') ?? 3;
      final archived = await Services.evrak.autoArchive(monthsOld: months, prevYearsOnly: prevYears);
      if (archived > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$archived evrak otomatik olarak arşive aktarıldı.')),
        );
        // Sayıları yenile
        final newCounts = await Services.evrak.durumCounts();
        final newTotal = await Services.evrak.totalCount();
        if (mounted) setState(() {
          _bekleyen = newCounts[EvrakDurum.bekliyor] ?? 0;
          _teslim = newCounts[EvrakDurum.teslimEdildi] ?? 0;
          _arsiv = newCounts[EvrakDurum.arsivlendi] ?? 0;
          _toplam = newTotal;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 1170).clamp(0.8, 1.5);

    return Column(
      children: [
        Expanded(
          child: GridView.count(
            padding: EdgeInsets.all(24 * scale),
            crossAxisCount: screenWidth > 900 ? 4 : 2,
            mainAxisSpacing: 16 * scale,
            crossAxisSpacing: 16 * scale,
            childAspectRatio: 1.6,
            children: [
              _card(
                context,
                title: 'Bekleyen Evraklar',
                value: _bekleyen,
                icon: Icons.hourglass_empty,
                color: Colors.orange,
                page: MenuPage.bekleyen,
              ),
              _card(
                context,
                title: 'Teslim Edilenler',
                value: _teslim,
                icon: Icons.check_circle,
                color: Colors.green,
                page: MenuPage.teslimEdilen,
              ),
              _card(
                context,
                title: 'Arşivlenenler',
                value: _arsiv,
                icon: Icons.archive,
                color: Colors.blueGrey,
                page: MenuPage.arsivlenen,
              ),
              _card(
                context,
                title: 'Toplam Evraklar',
                value: _toplam,
                icon: Icons.mark_email_unread,
                color: Theme.of(context).colorScheme.primary,
                page: MenuPage.ara,
              ),
            ],
          ),
        ),
        if (_muhtarlikAdi.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '$_muhtarlikAdi Muhtarlığı',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                  ),
            ),
          ),
      ],
    );
  }

  Widget _card(
    BuildContext ctx, {
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required MenuPage page,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => widget.onNavigate?.call(page),
      child: UiUtil.infoCard(ctx,
          title: title, value: value, icon: icon, color: color),
    );
  }
}
