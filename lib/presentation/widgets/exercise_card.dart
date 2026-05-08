import 'package:flutter/material.dart';
import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/data/models/exercise_model.dart';

/// Tarjeta visual de un ejercicio durante la sesión activa
/// Muestra: nombre, descripción, categoría color-coded, series/reps
class ExerciseCard extends StatelessWidget {
  final ExerciseModel exercise;
  final int currentSet;
  final int totalSets;
  final int reps;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onComplete;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.currentSet = 1,
    this.totalSets = 3,
    this.reps = 10,
    this.isActive = false,
    this.isCompleted = false,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(exercise.categoria);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? categoryColor.withValues(alpha: 0.12)
            : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? categoryColor.withValues(alpha: 0.4)
              : isCompleted
                  ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.06),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  exercise.categoriaNombre ?? exercise.categoria,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: categoryColor,
                  ),
                ),
              ),
              const Spacer(),
              // Series/reps badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$totalSets × $reps',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
              if (isCompleted) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // Exercise name
          Text(
            exercise.nombre,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isCompleted
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          // Description
          Text(
            exercise.descripcion,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: isCompleted ? 0.3 : 0.5),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Active state: show set progress + complete button
          if (isActive) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                // Set progress dots
                ...List.generate(totalSets, (index) {
                  final isDone = index < currentSet - 1;
                  final isCurrent = index == currentSet - 1;
                  return Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? categoryColor
                          : isCurrent
                              ? categoryColor.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.06),
                      border: isCurrent
                          ? Border.all(color: categoryColor, width: 2)
                          : null,
                    ),
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : isCurrent
                            ? Center(
                                child: Text(
                                  '$currentSet',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: categoryColor,
                                  ),
                                ),
                              )
                            : null,
                  );
                }),
                const Spacer(),
                // Complete set button
                if (onComplete != null)
                  ElevatedButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      currentSet >= totalSets ? 'Listo' : 'Serie $currentSet',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: categoryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'RD':
        return AppTheme.categoryRD;
      case 'CD':
        return AppTheme.categoryCD;
      case 'EM':
        return AppTheme.categoryEM;
      case 'JL':
        return AppTheme.categoryJL;
      case 'CR':
        return AppTheme.categoryCR;
      case 'ACT':
        return const Color(0xFF26C6DA);
      case 'JUEGO':
        return AppTheme.goldAccent;
      default:
        return AppTheme.accentTeal;
    }
  }
}
