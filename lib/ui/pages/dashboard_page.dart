import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/date_util.dart';
import '../../data/models/evrak.dart';
import '../../services/log_service.dart';
import '../shell/menu_page.dart';
import '../widgets/ui_util.dart';
import 'evrak_detail_page.dart';

/// Ana sayfa: özet kartlar + son gelen evraklar.
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
  List<Evrak> _recentDocuments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final counts = await Services.evrak.durumCounts();
    final total = await Services.evrak.totalCount();
    final muhtarlikAdi = await Services.settings.get('muhtarlik_adi') ?? '';
    final recent = await Services.evrak.getRecentDocuments(days: 7, limit: 15);
    if (!mounted) return;
    setState(() {
      _bekleyen = counts[EvrakDurum.bekliyor] ?? 0;
      _teslim = counts[EvrakDurum.teslimEdildi] ?? 0;
      _arsiv = counts[EvrakDurum.arsivlendi] ?? 0;
      _toplam = total;
      _muhtarlikAdi = muhtarlikAdi;
      _recentDocuments = recent;
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
        final newRecent = await Services.evrak.getRecentDocuments(days: 7, limit: 15);
        if (mounted) setState(() {
          _bekleyen = newCounts[EvrakDurum.bekliyor] ?? 0;
          _teslim = newCounts[EvrakDurum.teslimEdildi] ?? 0;
          _arsiv = newCounts[EvrakDurum.arsivlendi] ?? 0;
          _toplam = newTotal;
          _recentDocuments = newRecent;
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
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Column(
      children: [
        // İstatistik kartları
        Padding(
          padding: EdgeInsets.fromLTRB(24 * scale, 24 * scale, 24 * scale, 0),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
                color: theme.colorScheme.primary,
                page: MenuPage.ara,
              ),
            ],
          ),
        ),

        // Son Gelen Evraklar
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24 * scale, 16 * scale, 24 * scale, 0),
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16 * scale, 16 * scale, 16 * scale, 0),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 20, color: theme.colorScheme.primary),
                        SizedBox(width: 8 * scale),
                        Text(
                          'Son Gelen Evraklar (Son 7 Gün)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_recentDocuments.isNotEmpty)
                          Text(
                            '${_recentDocuments.length} kayıt',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  Expanded(
                    child: _recentDocuments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox, size: 48, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                                const SizedBox(height: 12),
                                Text(
                                  'Son 7 günde yeni evrak yok',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildRecentTable(scale, isLight),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Muhtarlık adı
        if (_muhtarlikAdi.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 8),
            child: Text(
              '$_muhtarlikAdi Muhtarlığı',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.35),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentTable(double scale, bool isLight) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final adOran = constraints.maxWidth * 0.25;
        final kurumOran = constraints.maxWidth * 0.28;
        final gelisOran = constraints.maxWidth * 0.15;
        final teslimOran = constraints.maxWidth * 0.17;
        final durumOran = constraints.maxWidth * 0.15;

        return Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 10 * scale),
              color: isLight ? const Color(0xFFE8EDF4) : theme.colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  SizedBox(width: adOran, child: Text('Ad Soyad', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12 * scale))),
                  SizedBox(width: kurumOran, child: Text('Geldiği Kurum', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12 * scale))),
                  SizedBox(width: gelisOran, child: Text('Geliş Tarihi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12 * scale))),
                  SizedBox(width: teslimOran, child: Text('Teslim Tarihi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12 * scale))),
                  SizedBox(width: durumOran, child: Text('Durum', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12 * scale))),
                ],
              ),
            ),
            // Rows
            Expanded(
              child: ListView.builder(
                itemCount: _recentDocuments.length,
                itemBuilder: (context, index) {
                  final e = _recentDocuments[index];
                  final bgColor = isLight
                      ? (index.isOdd ? const Color(0xFFF5F7FA) : Colors.transparent)
                      : (index.isOdd ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3) : Colors.transparent);
                  return InkWell(
                    onTap: () => _openDetail(e.id!),
                    child: Container(
                      color: bgColor,
                      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 10 * scale),
                      child: Row(
                        children: [
                          SizedBox(
                            width: adOran,
                            child: Tooltip(
                              message: e.adSoyad,
                              waitDuration: const Duration(seconds: 1),
                              child: Text(
                                e.adSoyad,
                                style: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: kurumOran,
                            child: Tooltip(
                              message: e.geldigiKurum ?? '-',
                              waitDuration: const Duration(seconds: 1),
                              child: Text(
                                e.geldigiKurum ?? '-',
                                style: TextStyle(fontSize: 12 * scale),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: gelisOran,
                            child: Text(DateUtil.displayDate(e.gelisTarihi), style: TextStyle(fontSize: 12 * scale)),
                          ),
                          SizedBox(
                            width: teslimOran,
                            child: Text(DateUtil.displayDate(e.teslimTarihi), style: TextStyle(fontSize: 12 * scale)),
                          ),
                          UiUtil.durumChip(context, e.durum),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _openDetail(int evrakId) {
    showDialog(
      context: context,
      builder: (_) => EvrakDetailPage(evrakId: evrakId),
    ).then((_) {
      // Detay sayfasından dönünce listeyi yenile
      _load();
    });
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
