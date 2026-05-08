import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/data/models/exercise_model.dart';
import 'package:gymtea3/data/models/session_model.dart';
import 'package:gymtea3/presentation/providers/auth_provider.dart';
import 'package:gymtea3/presentation/providers/exercise_provider.dart';
import 'package:gymtea3/presentation/providers/progress_provider.dart';
import 'package:gymtea3/presentation/widgets/phase_indicator.dart';
import 'package:gymtea3/presentation/widgets/exercise_card.dart';
import 'package:gymtea3/presentation/widgets/session_timer_widget.dart';

/// Pantalla de sesión activa con 3 fases secuenciales
/// Activación (2 min) → Fortalecimiento (8 min) → Juego (5 min)
class ExerciseSessionScreen extends StatefulWidget {
  const ExerciseSessionScreen({super.key});

  @override
  State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen> {
  SessionModel? _session;
  FaseSesion _currentPhase = FaseSesion.activacion;
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  bool _isLoading = true;
  bool _sessionCompleted = false;
  int _totalElapsedSeconds = 0;
  final List<String> _completedExerciseIds = [];

  final GlobalKey<SessionTimerWidgetState> _timerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSession());
  }

  Future<void> _loadSession() async {
    final level = ModalRoute.of(context)?.settings.arguments as int? ??
        context.read<AuthProvider>().childLevel;

    final exerciseProvider = context.read<ExerciseProvider>();
    final session = await exerciseProvider.buildSession(
      childId: context.read<AuthProvider>().currentChild?.id ?? 'mock-child',
      level: level,
    );

    setState(() {
      _session = session;
      _isLoading = false;
    });
  }

  List<ExerciseModel> get _currentExercises {
    if (_session == null) return [];
    switch (_currentPhase) {
      case FaseSesion.activacion:
        return _session!.ejerciciosActivacion;
      case FaseSesion.fortalecimiento:
        return _session!.ejerciciosFortalecimiento;
      case FaseSesion.juego:
        return _session!.juego != null ? [_session!.juego!] : [];
    }
  }

  int get _currentPhaseSets {
    switch (_currentPhase) {
      case FaseSesion.activacion:
        return SessionModel.activacionSeries;
      case FaseSesion.fortalecimiento:
        return SessionModel.fortalecimientoSeries;
      case FaseSesion.juego:
        return 1;
    }
  }

  int get _currentPhaseReps {
    switch (_currentPhase) {
      case FaseSesion.activacion:
        return SessionModel.activacionReps;
      case FaseSesion.fortalecimiento:
        return SessionModel.fortalecimientoReps;
      case FaseSesion.juego:
        return 1;
    }
  }

  int get _phaseDurationSeconds {
    switch (_currentPhase) {
      case FaseSesion.activacion:
        return 2 * 60;
      case FaseSesion.fortalecimiento:
        return 8 * 60;
      case FaseSesion.juego:
        return 5 * 60;
    }
  }

  void _completeSet() {
    final exercises = _currentExercises;
    if (exercises.isEmpty) return;

    final totalSets = _currentPhaseSets;

    if (_currentSet < totalSets) {
      // Next set
      setState(() => _currentSet++);
    } else {
      // Exercise complete
      _completedExerciseIds.add(exercises[_currentExerciseIndex].id);

      if (_currentExerciseIndex < exercises.length - 1) {
        // Next exercise
        setState(() {
          _currentExerciseIndex++;
          _currentSet = 1;
        });
      } else {
        // Phase complete
        _advancePhase();
      }
    }
  }

  void _advancePhase() {
    // Accumulate elapsed time from timer
    _totalElapsedSeconds += _timerKey.currentState?.elapsedSeconds ?? 0;

    if (_currentPhase == FaseSesion.activacion) {
      setState(() {
        _currentPhase = FaseSesion.fortalecimiento;
        _currentExerciseIndex = 0;
        _currentSet = 1;
      });
    } else if (_currentPhase == FaseSesion.fortalecimiento) {
      setState(() {
        _currentPhase = FaseSesion.juego;
        _currentExerciseIndex = 0;
        _currentSet = 1;
      });
    } else {
      // Session complete!
      _totalElapsedSeconds += _timerKey.currentState?.elapsedSeconds ?? 0;
      _completeSession();
    }
  }

  void _completeSession() {
    setState(() => _sessionCompleted = true);

    // Record progress
    final progressProvider = context.read<ProgressProvider>();
    progressProvider.recordSessionProgress(
      childId: _session!.childId,
      sessionId: _session!.id,
      level: _session!.nivel,
      completedExerciseIds: _completedExerciseIds,
      elapsedSeconds: _totalElapsedSeconds,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryGreen),
              const SizedBox(height: 16),
              Text(
                'Preparando sesión...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_sessionCompleted) {
      return _buildSummaryScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Nivel ${_session?.nivel ?? "-"}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => _showExitConfirmation(),
        ),
      ),
      body: Column(
        children: [
          // Phase indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PhaseIndicator(currentPhase: _currentPhase),
          ),
          const SizedBox(height: 16),

          // Timer
          SessionTimerWidget(
            key: _timerKey,
            phase: _currentPhase,
            durationSeconds: _phaseDurationSeconds,
            onComplete: _advancePhase,
          ),
          const SizedBox(height: 16),

          // Start/Pause button
          _buildTimerControls(),
          const SizedBox(height: 12),

          // Exercises list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _currentExercises.length,
              itemBuilder: (context, index) {
                final exercise = _currentExercises[index];
                final isActive = index == _currentExerciseIndex;
                final isCompleted = _completedExerciseIds.contains(exercise.id);

                return ExerciseCard(
                  exercise: exercise,
                  currentSet: isActive ? _currentSet : 1,
                  totalSets: _currentPhaseSets,
                  reps: _currentPhaseReps,
                  isActive: isActive,
                  isCompleted: isCompleted,
                  onComplete: isActive ? _completeSet : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerControls() {
    final isRunning = _timerKey.currentState?.isRunning ?? false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            if (isRunning) {
              _timerKey.currentState?.pause();
            } else {
              _timerKey.currentState?.start();
            }
            setState(() {});
          },
          icon: Icon(
            isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 20,
          ),
          label: Text(isRunning ? 'Pausar' : 'Iniciar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isRunning
                ? Colors.white.withValues(alpha: 0.1)
                : AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: _advancePhase,
          child: Text(
            _currentPhase == FaseSesion.juego ? 'Finalizar' : 'Saltar fase →',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryScreen() {
    final minutes = _totalElapsedSeconds ~/ 60;
    final seconds = _totalElapsedSeconds % 60;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Celebration icon
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
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                '¡Sesión Completada!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nivel ${_session?.nivel ?? "-"} · Excelente trabajo',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 40),

              // Stats grid
              Row(
                children: [
                  _buildSummaryStat(
                    icon: Icons.timer_outlined,
                    value: '${minutes}m ${seconds}s',
                    label: 'Duración',
                    color: const Color(0xFF26C6DA),
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryStat(
                    icon: Icons.fitness_center_rounded,
                    value: '${_completedExerciseIds.length}',
                    label: 'Ejercicios',
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryStat(
                    icon: Icons.bolt_rounded,
                    value: '3',
                    label: 'Fases',
                    color: AppTheme.goldAccent,
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Return button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Volver al Inicio',
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

  Widget _buildSummaryStat({
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
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
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

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Salir de la sesión?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Se perderá el progreso de esta sesión.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close session
            },
            child: Text(
              'Salir',
              style: TextStyle(color: AppTheme.levelLow),
            ),
          ),
        ],
      ),
    );
  }
}
