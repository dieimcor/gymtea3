import 'package:flutter/material.dart';

import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/data/models/exercise_model.dart';
import 'package:gymtea3/data/models/routine_model.dart';
import 'package:gymtea3/presentation/widgets/bouncy_tap.dart';
import 'package:gymtea3/presentation/widgets/equipment_chip.dart';
import 'package:gymtea3/presentation/widgets/exercise_media_slot.dart';

/// Pop-up que se abre al tocar un cráter: muestra los ejercicios que
/// tocaron en ese nivel antes de empezar, al estilo del tablero de
/// Mario Party.
///
/// Entra con un rebote y los ejercicios aparecen uno tras otro (también
/// después de "Sortear"), para que se sienta como abrir un regalo.
///
/// Devuelve `true` si el usuario decide comenzar la rutina.
class CraterPreviewDialog extends StatelessWidget {
  final RoutineModel routine;
  final VoidCallback onReshuffle;
  final bool isReshuffling;

  const CraterPreviewDialog({
    super.key,
    required this.routine,
    required this.onReshuffle,
    this.isReshuffling = false,
  });

  /// Sección "Para este cráter necesitan".
  static const gearKey = Key('crater_preview_gear');

  /// Texto cuando la rutina no pide nada.
  static const noGearText = '¡Nada! Solo ganas de jugar';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.elasticOut,
        builder: (context, t, child) => Transform.scale(
          scale: 0.6 + 0.4 * t,
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        ),
        child: _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldAccent.withValues(alpha: 0.15),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          Flexible(child: _buildExerciseList()),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.goldAccent.withValues(alpha: 0.25),
            AppTheme.accentTeal.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/mascota/alien.png',
                height: 44,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.rocket_launch_rounded,
                  color: AppTheme.goldAccent,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cráter ${routine.nivel}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Dificultad ${routine.dificultad.label}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        if (routine.ruta != null) _buildRoutePill(),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildChip(
                Icons.fitness_center_rounded,
                '${routine.ejercicios.length} ejercicios',
              ),
              const SizedBox(width: 8),
              _buildChip(Icons.repeat_rounded, '${routine.series} series'),
              const SizedBox(width: 8),
              _buildChip(
                Icons.timer_outlined,
                '${routine.exerciseSeconds}s por serie',
              ),
              const SizedBox(width: 8),
              _buildChip(
                Icons.self_improvement_rounded,
                '${routine.restSeconds}s descanso',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Ruta elegida (Explorador, Astronauta, Comandante), en su color.
  Widget _buildRoutePill() {
    final ruta = routine.ruta!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ruta.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ruta.color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ruta.icon, size: 13, color: ruta.color),
          const SizedBox(width: 4),
          Text(
            ruta.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ruta.color,
            ),
          ),
        ],
      ),
    );
  }

  /// Lo que hay que tener a mano, sin repetir (en el orden de la rutina).
  List<String> get _gear {
    final seen = <String>{};
    for (final e in routine.ejercicios) {
      final q = e.queUsar?.trim();
      if (q != null && q.isNotEmpty) seen.add(EquipmentIcons.shortLabel(q));
    }
    return seen.toList();
  }

  /// "Para este cráter necesitan": chips chicos con lo que hay que buscar
  /// antes de empezar. Va al inicio de la lista para que se vea sin
  /// agrandar el pop-up.
  Widget _buildGearSection() {
    final gear = _gear;
    return Container(
      key: CraterPreviewDialog.gearKey,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppTheme.accentTeal.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Para este cráter necesitan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 6),
          if (gear.isEmpty)
            const EquipmentChip(
              label: CraterPreviewDialog.noGearText,
              color: AppTheme.goldAccent,
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final g in gear) EquipmentChip(label: g)],
            ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppTheme.goldAccent),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList() {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      // El primer elemento es la sección de lo que necesitan.
      itemCount: routine.ejercicios.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == 0) return _buildGearSection();
        final index = i - 1;
        final exercise = routine.ejercicios[index];
        return _StaggeredEntry(
          // La key incluye la rutina: al sortear, la lista vuelve a entrar.
          key: ValueKey('${routine.id}-${exercise.id}'),
          index: index,
          child: _buildExerciseRow(index, exercise),
        );
      },
    );
  }

  Widget _buildExerciseRow(int index, ExerciseModel exercise) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.goldAccent.withValues(alpha: 0.2),
          ),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.goldAccent,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ExerciseMediaSlot(
          exercise: exercise,
          width: 64,
          showLabel: false,
          borderRadius: BorderRadius.circular(12),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.nombre,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                exercise.categoriaNombre ?? exercise.categoria,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Text(
            estimatedLabel(routine.estimatedSeconds),
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BouncyTap(
                  child: OutlinedButton.icon(
                    onPressed: isReshuffling ? null : onReshuffle,
                    icon: isReshuffling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.casino_rounded, size: 18),
                    label: const Text('Sortear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: BouncyTap(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('¡Comenzar!'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hace aparecer un elemento de la lista con un pequeño retraso según su
/// [index]: sube, crece y se hace visible.
class _StaggeredEntry extends StatelessWidget {
  final int index;
  final Widget child;

  const _StaggeredEntry({super.key, required this.index, required this.child});

  static const _stepMs = 110;
  static const _itemMs = 420;

  @override
  Widget build(BuildContext context) {
    final delayMs = 150 + index * _stepMs;
    final totalMs = delayMs + _itemMs;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: totalMs),
      curve: Interval(delayMs / totalMs, 1, curve: Curves.easeOutBack),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - t)),
          child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
        ),
      ),
      child: child,
    );
  }
}

/// "El cráter dura unos 7 minutos": la duración en palabras (antes "06:55", que
/// se leía como una hora).
String estimatedLabel(int seconds) {
  final minutes = (seconds / 60).round();
  if (minutes <= 1) return 'El cráter dura cerca de un minuto';
  return 'El cráter dura unos $minutes minutos';
}
