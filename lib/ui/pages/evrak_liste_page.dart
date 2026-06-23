import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/models/evrak.dart';
import '../../services/log_service.dart';
import '../pages/evrak_detail_page.dart';
import 'widgets/evrak_data_table.dart';

/// Duruma göre filtreli liste (Bekleyen / Teslim Edilen / Arşivlenen).
class EvrakListePage extends StatefulWidget {
  final String durum;
  final String title;

  const EvrakListePage._({required this.durum, required this.title});

  const EvrakListePage.durumBekleyen()
      : this._(durum: EvrakDurum.bekliyor, title: 'Bekleyen Evraklar');
  const EvrakListePage.durumTeslimEdilen()
      : this._(durum: EvrakDurum.teslimEdildi, title: 'Teslim Edilen Evraklar');
  const EvrakListePage.durumArsivlendi()
      : this._(durum: EvrakDurum.arsivlendi, title: 'Arşivlenen Evraklar');

  @override
  State<EvrakListePage> createState() => _EvrakListePageState();
}

class _EvrakListePageState extends State<EvrakListePage> {
  List<Evrak> _items = [];
  int _total = 0;
  int _page = 1;
  final int _pageSize = AppConstants.defaultPageSize;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await Services.evrak.listByDurum(widget.durum,
        page: _page, pageSize: _pageSize);
    if (!mounted) return;
    setState(() {
      _items = res.items;
      _total = res.total;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(widget.title,
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
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
                ),
        ),
      ],
    );
  }
}
