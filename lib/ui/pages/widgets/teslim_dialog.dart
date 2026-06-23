import 'package:flutter/material.dart';
import '../../../services/log_service.dart';

/// Teslim alma diyaloğu.
class TeslimDialog extends StatefulWidget {
  final int evrakId;
  const TeslimDialog({super.key, required this.evrakId});

  @override
  State<TeslimDialog> createState() => _TeslimDialogState();
}

class _TeslimDialogState extends State<TeslimDialog> {
  final _formKey = GlobalKey<FormState>();
  final _alanCtrl = TextEditingController();
  final _tcCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _aciklamaCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _alanCtrl.dispose();
    _tcCtrl.dispose();
    _telCtrl.dispose();
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await Services.evrak.teslimEt(
        evrakId: widget.evrakId,
        teslimAlanAdSoyad: _alanCtrl.text,
        tcKimlikNo: _tcCtrl.text,
        telefon: _telCtrl.text,
        aciklama: _aciklamaCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teslim edildi olarak kaydedildi.')),
        );
        Navigator.of(context).pop(true);
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
    return AlertDialog(
      title: const Text('Teslim Et'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _alanCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Teslim Alan Ad Soyad *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Zorunlu alan'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tcCtrl,
                  decoration: const InputDecoration(
                    labelText: 'T.C. Kimlik No',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _aciklamaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
