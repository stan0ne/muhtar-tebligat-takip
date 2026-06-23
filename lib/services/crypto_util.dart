import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Şifre hashleme yardımcısı (SHA-256 + tuz).
class CryptoUtil {
  CryptoUtil._();

  static const String _salt = 'muhtar_tebligat_2026';

  static String hash(String password) {
    final bytes = utf8.encode('$_salt::$password');
    return sha256.convert(bytes).toString();
  }

  static bool verify(String password, String hashStr) =>
      hash(password) == hashStr;
}
