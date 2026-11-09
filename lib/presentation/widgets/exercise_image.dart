import 'package:flutter/material.dart';

import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/data/models/exercise_model.dart';

/// Ilustración de un ejercicio.
///
/// Muestra el asset de `exercise.imagenAsset` si existe. Mientras no haya
/// arte para ese ejercicio cae en un placeholder con el nombre, así que
/// basta dejar el PNG en `assets/images/ejercicios/` para que aparezca.
class ExerciseImage extends StatelessWidget {
  final ExerciseModel exercise;
  final double size;
  final BorderRadius? borderRadius;

  const ExerciseImage({
    super.key,
    required this.exercise,
    this.size = 72,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(14);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: radius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        exercise.imagenAsset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: size * 0.28,
            color: AppTheme.goldAccent.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              exercise.nombre,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: size * 0.12,
                height: 1.15,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
