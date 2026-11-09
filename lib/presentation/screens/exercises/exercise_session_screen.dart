import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gymtea3/core/constants/app_constants.dart';
import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/data/models/exercise_model.dart';
import 'package:gymtea3/data/models/routine_model.dart';
import 'package:gymtea3/presentation/providers/exercise_provider.dart';
import 'package:gymtea3/presentation/screens/exercises/rating_screen.dart';
import 'package:gymtea3/presentation/widgets/exercise_image.dart';
import 'package:gymtea3/presentation/widgets/session_timer_widget.dart';
import 'package:gymtea3/utils/formatters.dart';

/// Un paso de la rutina: una serie de un ejercicio, o un descanso.
class _Block {
  final ExerciseModel exercise;
  final int serie;
  final bool isRest;
  final int seconds;

  const _Block({
    required this.exercise,
    required this.serie,
    required this.isRest,
    required this.seconds,
  });
}

/// Sesión activa de un cráter.
///
/// Lista plana de ejercicios: N ejercicios × 2 series × 60s, con descansos
/// incrementales según la dificultad. Sin fases y sin configuración de
/// tiempos — los define el cráter.
class ExerciseSessionScreen extends StatefulWidget {
  const ExerciseSessionScreen({super.key});

  @override
  State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen> {
  RoutineModel? _routine;
  List<_Block> _blocks = const [];
  int _blockIndex = 0;
  int _elapsedSeconds = 0;

  final GlobalKey<SessionTimerWidgetState> _timerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRoutine());
  }

  void _loadRoutine() {
    final routine = context.read<ExerciseProvider>().previewRoutine;
    if (routine == null) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _routine = routine;
      _blocks = _buildBlocks(routine);
    });
  }

  /// Arma la secuencia: serie → descanso → serie → … sin descanso final.
  List<_Block> _buildBlocks(RoutineModel routine) {
    final blocks = <_Block>[];

    for (final exercise in routine.ejercicios) {
      for (var serie = 1; serie <= routine.series; serie++) {
        blocks.add(_Block(
          exercise: exercise,
          serie: serie,
          isRest: false,
          seconds: AppConstants.exerciseSeconds,
        ));
        blocks.add(_Block(
          exercise: exercise,
          serie: serie,
          isRest: true,
          seconds: routine.restSeconds,
        ));
      }
    }

    // El último descanso sobra.
    if (blocks.isNotEmpty && blocks.last.isRest) {
      blocks.removeLast();
    }
    return blocks;
  }

  _Block? get _currentBlock =>
      _blockIndex < _blocks.length ? _blocks[_blockIndex] : null;

  /// Ejercicios ya terminados (sus dos series completas).
  ///
  /// [upTo] es el indice del primer bloque que todavia NO cuenta. Al
  /// terminar la rutina hay que incluir el ultimo bloque, que si se hizo.
  Set<String> _completedExerciseIds(int upTo) {
    final routine = _routine;
    if (routine == null) return {};

    final done = <String>{};
    for (var i = 0; i < upTo && i < _blocks.length; i++) {
      final block = _blocks[i];
      if (block.isRest || block.serie != routine.series) continue;
      done.add(block.exercise.id);
    }
    return done;
  }

  double get _progress =>
      _blocks.isEmpty ? 0 : _blockIndex / _blocks.length;

  void _advance() {
    _elapsedSeconds += _timerKey.currentState?.elapsedSeconds ?? 0;

    if (_blockIndex >= _blocks.length - 1) {
      _finish();
      return;
    }
    setState(() => _blockIndex++);
  }

  Future<void> _finish() async {
    final routine = _routine;
    if (routine == null) return;

    await Navigator.pushReplacementNamed(
      context,
      RatingScreen.routeName,
      arguments: RatingScreenArgs(
        routine: routine,
        elapsedSeconds: _elapsedSeconds,
        // +1: el bloque actual es el ultimo y tambien se completo.
        completedExerciseIds: _completedExerciseIds(_blockIndex + 1).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routine = _routine;
    final block = _currentBlock;

    if (routine == null || block == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitConfirmation();
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Cráter ${routine.nivel} · ${routine.dificultad.label}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: _showExitConfirmation,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildProgressBar(routine),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildBlockHeader(routine, block),
                      const SizedBox(height: 16),
                      if (!block.isRest)
                        ExerciseImage(
                          exercise: block.exercise,
                          size: 140,
                          borderRadius: BorderRadius.circular(24),
                        )
                      else
                        _buildRestIllustration(),
                      const SizedBox(height: 20),
                      SessionTimerWidget(
                        key: ValueKey(_blockIndex),
                        durationSeconds: block.seconds,
                        isRest: block.isRest,
                        label: block.isRest
                            ? 'Descansa y respira'
                            : block.exercise.nombre,
                        onComplete: _advance,
                        autoStart: block.isRest,
                      ),
                      const SizedBox(height: 12),
                      if (!block.isRest)
                        Text(
                          block.exercise.descripcion,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _buildControls(block),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(RoutineModel routine) {
    final exerciseNumber = routine.ejercicios.indexOf(_currentBlock!.exercise) + 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.goldAccent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ejercicio $exerciseNumber de ${routine.ejercicios.length}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockHeader(RoutineModel routine, _Block block) {
    final color = block.isRest ? AppTheme.accentTeal : AppTheme.primaryGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        block.isRest
            ? 'Descanso · ${block.seconds}s'
            : 'Serie ${block.serie} de ${routine.series}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRestIllustration() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.accentTeal.withValues(alpha: 0.12),
      ),
      child: Image.asset(
        'assets/images/mascota/alien.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.self_improvement_rounded,
          size: 64,
          color: AppTheme.accentTeal,
        ),
      ),
    );
  }

  Widget _buildControls(_Block block) {
    final timer = _timerKey.currentState;
    final isRunning = timer?.isRunning ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                _timerKey.currentState?.toggle();
                setState(() {});
              },
              icon: Icon(
                isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(isRunning ? 'Pausar' : 'Iniciar'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isRunning ? Colors.white.withValues(alpha: 0.12) : null,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: _advance,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _blockIndex >= _blocks.length - 1
                    ? 'Terminar'
                    : block.isRest
                        ? 'Saltar'
                        : 'Listo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Salir del cráter?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Llevas ${Formatters.formatDuration(_elapsedSeconds)} de entrenamiento. '
          'Si sales ahora, esta rutina no se guardará.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Seguir entrenando'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: Text('Salir', style: TextStyle(color: AppTheme.levelLow)),
          ),
        ],
      ),
    );
  }
}
