import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/models/user.dart';
import '../../services/log_service.dart';

/// Uygulama durumu: auth, tema, otomatik yedek.
class AppProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _autoBackup = false;
  User? _user;

  ThemeMode get themeMode => _themeMode;
  bool get autoBackup => _autoBackup;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  Future<void> init() async {
    final modeStr = await Services.settings.get(AppConstants.prefThemeMode);
    if (modeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (modeStr == 'light') {
      _themeMode = ThemeMode.light;
    }
    _autoBackup = await Services.settings.getBool(AppConstants.prefAutoBackup);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final s = mode == ThemeMode.dark
        ? 'dark'
        : (mode == ThemeMode.light ? 'light' : 'system');
    await Services.settings.set(AppConstants.prefThemeMode, s);
    notifyListeners();
  }

  Future<void> setAutoBackup(bool v) async {
    _autoBackup = v;
    await Services.settings.setBool(AppConstants.prefAutoBackup, v);
    notifyListeners();
  }

  Future<User?> login(String kullaniciAdi, String sifre) async {
    final u = await Services.auth.login(kullaniciAdi, sifre);
    if (u != null) {
      _user = u;
      if (_autoBackup) {
        try {
          await Services.backup.maybeAutoBackup();
        } catch (_) {}
      }
      notifyListeners();
    }
    return u;
  }

  Future<void> logout() async {
    await Services.auth.logout();
    _user = null;
    notifyListeners();
  }

  void refreshUser(User u) {
    _user = u;
    notifyListeners();
  }
}
