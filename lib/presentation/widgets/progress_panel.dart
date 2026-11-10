import 'package:flutter/material.dart';

import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/data/services/level_progress_service.dart';

/// Panel de avance del mapa.
///
/// Ocupa el cielo sobre el cometa con lo que de verdad importa: cuánto
/// se lleva del total y el acumulado de entrenamiento.
class ProgressPanel extends StatelessWidget {
  final int completed;
  final int total;
  final TrainingStats stats;

  const ProgressPanel({
    super.key,
    required this.completed,
    required this.total,
    required this.stats,
  });

  double get _progress => total == 0 ? 0 : completed / total;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          _buildBar(),
          const SizedBox(height: 14),
          _buildStats(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Icon(Icons.flag_rounded, size: 18, color: AppTheme.goldAccent),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Tu progreso',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          '$completed',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.goldAccent,
            height: 1,
          ),
        ),
        Text(
          ' / $total cráteres',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildBar() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 9,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.goldAccent),
          ),
        ),
        const SizedBox(height: 5),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(_progress * 100).round()}% del viaje',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _buildStat(
          icon: Icons.fitness_center_rounded,
          value: '${stats.exercises}',
          label: 'ejercicios',
          color: AppTheme.primaryGreen,
        ),
        _divider(),
        _buildStat(
          icon: Icons.timer_outlined,
          value: _formatTime(stats.seconds),
          label: 'entrenando',
          color: AppTheme.accentTeal,
        ),
        _divider(),
        _buildStat(
          icon: Icons.local_fire_department_rounded,
          value: '${stats.sessions}',
          label: stats.sessions == 1 ? 'sesión' : 'sesiones',
          color: const Color(0xFFE2553C),
        ),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 30,
        color: Colors.white.withValues(alpha: 0.08),
      );

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// "0 min" · "45 min" · "1h 05m"
  static String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return '${hours}h ${rest.toString().padLeft(2, '0')}m';
  }
}
