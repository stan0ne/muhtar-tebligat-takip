import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/log_service.dart';

/// Uygulama durumu: tema, otomatik yedek.
class AppProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _autoBackup = false;

  ThemeMode get themeMode => _themeMode;
  bool get autoBackup => _autoBackup;

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
}
