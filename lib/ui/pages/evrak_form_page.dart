import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/date_util.dart';
import '../../data/models/evrak.dart';
import '../../services/log_service.dart';

/// Yeni evrak kaydı / mevcut evrak düzenleme ekranı.
class EvrakFormPage extends StatefulWidget {
  final Evrak? evrak;
  const EvrakFormPage({super.key, this.evrak});

  @override
  State<EvrakFormPage> createState() => _EvrakFormPageState();
}

class _EvrakFormPageState extends State<EvrakFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _gelisCtrl;
  final _adCtrl = TextEditingController();
  final _kurumCtrl = TextEditingController();
  final _sayiCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.evrak;
    // ISO formatını display formatına çevir (DD-MM-YYYY)
    final gelisTarihi = e?.gelisTarihi ?? DateUtil.todayIso();
    _gelisCtrl = TextEditingController(text: DateUtil.displayDate(gelisTarihi));
    _adCtrl.text = e?.adSoyad ?? '';
    _kurumCtrl.text = e?.geldigiKurum ?? '';
    _sayiCtrl.text = e?.evrakSayisi ?? '';
  }

  @override
  void dispose() {
    _gelisCtrl.dispose();
    _adCtrl.dispose();
    _kurumCtrl.dispose();
    _sayiCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime initial;
    try {
      initial = DateFormat('dd-MM-yyyy').parse(_gelisCtrl.text);
    } catch (_) {
      initial = DateTime.now();
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _gelisCtrl.text = DateFormat('dd-MM-yyyy').format(picked);
    }
  }

  /// Display formatındaki tarihi ISO formatına çevir.
  String _toIsoDate(String displayDate) {
    try {
      return DateFormat('yyyy-MM-dd').format(DateFormat('dd-MM-yyyy').parse(displayDate));
    } catch (_) {
      return displayDate;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final gelisTarihiIso = _toIsoDate(_gelisCtrl.text.trim());
      if (widget.evrak == null) {
        await Services.evrak.ekle(
          gelisTarihi: gelisTarihiIso,
          adSoyad: _adCtrl.text,
          geldigiKurum: _kurumCtrl.text,
          evrakSayisi: _sayiCtrl.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evrak kaydedildi (Bekliyor).')),
          );
          _adCtrl.clear();
          _kurumCtrl.clear();
          _sayiCtrl.clear();
          _gelisCtrl.text = DateUtil.displayDate(DateUtil.todayIso());
        }
      } else {
        final updated = widget.evrak!.copyWith(
          gelisTarihi: gelisTarihiIso,
          adSoyad: _adCtrl.text,
          geldigiKurum: _kurumCtrl.text,
          evrakSayisi: _sayiCtrl.text,
        );
        await Services.evrak.guncelle(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evrak güncellendi.')),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.evrak != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: FocusTraversalGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isEdit ? 'Evrak Düzenle' : 'Yeni Evrak Kaydı',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _adCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Ad Soyad *',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Ad Soyad zorunlu'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _kurumCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Geldiği Kurum',
                          prefixIcon: Icon(Icons.account_balance),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sayiCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Evrak Sayısı',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _gelisCtrl,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Geliş Tarihi',
                                prefixIcon: const Icon(Icons.event),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Tarih zorunlu'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton.outlined(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today),
                            tooltip: 'Tarih Seç',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: const Icon(Icons.save),
                              label: Text(isEdit ? 'Güncelle' : 'Kaydet'),
                            ),
                          ),
                          if (isEdit) ...[
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('İptal'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
