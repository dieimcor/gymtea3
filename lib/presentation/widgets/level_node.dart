import 'package:flutter/material.dart';
import 'package:gymtea3/core/theme/app_theme.dart';

/// Nodo visual de un nivel en el mapa de niveles
/// Muestra: número de nivel, estado (bloqueado/actual/completado), progreso
class LevelNode extends StatelessWidget {
  final int level;
  final LevelStatus status;
  final int completedSessions;
  final int requiredSessions;
  final VoidCallback? onTap;

  const LevelNode({
    super.key,
    required this.level,
    required this.status,
    this.completedSessions = 0,
    this.requiredSessions = 5,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: status != LevelStatus.locked ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Círculo principal del nodo
            _buildNodeCircle(),
            const SizedBox(height: 8),
            // Label del nivel
            Text(
              'Nivel $level',
              style: TextStyle(
                fontSize: 13,
                fontWeight: status == LevelStatus.current
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: _labelColor,
              ),
            ),
            // Progreso de sesiones
            if (status == LevelStatus.current) ...[
              const SizedBox(height: 4),
              Text(
                '$completedSessions / $requiredSessions sesiones',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textLight.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNodeCircle() {
    return Container(
      width: status == LevelStatus.current ? 72 : 60,
      height: status == LevelStatus.current ? 72 : 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _backgroundColor,
        border: Border.all(
          color: _borderColor,
          width: status == LevelStatus.current ? 3 : 2,
        ),
        boxShadow: status == LevelStatus.current
            ? [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: status == LevelStatus.locked
            ? Icon(
                Icons.lock_rounded,
                color: Colors.white.withValues(alpha: 0.3),
                size: 24,
              )
            : status == LevelStatus.completed
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 28,
                  )
                : Text(
                    '$level',
                    style: TextStyle(
                      fontSize: status == LevelStatus.current ? 28 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
      ),
    );
  }

  Color get _backgroundColor {
    switch (status) {
      case LevelStatus.completed:
        return AppTheme.primaryGreen;
      case LevelStatus.current:
        return AppTheme.primaryGreen.withValues(alpha: 0.8);
      case LevelStatus.locked:
        return AppTheme.surfaceDark;
    }
  }

  Color get _borderColor {
    switch (status) {
      case LevelStatus.completed:
        return AppTheme.primaryGreen;
      case LevelStatus.current:
        return AppTheme.goldAccent;
      case LevelStatus.locked:
        return Colors.white.withValues(alpha: 0.1);
    }
  }

  Color get _labelColor {
    switch (status) {
      case LevelStatus.completed:
        return AppTheme.primaryGreen;
      case LevelStatus.current:
        return Colors.white;
      case LevelStatus.locked:
        return Colors.white.withValues(alpha: 0.3);
    }
  }
}

/// Estado del nivel
enum LevelStatus {
  completed,
  current,
  locked,
}
