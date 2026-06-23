import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../data/models/user.dart';
import '../../../services/log_service.dart';

/// Kullanıcı ekleme/düzenleme diyaloğu.
/// `user` null ise yeni kullanıcı; dolu ise düzenleme (parola isteğe bağlı).
class UserDialog extends StatefulWidget {
  final User? user;
  const UserDialog({super.key, this.user});

  @override
  State<UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _adiCtrl = TextEditingController();
  final _adSoyadCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();
  String _rol = UserRole.personel;
  bool _aktif = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      final u = widget.user!;
      _adiCtrl.text = u.kullaniciAdi;
      _adSoyadCtrl.text = u.adSoyad ?? '';
      _rol = u.rol;
      _aktif = u.aktif;
    }
  }

  @override
  void dispose() {
    _adiCtrl.dispose();
    _adSoyadCtrl.dispose();
    _sifreCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.user == null) {
        await Services.auth.createUser(
          kullaniciAdi: _adiCtrl.text.trim(),
          sifre: _sifreCtrl.text,
          rol: _rol,
          adSoyad: _adSoyadCtrl.text.trim().isEmpty ? null : _adSoyadCtrl.text.trim(),
        );
      } else {
        final u = widget.user!;
        await Services.auth.updateUser(User(
          id: u.id,
          kullaniciAdi: _adiCtrl.text.trim(),
          sifreHash: u.sifreHash,
          rol: _rol,
          adSoyad: _adSoyadCtrl.text.trim().isEmpty ? null : _adSoyadCtrl.text.trim(),
          aktif: _aktif,
          olusturmaTarihi: u.olusturmaTarihi,
          guncellemeTarihi: u.guncellemeTarihi,
        ));
        // Parola girildiyse değiştir.
        if (_sifreCtrl.text.isNotEmpty) {
          await Services.auth.changePassword(u.id!, _sifreCtrl.text);
        }
      }
      if (mounted) Navigator.of(context).pop(true);
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
    final isEdit = widget.user != null;
    return AlertDialog(
      title: Text(isEdit ? 'Kullanıcı Düzenle' : 'Yeni Kullanıcı'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _adiCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı Adı *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Zorunlu alan'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _adSoyadCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _rol,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final r in UserRole.all)
                      DropdownMenuItem(value: r, child: Text(r)),
                  ],
                  onChanged: (v) => setState(() => _rol = v ?? UserRole.personel),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sifreCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: isEdit
                        ? 'Yeni Parola (boşsa değişmez)'
                        : 'Parola *',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (!isEdit && (v == null || v.isEmpty)) {
                      return 'Zorunlu alan';
                    }
                    return null;
                  },
                ),
                if (isEdit)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aktif'),
                    value: _aktif,
                    onChanged: (v) => setState(() => _aktif = v),
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
