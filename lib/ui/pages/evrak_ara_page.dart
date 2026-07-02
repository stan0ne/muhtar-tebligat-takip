import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../data/models/evrak.dart';
import '../../data/repositories/evrak_repository.dart' show EvrakFilter;
import '../../services/log_service.dart';
import '../pages/evrak_detail_page.dart';
import 'widgets/evrak_data_table.dart';

/// Evrak arama ekranı: canlı filtre + sayfalama.
class EvrakAraPage extends StatefulWidget {
  final String hizliArama;
  const EvrakAraPage({super.key, this.hizliArama = ''});

  @override
  State<EvrakAraPage> createState() => _EvrakAraPageState();
}

class _EvrakAraPageState extends State<EvrakAraPage> {
  final _adCtrl = TextEditingController();
  final _sayiCtrl = TextEditingController();
  final _kurumCtrl = TextEditingController();
  final _teslimAlanCtrl = TextEditingController();
  final _tcCtrl = TextEditingController();
  final _telefonCtrl = TextEditingController();
  final _basCtrl = TextEditingController();
  final _sonCtrl = TextEditingController();
  String? _durum;
  late String _hizliArama;

  List<Evrak> _items = [];
  int _total = 0;
  int _page = 1;
  final int _pageSize = AppConstants.defaultPageSize;
  bool _loading = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _hizliArama = widget.hizliArama;
    for (final c in [_adCtrl, _sayiCtrl, _kurumCtrl, _teslimAlanCtrl, _tcCtrl, _telefonCtrl]) {
      c.addListener(_onChanged);
    }
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _adCtrl.dispose();
    _sayiCtrl.dispose();
    _kurumCtrl.dispose();
    _teslimAlanCtrl.dispose();
    _tcCtrl.dispose();
    _telefonCtrl.dispose();
    _basCtrl.dispose();
    _sonCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _page = 1;
      _hizliArama = '';
      _search();
    });
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      // Display formatındaki tarihleri ISO formatına çevir
      String? toIso(String? display) {
        if (display == null || display.isEmpty) return null;
        try {
          return DateFormat('yyyy-MM-dd').format(DateFormat('dd-MM-yyyy').parse(display));
        } catch (_) {
          return display;
        }
      }

      final filter = EvrakFilter(
        adSoyad: _adCtrl.text.trim().isEmpty ? null : _adCtrl.text.trim(),
        evrakSayisi: _sayiCtrl.text.trim().isEmpty ? null : _sayiCtrl.text.trim(),
        geldigiKurum: _kurumCtrl.text.trim().isEmpty ? null : _kurumCtrl.text.trim(),
        teslimAlan: _teslimAlanCtrl.text.trim().isEmpty ? null : _teslimAlanCtrl.text.trim(),
        tcKimlikNo: _tcCtrl.text.trim().isEmpty ? null : _tcCtrl.text.trim(),
        telefon: _telefonCtrl.text.trim().isEmpty ? null : _telefonCtrl.text.trim(),
        durum: _durum,
        tarihBaslangic: toIso(_basCtrl.text),
        tarihBitis: toIso(_sonCtrl.text),
        hizliArama: _hizliArama.isNotEmpty ? _hizliArama : null,
      );
      final res = await Services.evrak.search(
          filter: filter, page: _page, pageSize: _pageSize);
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
          SnackBar(content: Text('Arama hatası: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    DateTime initial;
    try {
      initial = DateFormat('dd-MM-yyyy').parse(ctrl.text);
    } catch (_) {
      initial = DateTime.now();
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      ctrl.text = DateFormat('dd-MM-yyyy').format(picked);
      _page = 1;
      _search();
    }
  }

  void _clear() {
    _adCtrl.clear();
    _sayiCtrl.clear();
    _kurumCtrl.clear();
    _teslimAlanCtrl.clear();
    _tcCtrl.clear();
    _telefonCtrl.clear();
    _basCtrl.clear();
    _sonCtrl.clear();
    setState(() {
      _durum = null;
      _hizliArama = '';
    });
    _page = 1;
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Filtreler kartı
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.filter_list, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Arama Filtreleri', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: _clear,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Temizle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Satır 1: Kişisel Bilgiler
                  Row(
                    children: [
                      Expanded(child: _filterField(_adCtrl, 'Ad Soyad', Icons.person)),
                      const SizedBox(width: 12),
                      Expanded(child: _filterField(_sayiCtrl, 'Evrak Sayısı', Icons.numbers)),
                      const SizedBox(width: 12),
                      Expanded(child: _filterField(_kurumCtrl, 'Geldiği Kurum', Icons.account_balance)),
                      const SizedBox(width: 12),
                      Expanded(child: _filterField(_teslimAlanCtrl, 'Teslim Alan', Icons.how_to_reg)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Satır 2: İletişim + Tarih + Durum
                  Row(
                    children: [
                      Expanded(child: _filterField(_tcCtrl, 'TC Kimlik No', Icons.badge)),
                      const SizedBox(width: 12),
                      Expanded(child: _filterField(_telefonCtrl, 'Telefon', Icons.phone)),
                      const SizedBox(width: 12),
                      Expanded(child: _filterField(_basCtrl, 'Başlangıç Tarihi', Icons.calendar_today, readOnly: true, onTap: () => _pickDate(_basCtrl))),
                      const SizedBox(width: 12),
                      Expanded(child: _filterField(_sonCtrl, 'Bitiş Tarihi', Icons.calendar_today, readOnly: true, onTap: () => _pickDate(_sonCtrl))),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 160,
                        child: DropdownButtonFormField<String>(
                          initialValue: _durum,
                          decoration: const InputDecoration(
                            labelText: 'Durum',
                            isDense: true,
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.flag, size: 20),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Tümü')),
                            for (final d in EvrakDurum.all)
                              DropdownMenuItem(value: d, child: Text(d)),
                          ],
                          onChanged: (v) {
                            setState(() => _durum = v);
                            _page = 1;
                            _search();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              children: [
                EvrakDataTable(
                  items: _items,
                  total: _total,
                  page: _page,
                  pageSize: _pageSize,
                  onPage: (p) {
                    _page = p;
                    _search();
                  },
                  onRowTap: (e) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => EvrakDetailPage(evrakId: e.id!),
                    ));
                  },
                ),
                if (_loading)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterField(TextEditingController ctrl, String label, IconData icon,
      {bool readOnly = false, VoidCallback? onTap}) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onTap: onTap,
    );
  }
}
