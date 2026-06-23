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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              radius: 26,
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor)),
                  const SizedBox(height: 4),
                  Text('$value',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
