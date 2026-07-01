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
  final String dateColumnLabel;
  final String Function(Evrak) dateGetter;

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
    this.dateColumnLabel = 'Geliş Tarihi',
    this.dateGetter = _defaultDateGetter,
  });

  static String _defaultDateGetter(Evrak e) => e.gelisTarihi ?? '';

  int get _totalPages =>
      pageSize <= 0 ? 1 : ((total + pageSize - 1) ~/ pageSize);

  bool get _isMultiSelect => selectedIds != null && onSelectionChanged != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final columns = _isMultiSelect
        ? ['', 'Ad Soyad', 'Geldiği Kurum', 'Evrak Sayısı', dateColumnLabel, 'Durum']
        : ['Ad Soyad', 'Geldiği Kurum', 'Evrak Sayısı', dateColumnLabel, 'Durum'];

    // Açık tema için sütun başlık stili
    final headerStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      color: isLight ? const Color(0xFF1A1A1A) : null,
    );

    // Açık tema için hücre metin stili
    final cellStyle = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 13,
      color: isLight ? const Color(0xFF2A2A2A) : null,
    );

    return Column(
      children: [
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Kayıt bulunamadı.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 0,
                      headingRowColor: WidgetStateProperty.resolveWith((states) {
                        if (isLight) return const Color(0xFFE8EDF4);
                        return null;
                      }),
                      dataRowColor: WidgetStateProperty.resolveWith((states) {
                        if (!isLight) return null;
                        return null;
                      }),
                      columns: [
                        if (_isMultiSelect)
                          DataColumn(label: SizedBox(width: 48)),
                        for (final c in columns)
                          DataColumn(label: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(c, style: headerStyle),
                          )),
                      ],
                      rows: [
                        for (final e in items)
                          DataRow.byIndex(
                            index: items.indexOf(e),
                            color: isLight
                                ? WidgetStateProperty.resolveWith((states) {
                                    // Zebra striping
                                    final idx = items.indexOf(e);
                                    if (idx.isEven) {
                                      return Colors.white;
                                    }
                                    return const Color(0xFFF8F9FC);
                                  })
                                : null,
                            onSelectChanged: _isMultiSelect
                                ? null
                                : (_) => onRowTap(e),
                            cells: [
                              if (_isMultiSelect)
                                DataCell(Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: SizedBox(
                                    width: 40,
                                    child: Checkbox(
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
                                    ),
                                  ),
                                )),
                              DataCell(Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: SizedBox(
                                  width: 180,
                                  child: GestureDetector(
                                    onTap: () => onRowTap(e),
                                    child: Text(e.adSoyad, style: cellStyle, overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              )),
                              DataCell(Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: SizedBox(
                                  width: 200,
                                  child: GestureDetector(
                                    onTap: () => onRowTap(e),
                                    child: Text(e.geldigiKurum ?? '-', style: cellStyle, overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              )),
                              DataCell(Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: SizedBox(
                                  width: 50,
                                  child: GestureDetector(
                                    onTap: () => onRowTap(e),
                                    child: Text(e.evrakSayisi ?? '-', style: cellStyle, overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              )),
                              DataCell(Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: SizedBox(
                                  width: 55,
                                  child: GestureDetector(
                                    onTap: () => onRowTap(e),
                                    child: Text(DateUtil.displayDate(dateGetter(e)), style: cellStyle),
                                  ),
                                ),
                              )),
                              DataCell(Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: SizedBox(
                                  width: 110,
                                  child: GestureDetector(
                                    onTap: () => onRowTap(e),
                                    child: UiUtil.durumChip(context, e.durum),
                                  ),
                                ),
                              )),
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
