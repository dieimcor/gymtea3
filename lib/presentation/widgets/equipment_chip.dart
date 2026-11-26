import 'package:flutter/material.dart';

import 'package:gymtea3/core/theme/app_theme.dart';

/// Ícono amable para lo que hay que tener a mano en un ejercicio
/// ("Silla firme", "Botella de agua chica", "Toalla: tú tiras…").
///
/// Se elige por la primera palabra clave que aparece en el texto, para que
/// "Sofá o silla firme" muestre el sofá y "Botella de agua chica y una
/// silla" la botella. Si nada calza, una casita (es algo de la casa).
class EquipmentIcons {
  EquipmentIcons._();

  static const Map<String, IconData> _byKeyword = {
    'botella': Icons.local_drink_rounded,
    'pelota': Icons.sports_soccer_rounded,
    'balón': Icons.sports_soccer_rounded,
    'peluche': Icons.toys_rounded,
    'mochila': Icons.backpack_rounded,
    'libro': Icons.menu_book_rounded,
    'toalla': Icons.dry_cleaning_rounded,
    'cojín': Icons.weekend_rounded,
    'cojines': Icons.weekend_rounded,
    'sofá': Icons.weekend_rounded,
    'silla': Icons.chair_rounded,
    'banco': Icons.chair_rounded,
    'mesa': Icons.table_restaurant_rounded,
    'cinta': Icons.straighten_rounded,
    'manos': Icons.pan_tool_rounded,
    'mancuerna': Icons.fitness_center_rounded,
    'kettlebell': Icons.fitness_center_rounded,
    'barra': Icons.fitness_center_rounded,
    'elástico': Icons.fitness_center_rounded,
    'trx': Icons.fitness_center_rounded,
    'rueda': Icons.fitness_center_rounded,
  };

  static IconData forText(String text) {
    final lower = text.toLowerCase();
    IconData best = Icons.home_rounded;
    var bestAt = lower.length + 1;
    _byKeyword.forEach((keyword, icon) {
      final at = lower.indexOf(keyword);
      if (at >= 0 && at < bestAt) {
        bestAt = at;
        best = icon;
      }
    });
    return best;
  }

  /// Versión corta para chips chicos: lo que va antes de los dos puntos
  /// ("Toalla: tú tiras del otro extremo" → "Toalla").
  static String shortLabel(String text) {
    final i = text.indexOf(':');
    return (i > 0 ? text.substring(0, i) : text).trim();
  }
}

/// Chip chico con ícono + texto de lo que hay que tener a mano.
class EquipmentChip extends StatelessWidget {
  final String label;
  final Color color;

  const EquipmentChip({
    super.key,
    required this.label,
    this.color = AppTheme.accentTeal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(EquipmentIcons.forText(label), size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
