import 'package:flutter/material.dart';

/// UI yardımcıları: durum renkleri, ortak widget'lar.
class UiUtil {
  UiUtil._();

  /// Durum etiket rengini döndürür.
  static Color durumColor(BuildContext ctx, String durum) {
    switch (durum) {
      case 'Bekliyor':
        return Colors.orange.shade700;
      case 'Teslim Edildi':
        return Colors.green.shade700;
      case 'Arşivlendi':
        return Colors.blueGrey.shade500;
      default:
        return Theme.of(ctx).disabledColor;
    }
  }

  /// Durum etiketi (chip).
  static Widget durumChip(BuildContext ctx, String durum) {
    final color = durumColor(ctx, durum);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        durum,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  static InputDecoration fieldDecoration(BuildContext ctx, String label,
      {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  /// Bilgi kartı (dashboard için).
  static Widget infoCard(
    BuildContext ctx, {
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(ctx);
    final screenWidth = MediaQuery.of(ctx).size.width;
    final scale = (screenWidth / 1170).clamp(0.8, 1.5);

    final iconSize = 26 * scale;
    final avatarRadius = 26 * scale;
    final padding = 20 * scale;
    final spacing = 16 * scale;
    final titleSize = 12 * scale;
    final valueSize = 28 * scale;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              radius: avatarRadius,
              child: Icon(icon, color: color, size: iconSize),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: TextStyle(
                        color: theme.hintColor,
                        fontSize: titleSize,
                      )),
                  const SizedBox(height: 6),
                  Text('$value',
                      style: TextStyle(
                        fontSize: valueSize,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
