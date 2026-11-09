import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/data/models/routine_model.dart';
import 'package:gymtea3/presentation/providers/exercise_provider.dart';
import 'package:gymtea3/presentation/providers/progress_provider.dart';
import 'package:gymtea3/utils/formatters.dart';

/// Argumentos de la pantalla de calificación.
class RatingScreenArgs {
  final RoutineModel routine;
  final int elapsedSeconds;
  final List<String> completedExerciseIds;

  const RatingScreenArgs({
    required this.routine,
    required this.elapsedSeconds,
    required this.completedExerciseIds,
  });
}

/// "Califica tu progreso" — 1 a 5 estrellas en desempeño, cansancio y
/// motivación. Aparece al terminar el cráter, antes del resumen.
///
/// La calificación se guarda junto al progreso local (`sincronizado = false`)
/// para enviarse al backend cuando exista.
class RatingScreen extends StatefulWidget {
  static const routeName = '/exercises/rating';

  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _desempeno = 0;
  int _cansancio = 0;
  int _motivacion = 0;
  bool _saving = false;
  bool _saved = false;

  RatingScreenArgs? _args;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _args ??= ModalRoute.of(context)?.settings.arguments as RatingScreenArgs?;
  }

  Future<void> _save({required bool withRating}) async {
    final args = _args;
    if (args == null || _saving || _saved) return;

    setState(() => _saving = true);

    await context.read<ProgressProvider>().recordSessionProgress(
          childId: args.routine.childId,
          sessionId: args.routine.id,
          level: args.routine.nivel,
          completedExerciseIds: args.completedExerciseIds,
          elapsedSeconds: args.elapsedSeconds,
          desempeno: withRating ? _desempeno : null,
          cansancio: withRating ? _cansancio : null,
          motivacion: withRating ? _motivacion : null,
        );

    if (!mounted) return;
    await context.read<ExerciseProvider>().completeLevel(args.routine.nivel);

    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;
    if (args == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_saved) return _buildSummary(args);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Image.asset(
                'assets/images/mascota/alien_calificacion.png',
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.emoji_events_rounded,
                  size: 96,
                  color: AppTheme.goldAccent,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '¡Califica tu progreso!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.goldAccent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cráter ${args.routine.nivel} completado',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 28),
              _buildStarRow(
                label: 'Desempeño',
                icon: Icons.fitness_center_rounded,
                value: _desempeno,
                onChanged: (v) => setState(() => _desempeno = v),
              ),
              const SizedBox(height: 16),
              _buildStarRow(
                label: 'Cansancio',
                icon: Icons.battery_3_bar_rounded,
                value: _cansancio,
                onChanged: (v) => setState(() => _cansancio = v),
              ),
              const SizedBox(height: 16),
              _buildStarRow(
                label: 'Motivación',
                icon: Icons.favorite_rounded,
                value: _motivacion,
                onChanged: (v) => setState(() => _motivacion = v),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _save(withRating: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Guardar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              TextButton(
                onPressed: _saving ? null : () => _save(withRating: false),
                child: Text(
                  'Saltar por ahora',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarRow({
    required String label,
    required IconData icon,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.goldAccent),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final star = i + 1;
              final filled = star <= value;
              return Semantics(
                button: true,
                label: '$label $star de 5',
                child: IconButton(
                  iconSize: 36,
                  onPressed: () => onChanged(star),
                  icon: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled
                        ? AppTheme.goldAccent
                        : Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(RatingScreenArgs args) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 64,
                  color: AppTheme.goldAccent,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '¡Cráter conquistado!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cráter ${args.routine.nivel} · ${args.routine.dificultad.label}',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  _buildStat(
                    icon: Icons.timer_outlined,
                    value: Formatters.formatDuration(args.elapsedSeconds),
                    label: 'Duración',
                    color: AppTheme.accentTeal,
                  ),
                  const SizedBox(width: 12),
                  _buildStat(
                    icon: Icons.fitness_center_rounded,
                    value: '${args.completedExerciseIds.length}'
                        '/${args.routine.ejercicios.length}',
                    label: 'Ejercicios',
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(width: 12),
                  _buildStat(
                    icon: Icons.star_rounded,
                    value: _desempeno > 0 ? '$_desempeno/5' : '—',
                    label: 'Desempeño',
                    color: AppTheme.goldAccent,
                  ),
                ],
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(
                    context,
                    ModalRoute.withName('/home'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Volver al mapa',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
