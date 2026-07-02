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
    final headerStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      color: isLight ? const Color(0xFF1A1A1A) : null,
    );

    final cellStyle = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 13,
      color: isLight ? const Color(0xFF2A2A2A) : null,
    );

    final allSelected = _isMultiSelect && items.isNotEmpty &&
        items.every((e) => selectedIds!.contains(e.id));

    return Column(
      children: [
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Kayıt bulunamadı.'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;

                    // Checkbox sütunu varsa onu hesaba kat
                    final checkboxColWidth = _isMultiSelect ? 48.0 : 0.0;
                    final usableWidth = availableWidth - checkboxColWidth;

                    final adWidth = usableWidth * 0.28;
                    final kurumWidth = usableWidth * 0.30;
                    final sayiWidth = usableWidth * 0.12;
                    final tarihWidth = usableWidth * 0.14;

                    return SizedBox(
                      width: availableWidth,
                      child: Column(
                          children: [
                            // Başlık satırı
                            Container(
                              height: 44,
                              color: isLight ? const Color(0xFFE8EDF4) : null,
                              child: Row(
                                children: [
                                  if (_isMultiSelect)
                                    SizedBox(
                                      width: checkboxColWidth,
                                      child: Center(
                                        child: Checkbox(
                                          value: allSelected,
                                          tristate: true,
                                          onChanged: (val) {
                                            if (val == true) {
                                              onSelectionChanged!(
                                                  items.map((e) => e.id!).toSet());
                                            } else {
                                              onSelectionChanged!(<int>{});
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  _headerCell('Ad Soyad', adWidth, headerStyle),
                                  _headerCell('Geldiği Kurum', kurumWidth, headerStyle),
                                  _headerCell('Evrak Sayısı', sayiWidth, headerStyle),
                                  _headerCell(dateColumnLabel, tarihWidth, headerStyle),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Text('Durum', style: headerStyle),
                                  ),
                                ],
                              ),
                            ),
                            // Veri satırları
                            Expanded(
                              child: ListView.builder(
                                itemCount: items.length,
                                itemBuilder: (context, idx) {
                                  final e = items[idx];
                                  final isEven = idx.isEven;
                                  final bgColor = isLight
                                      ? (isEven ? Colors.white : const Color(0xFFF8F9FC))
                                      : null;

                                  return GestureDetector(
                                    onTap: () => onRowTap(e),
                                    child: Container(
                                      height: 44,
                                      color: bgColor,
                                      child: Row(
                                        children: [
                                          if (_isMultiSelect)
                                            SizedBox(
                                              width: checkboxColWidth,
                                              child: Center(
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
                                            ),
                                          _dataCell(e.adSoyad, adWidth, cellStyle),
                                          _dataCell(e.geldigiKurum ?? '-', kurumWidth, cellStyle),
                                          _dataCell(e.evrakSayisi ?? '-', sayiWidth, cellStyle),
                                          _dataCell(DateUtil.displayDate(dateGetter(e)), tarihWidth, cellStyle),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: UiUtil.durumChip(context, e.durum),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                  },
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

  Widget _headerCell(String text, double width, TextStyle style) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(text, style: style),
      ),
    );
  }

  Widget _dataCell(String text, double width, TextStyle style) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Tooltip(
          message: text,
          waitDuration: const Duration(seconds: 1),
          child: Text(
            text,
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
