import 'package:flutter/material.dart';
import '../../../core/date_util.dart';
import '../../../data/models/evrak.dart';
import '../../widgets/ui_util.dart';

/// Evrak tablosu (DataGrid benzeri). Çift tıklama detay açar.
/// Opsiyonel çoklu seçim desteği.
class EvrakDataTable extends StatelessWidget {
  final List<Evrak> items;
  final int total;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPage;
  final ValueChanged<Evrak> onRowTap;
  final Set<int>? selectedIds;
  final ValueChanged<Set<int>>? onSelectionChanged;

  const EvrakDataTable({
    super.key,
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.onPage,
    required this.onRowTap,
    this.selectedIds,
    this.onSelectionChanged,
  });

  int get _totalPages =>
      pageSize <= 0 ? 1 : ((total + pageSize - 1) ~/ pageSize);

  bool get _isMultiSelect => selectedIds != null && onSelectionChanged != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final columns = _isMultiSelect
        ? const ['', 'Ad Soyad', 'Geldiği Kurum', 'Evrak Sayısı', 'Geliş Tarihi', 'Durum']
        : const ['Ad Soyad', 'Geldiği Kurum', 'Evrak Sayısı', 'Geliş Tarihi', 'Durum'];

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
                            selected: _isMultiSelect && selectedIds!.contains(e.id),
                            onSelectChanged: _isMultiSelect
                                ? (val) {
                                    final newSet = Set<int>.from(selectedIds!);
                                    if (val == true) {
                                      newSet.add(e.id!);
                                    } else {
                                      newSet.remove(e.id!);
                                    }
                                    onSelectionChanged!(newSet);
                                  }
                                : (_) => onRowTap(e),
                            cells: [
                              if (_isMultiSelect)
                                DataCell(Checkbox(
                                  value: selectedIds!.contains(e.id),
                                  onChanged: (val) {
                                    final newSet = Set<int>.from(selectedIds!);
                                    if (val == true) {
                                      newSet.add(e.id!);
                                    } else {
                                      newSet.remove(e.id!);
                                    }
                                    onSelectionChanged!(newSet);
                                  },
                                )),
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
