import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/models/evrak.dart';
import '../../services/log_service.dart';
import '../pages/evrak_detail_page.dart';
import 'widgets/evrak_data_table.dart';
import 'widgets/teslim_dialog.dart';

/// Duruma göre filtreli liste (Bekleyen / Teslim Edilen / Arşivlenen).
class EvrakListePage extends StatefulWidget {
  final String durum;
  final String title;

  const EvrakListePage._({super.key, required this.durum, required this.title});

  const EvrakListePage.durumBekleyen({Key? key})
      : this._(key: key, durum: EvrakDurum.bekliyor, title: 'Bekleyen Evraklar');
  const EvrakListePage.durumTeslimEdilen({Key? key})
      : this._(key: key, durum: EvrakDurum.teslimEdildi, title: 'Teslim Edilen Evraklar');
  const EvrakListePage.durumArsivlendi({Key? key})
      : this._(key: key, durum: EvrakDurum.arsivlendi, title: 'Arşivlenen Evraklar');

  @override
  State<EvrakListePage> createState() => _EvrakListePageState();
}

class _EvrakListePageState extends State<EvrakListePage> {
  List<Evrak> _items = [];
  int _total = 0;
  int _page = 1;
  final int _pageSize = AppConstants.defaultPageSize;
  bool _loading = true;
  final Set<int> _selectedIds = {};

  bool get _isBekleyen => widget.durum == EvrakDurum.bekliyor;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant EvrakListePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.durum != oldWidget.durum) {
      _page = 1;
      _selectedIds.clear();
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Services.evrak.listByDurum(widget.durum,
          page: _page, pageSize: _pageSize);
      if (!mounted) return;
      setState(() {
        _items = res.items;
        _total = res.total;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yükleme hatası: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _teslimEtSecilenleri() async {
    if (_selectedIds.isEmpty) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => TeslimDialog(evrakIds: _selectedIds.toList()),
    );
    if (result == true) {
      _selectedIds.clear();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(widget.title,
                  style: theme.textTheme.titleLarge),
              const Spacer(),
              if (_isBekleyen && _selectedIds.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_selectedIds.length} seçili',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _teslimEtSecilenleri,
                  icon: const Icon(Icons.how_to_reg),
                  label: const Text('Seçilenleri Teslim Et'),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                tooltip: 'Yenile',
                icon: const Icon(Icons.refresh),
                onPressed: _load,
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : EvrakDataTable(
                  items: _items,
                  total: _total,
                  page: _page,
                  pageSize: _pageSize,
                  onPage: (p) {
                    _page = p;
                    _load();
                  },
                  onRowTap: (e) async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => EvrakDetailPage(evrakId: e.id!),
                    ));
                    _load();
                  },
                  selectedIds: _isBekleyen ? _selectedIds : null,
                  onSelectionChanged: _isBekleyen
                      ? (ids) => setState(() {
                            _selectedIds.clear();
                            _selectedIds.addAll(ids);
                          })
                      : null,
                  dateColumnLabel: widget.durum == EvrakDurum.teslimEdildi
                      ? 'Teslim Tarihi'
                      : 'Geliş Tarihi',
                  dateGetter: widget.durum == EvrakDurum.teslimEdildi
                      ? (e) => e.teslimTarihi ?? ''
                      : (e) => e.gelisTarihi ?? '',
                ),
        ),
      ],
    );
  }
}
