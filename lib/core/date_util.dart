import 'package:intl/intl.dart';

/// Tarih/saat yardımcıları.
class DateUtil {
  DateUtil._();

  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _isoDateTime = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _displayDate = DateFormat('dd.MM.yyyy');
  static final DateFormat _displayDateTime = DateFormat('dd.MM.yyyy HH:mm');

  /// Bugünün tarihini ISO (yyyy-MM-dd) olarak döndürür.
  static String todayIso() => _isoDate.format(DateTime.now());

  /// Şimdiki zamanı ISO tam (yyyy-MM-dd HH:mm:ss) olarak döndürür.
  static String nowIso() => _isoDateTime.format(DateTime.now());

  /// ISO tarih/zamanı okunabilir tarihe çevirir.
  static String displayDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      return _displayDate.format(_parse(iso));
    } catch (_) {
      return iso;
    }
  }

  /// ISO tarih/zamanı okunabilir tarih+saate çevirir.
  static String displayDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      return _displayDateTime.format(_parse(iso));
    } catch (_) {
      return iso;
    }
  }

  static DateTime _parse(String iso) {
    if (iso.length <= 10) return DateFormat('yyyy-MM-dd').parse(iso);
    return DateFormat('yyyy-MM-dd HH:mm:ss').parse(iso);
  }

  /// İki ISO tarih aralığını karşılaştırmak için başlangıç bitişi döndürür.
  static (String, String) monthRange(DateTime ref) {
    final start = DateTime(ref.year, ref.month, 1);
    final end = DateTime(ref.year, ref.month + 1, 0, 23, 59, 59);
    return (_isoDate.format(start), _isoDate.format(end));
  }
}
