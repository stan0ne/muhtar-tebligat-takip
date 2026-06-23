import 'package:flutter/material.dart';
import '../../../core/date_util.dart';
import '../../../data/models/evrak.dart';
import '../../widgets/ui_util.dart';

/// Evrak tablosu (DataGrid benzeri). Çift tıklama detay açar.
class EvrakDataTable extends StatelessWidget {
  final List<Evrak> items;
  final int total;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPage;
  final ValueChanged<Evrak> onRowTap;

  const EvrakDataTable({
    super.key,
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.onPage,
    required this.onRowTap,
  });

  int get _totalPages =>
      pageSize <= 0 ? 1 : ((total + pageSize - 1) ~/ pageSize);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final columns = const ['Ad Soyad', 'Geldiği Kurum', 'Evrak Sayısı', 'Geliş Tarihi', 'Durum'];

    return Column(
      children: [
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Kayıt bulunamadı.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: [
                        for (final c in columns)
                          DataColumn(label: Text(c, style: const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: [
                        for (final e in items)
                          DataRow(
                            onSelectChanged: (_) => onRowTap(e),
                            cells: [
                              DataCell(Text(e.adSoyad)),
                              DataCell(Text(e.geldigiKurum ?? '-')),
                              DataCell(Text(e.evrakSayisi ?? '-')),
                              DataCell(Text(DateUtil.displayDate(e.gelisTarihi))),
                              DataCell(UiUtil.durumChip(context, e.durum)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
        ),
        if (items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Toplam: $total kayıt',
                    style: theme.textTheme.bodySmall),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Önceki',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: page > 1 ? () => onPage(page - 1) : null,
                    ),
                    Text('Sayfa $page / $_totalPages'),
                    IconButton(
                      tooltip: 'Sonraki',
                      icon: const Icon(Icons.chevron_right),
                      onPressed: page < _totalPages
                          ? () => onPage(page + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
