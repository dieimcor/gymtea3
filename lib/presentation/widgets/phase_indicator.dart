import 'package:flutter/material.dart';
import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/data/models/exercise_model.dart';

/// Indicador horizontal de progreso de las 3 fases de sesión
/// Activación → Fortalecimiento → Juego
class PhaseIndicator extends StatelessWidget {
  final FaseSesion currentPhase;

  const PhaseIndicator({
    super.key,
    required this.currentPhase,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          _buildPhaseChip(
            label: 'Activación',
            icon: Icons.directions_run_rounded,
            phase: FaseSesion.activacion,
            color: const Color(0xFF26C6DA), // Cyan
          ),
          _buildConnector(FaseSesion.activacion),
          _buildPhaseChip(
            label: 'Fuerza',
            icon: Icons.fitness_center_rounded,
            phase: FaseSesion.fortalecimiento,
            color: AppTheme.primaryGreen,
          ),
          _buildConnector(FaseSesion.fortalecimiento),
          _buildPhaseChip(
            label: 'Juego',
            icon: Icons.sports_esports_rounded,
            phase: FaseSesion.juego,
            color: AppTheme.goldAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseChip({
    required String label,
    required IconData icon,
    required FaseSesion phase,
    required Color color,
  }) {
    final isActive = currentPhase == phase;
    final isPast = phase.index < currentPhase.index;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.2)
              : isPast
                  ? color.withValues(alpha: 0.08)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(color: color.withValues(alpha: 0.5))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPast ? Icons.check_circle_rounded : icon,
              color: isActive
                  ? color
                  : isPast
                      ? color.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.25),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? color
                    : isPast
                        ? color.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.25),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnector(FaseSesion phase) {
    final isPast = phase.index < currentPhase.index;
    return Container(
      width: 20,
      height: 2,
      color: isPast
          ? AppTheme.primaryGreen.withValues(alpha: 0.5)
          : Colors.white.withValues(alpha: 0.1),
    );
  }
}
