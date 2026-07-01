import 'package:flutter/material.dart';

/// Açık ve koyu tema tanımları.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF0D47A1);

  /// Açık tema metin rengi — koyu ve okunur.
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textMedium = Color(0xFF3A3A3A);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        selectedIconTheme: const IconThemeData(color: primary),
        unselectedIconTheme: const IconThemeData(color: Colors.black54),
        selectedLabelTextStyle: const TextStyle(
          color: primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: _textMedium,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      // Açık tema için genel metin ayarları
      textTheme: const TextTheme(
        // Başlıklar
        headlineLarge: TextStyle(color: _textDark, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: _textDark, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(color: _textDark, fontWeight: FontWeight.w600),
        // Alt başlıklar
        titleLarge: TextStyle(color: _textDark, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: _textDark, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: _textDark, fontWeight: FontWeight.w600),
        // Gövde metinleri
        bodyLarge: TextStyle(color: _textDark, fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(color: _textDark, fontWeight: FontWeight.w500),
        bodySmall: TextStyle(color: _textMedium, fontWeight: FontWeight.w500),
        // Etiketler
        labelLarge: TextStyle(color: _textDark, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: _textDark, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(color: _textMedium, fontWeight: FontWeight.w500),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121417),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Color(0xFF1B1F24),
        selectedIconTheme: IconThemeData(color: Colors.lightBlueAccent),
        unselectedIconTheme: IconThemeData(color: Colors.white54),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF1B1F24),
      ),
    );
  }
}
