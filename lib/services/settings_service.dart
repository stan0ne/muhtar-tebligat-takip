import 'package:shared_preferences/shared_preferences.dart';

/// Basit anahtar-değer ayar servisi (SharedPreferences).
class SettingsService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<String?> get(String key) async => (await _p).getString(key);

  Future<bool> set(String key, String value) async =>
      (await _p).setString(key, value);

  Future<bool> getBool(String key, {bool def = false}) async =>
      (await _p).getBool(key) ?? def;

  Future<bool> setBool(String key, bool value) async =>
      (await _p).setBool(key, value);

  Future<bool> remove(String key) async => (await _p).remove(key);
}
