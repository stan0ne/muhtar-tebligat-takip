import 'package:flutter/material.dart';

/// Ana menü öğeleri.
enum MenuPage {
  dashboard('Ana Sayfa', Icons.dashboard_outlined, Icons.dashboard),
  yeniEvrak('Yeni Evrak Kaydı', Icons.note_add_outlined, Icons.note_add),
  ara('Evrak Ara', Icons.search_outlined, Icons.search),
  bekleyen('Bekleyen Evraklar', Icons.hourglass_empty_outlined, Icons.hourglass_empty),
  teslimEdilen('Teslim Edilenler', Icons.check_circle_outline, Icons.check_circle),
  arsivlenen('Arşivlenenler', Icons.archive_outlined, Icons.archive),
  raporlar('Raporlar', Icons.bar_chart_outlined, Icons.bar_chart),
  iceAktarma('İçe Aktarma', Icons.file_upload_outlined, Icons.file_upload),
  yedekleme('Yedekleme', Icons.backup_outlined, Icons.backup),
  ayarlar('Ayarlar', Icons.settings_outlined, Icons.settings);

  final String title;
  final IconData icon;
  final IconData selectedIcon;

  const MenuPage(this.title, this.icon, this.selectedIcon);
}
