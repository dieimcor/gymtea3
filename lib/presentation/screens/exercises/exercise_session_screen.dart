import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gymtea3/core/constants/app_constants.dart';
import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/data/models/exercise_model.dart';
import 'package:gymtea3/data/models/exercise_rating.dart';
import 'package:gymtea3/data/models/routine_model.dart';
import 'package:gymtea3/data/models/session_step.dart';
import 'package:gymtea3/presentation/providers/auth_provider.dart';
import 'package:gymtea3/presentation/providers/exercise_provider.dart';
import 'package:gymtea3/presentation/providers/progress_provider.dart';
import 'package:gymtea3/presentation/screens/rewards/comet_reward_screen.dart';
import 'package:gymtea3/presentation/widgets/equipment_chip.dart';
import 'package:gymtea3/presentation/widgets/exercise_media_slot.dart';
import 'package:gymtea3/presentation/widgets/how_did_it_go_sheet.dart';
import 'package:gymtea3/presentation/widgets/session_controls.dart';
import 'package:gymtea3/presentation/widgets/session_timer_widget.dart';

/// Sesión activa de un cráter.
///
/// Lista plana de pasos (ver [SessionPlan]): cada serie parte con unos segundos de
/// "¡Prepárate!" y luego corre sola; los descansos arrancan directo. Tras
/// la última serie de cada ejercicio se pregunta "¿Cómo le fue?".
///
/// Antes de la primera serie se muestra una portada corta ("¡A entrenar
/// juntos!") que se salta con un toque; recién al cerrarse parte la
/// preparación.
///
/// Al terminar guarda el progreso, completa el cráter y, si con él se
/// conquistó el cometa, abre la recompensa; si no, vuelve al mapa.
class ExerciseSessionScreen extends StatefulWidget {
  const ExerciseSessionScreen({super.key});

  /// Portada inicial ("¡A entrenar juntos!").
  static const introKey = Key('session_intro');

  /// Entrada y salida de la portada (normal y con animaciones reducidas).
  /// La portada no avanza sola: espera el toque del padre, así la sesión
  /// no parte con el niño todavía lejos.
  static const introEntrance = Duration(milliseconds: 450);
  static const introEntranceReduced = Duration(milliseconds: 200);
  static const introExit = Duration(milliseconds: 350);
  static const introExitReduced = Duration(milliseconds: 150);

  @override
  State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen>
    with TickerProviderStateMixin {
  /// Nombre genérico cuando no hay niño registrado (o en tests).
  static const _genericChildName = 'tu hijo/a';

  RoutineModel? _routine;
  SessionPlan _plan = const SessionPlan([]);
  int _index = 0;
  int _elapsedSeconds = 0;

  /// Valoraciones "¿Cómo le fue?" por ejercicio (1 a 3).
  final Map<String, int> _ratings = {};

  /// La serie actual está en su preparación ([AppConstants.prepSeconds]).
  bool _preparing = false;

  /// El padre pausó (prep o contador).
  bool _paused = false;

  /// Hay una hoja abierta o se está guardando: se ignoran los controles.
  bool _busy = false;
  bool _finishing = false;

  /// El último guardado falló: "siguiente" reintenta el cierre.
  bool _saveFailed = false;

  /// El historial ya se guardó en un intento anterior.
  bool _progressSaved = false;

  /// Se recrea en cada paso para montar un timer nuevo.
  GlobalKey<SessionTimerWidgetState> _timerKey = GlobalKey();

  late final AnimationController _prepController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: AppConstants.prepSeconds),
  )..addStatusListener(_onPrepStatus);

  /// Portada "¡A entrenar juntos!" antes de la primera serie.
  bool _introVisible = false;

  /// Animaciones reducidas (accesibilidad): portada más corta y sin escala.
  bool _reduceMotion = false;

  /// Entrada de la portada; al terminar se queda quieta esperando el toque.
  late final AnimationController _introController = AnimationController(
    vsync: this,
    duration: ExerciseSessionScreen.introEntrance,
  );

  /// Salida de la portada tras el toque; al terminar parte la serie 1.
  late final AnimationController _introExitController = AnimationController(
    vsync: this,
    duration: ExerciseSessionScreen.introExit,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _endIntro();
    });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRoutine());
  }

  @override
  void dispose() {
    _prepController.dispose();
    _introController.dispose();
    _introExitController.dispose();
    super.dispose();
  }

  void _loadRoutine() {
    if (!mounted) return;
    final routine = context.read<ExerciseProvider>().previewRoutine;
    if (routine == null) {
      Navigator.pop(context);
      return;
    }
    _routine = routine;
    _plan = SessionPlan.fromRoutine(routine);
    if (_plan.isEmpty) {
      Navigator.pop(context);
      return;
    }
    _startIntro();
  }

  /// Muestra la portada. El paso 0 queda montado debajo, pero su
  /// preparación no corre hasta que la portada se cierra.
  void _startIntro() {
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) == true;
    setState(() {
      _index = 0;
      _timerKey = GlobalKey();
      _preparing = _plan[0].prepSeconds > 0;
      _introVisible = true;
    });
    _introExitController
      ..duration = _reduceMotion
          ? ExerciseSessionScreen.introExitReduced
          : ExerciseSessionScreen.introExit
      ..value = 0;
    _introController
      ..duration = _reduceMotion
          ? ExerciseSessionScreen.introEntranceReduced
          : ExerciseSessionScreen.introEntrance
      ..forward(from: 0);
  }

  /// Toque en la portada: sale con un fundido y luego parte la serie 1.
  void _leaveIntro() {
    if (!_introVisible || _introExitController.isAnimating) return;
    _introExitController.forward();
  }

  /// Cierra la portada y parte la serie 1.
  void _endIntro() {
    if (!_introVisible || !mounted) return;
    _introController.stop();
    _introExitController.stop();
    setState(() => _introVisible = false);
    _enterStep(0);
  }

  /// Primer nombre del niño, para la portada ("Tomás y tú…").
  String get _childFirstName {
    final name = _childName;
    if (name == _genericChildName) return 'Tu hijo/a';
    return name.split(RegExp(r'\s+')).first;
  }

  SessionStep? get _step => _index < _plan.length ? _plan[_index] : null;

  String get _childName {
    try {
      final name = context.read<AuthProvider>().currentChild?.nombre.trim();
      return (name == null || name.isEmpty) ? _genericChildName : name;
    } on ProviderNotFoundException {
      return _genericChildName;
    }
  }

  // ------------------------------------------------------------------
  // Movimiento entre pasos
  // ------------------------------------------------------------------

  /// Monta el paso [index]: las series pasan por la preparación, los
  /// descansos arrancan solos.
  void _enterStep(int index) {
    final step = _plan[index];
    setState(() {
      _index = index;
      _saveFailed = false;
      _timerKey = GlobalKey();
      _paused = false;
      _preparing = step.prepSeconds > 0;
    });
    if (_preparing) {
      _prepController.forward(from: 0);
    } else {
      _prepController.stop();
      _prepController.value = 0;
    }
  }

  void _onPrepStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_preparing || !mounted) return;
    setState(() => _preparing = false);
    // Termina la preparación: el ejercicio arranca solo.
    _timerKey.currentState?.start();
  }

  /// Texto del diálogo de salida. Cuenta también la serie en curso (antes
  /// decía "Llevan 00:00" en la primera) y lo escribe en palabras.
  String _exitMessage() {
    var seconds = _elapsedSeconds;
    final step = _step;
    if (!_introVisible && step != null && !step.isRest) {
      seconds += _timerKey.currentState?.elapsedSeconds ?? 0;
    }
    const lose = 'Si salen ahora, esta rutina no se guardará.';
    if (seconds <= 0) return lose;
    return 'Llevan ${spokenDuration(seconds)} de entrenamiento. $lose';
  }

  /// Suma lo entrenado en el paso que se deja y congela todo.
  void _leaveStep() {
    final timer = _timerKey.currentState;
    final step = _step;
    if (timer != null && step != null && !step.isRest) {
      _elapsedSeconds += timer.elapsedSeconds;
    }
    timer?.pause();
    _prepController.stop();
  }

  Future<void> _goNext() async {
    if (_busy || _introVisible || _step == null) return;
    if (_saveFailed) {
      // Ya se terminó la última serie y se valoró: solo falta guardar.
      await _finish();
      return;
    }
    final step = _step!;
    final asksRating = _plan.asksRatingAt(_index);
    _leaveStep();

    // "¿Cómo le fue?" va después del descanso del ejercicio (o al final de
    // la rutina), nunca con el ejercicio siguiente ya corriendo.
    if (asksRating) {
      await _askHowDidItGo(step);
      if (!mounted) return;
    }

    if (_plan.isLast(_index)) {
      await _finish();
    } else {
      _enterStep(_index + 1);
    }
  }

  void _goPrevious() {
    if (_busy || _introVisible || _step == null) return;
    _leaveStep();
    _enterStep(_plan.previousWorkIndex(_index));
  }

  void _togglePause() {
    if (_busy || _introVisible || _step == null) return;
    if (_saveFailed) {
      // La rutina ya terminó: "continuar" reintenta el guardado en vez de
      // volver a correr la última serie.
      _finish();
      return;
    }
    final timer = _timerKey.currentState;
    setState(() => _paused = !_paused);

    if (_paused) {
      if (_preparing) {
        _prepController.stop();
      } else {
        timer?.pause();
      }
    } else {
      if (_preparing) {
        _prepController.forward();
      } else {
        timer?.start();
      }
    }
  }

  Future<void> _askHowDidItGo(SessionStep step) async {
    setState(() => _busy = true);
    final exercise = step.exercise;
    final rating = await HowDidItGoSheet.show(
      context,
      childName: _childName,
      exerciseName: exercise.nombre,
      initial: ExerciseRating.fromStars(_ratings[exercise.id]),
    );
    if (!mounted) return;
    // Si se re-valora un ejercicio, se sobrescribe.
    if (rating != null) _ratings[exercise.id] = rating.stars;
    setState(() => _busy = false);
  }

  // ------------------------------------------------------------------
  // Cierre
  // ------------------------------------------------------------------

  Future<void> _finish() async {
    final routine = _routine;
    if (routine == null || _finishing) return;

    setState(() {
      _busy = true;
      _finishing = true;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final childName = _childName;
    final completedIds = _plan.completedExerciseIds(_plan.length).toList();
    final progressProvider = context.read<ProgressProvider>();
    final exerciseProvider = context.read<ExerciseProvider>();

    final LevelCompletion completion;
    try {
      // Si un intento anterior ya guardó el historial, no se duplica.
      if (!_progressSaved) {
        await progressProvider.recordSessionProgress(
          childId: routine.childId,
          sessionId: routine.id,
          level: routine.nivel,
          completedExerciseIds: completedIds,
          elapsedSeconds: _elapsedSeconds,
          calificaciones: Map.of(_ratings),
        );
        _progressSaved = true;
      }
      if (!mounted) return;

      completion = await exerciseProvider.completeLevel(
        routine.nivel,
        exercisesDone: completedIds.length,
        elapsedSeconds: _elapsedSeconds,
      );
    } catch (_) {
      if (!mounted) return;
      // No se pudo guardar: se libera la pantalla para reintentar con
      // "siguiente" o salir, en vez de quedar pegados en el overlay.
      setState(() {
        _busy = false;
        _finishing = false;
        _saveFailed = true;
        _paused = true;
      });
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'No pudimos guardar el cráter. Toca "Reintentar" para '
            'intentarlo de nuevo.',
          ),
          action: SnackBarAction(label: 'Reintentar', onPressed: _finish),
        ),
      );
      return;
    }
    if (!mounted) return;

    if (completion.cometCompleted) {
      await navigator.pushReplacementNamed(
        CometRewardScreen.routeName,
        arguments: CometRewardArgs(
          childName: childName,
          cometIndex: completion.cometIndex,
          journeyCompleted: completion.journeyCompleted,
          route: routine.ruta ?? exerciseProvider.route,
        ),
      );
    } else {
      navigator.pop();
    }
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final routine = _routine;
    final step = _step;

    if (routine == null || step == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_finishing) _showExitConfirmation();
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
            onPressed: _finishing ? null : _showExitConfirmation,
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildProgressBar(routine, step),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildStepHeader(step),
                          const SizedBox(height: 12),
                          if (step.isRest)
                            ..._buildRestLayout(step)
                          else
                            ..._buildWorkLayout(step),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    child: SessionControls(
                      isRunning: !_paused,
                      preparing: _preparing,
                      prepAnimation: _prepController,
                      previousDimmed: _index == 0,
                      onPrevious: _goPrevious,
                      onTogglePause: _togglePause,
                      onNext: _goNext,
                    ),
                  ),
                ],
              ),
              if (_introVisible) _buildIntroOverlay(routine),
              if (_finishing) _buildSavingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(RoutineModel routine, SessionStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            // La barra avanza suave en vez de saltar entre pasos.
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: _plan.progressAt(_index)),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.goldAccent),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ejercicio ${step.exerciseIndex + 1} de ${routine.ejercicios.length}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Transición infantil entre pasos: lo nuevo entra con un saltito.
  Widget _popIn(Widget child, Animation<double> anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      );

  Widget _buildStepHeader(SessionStep step) {
    final color = step.isRest ? AppTheme.accentTeal : AppTheme.primaryGreen;
    final text = step.isRest
        ? 'Descanso · ${step.seconds}s'
        : 'Serie ${step.serie} de ${step.totalSeries}';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: _popIn,
      child: Container(
        key: ValueKey(text),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  /// Descanso: mascota flotando y el anillo grande al centro.
  List<Widget> _buildRestLayout(SessionStep step) {
    return [
      const _FloatingMascot(),
      const SizedBox(height: 20),
      SessionTimerWidget(
        key: _timerKey,
        durationSeconds: step.seconds,
        isRest: true,
        label: 'Descansa y respira',
        onComplete: _goNext,
        autoStart: true,
      ),
    ];
  }

  /// Serie: lo protagonista es el ejercicio. El recurso va grande, el
  /// contador en su esquina superior derecha (aparece al terminar la
  /// preparación) y abajo la explicación en pasos simples.
  List<Widget> _buildWorkLayout(SessionStep step) {
    final exercise = step.exercise;
    final screen = MediaQuery.sizeOf(context);
    // Ancho del recurso: todo el ancho útil, sin pasar de 360 ni comerse
    // la pantalla en teléfonos bajos.
    final mediaWidth = [
      screen.width - 40,
      360.0,
      screen.height * 0.32 * 4 / 3,
    ].reduce((a, b) => a < b ? a : b);

    return [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: _popIn,
        child: Text(
          exercise.nombre,
          key: ValueKey('name-${exercise.id}'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: mediaWidth,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              transitionBuilder: _popIn,
              child: ExerciseMediaSlot(
                key: ValueKey('media-${exercise.id}'),
                exercise: exercise,
                width: mediaWidth,
                showLabel: false,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: SessionTimerWidget(
                key: _timerKey,
                durationSeconds: step.seconds,
                label: exercise.nombre,
                onComplete: _goNext,
                preparing: _preparing,
                compact: true,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _ExplanationCard(
        key: ValueKey('steps-${exercise.id}'),
        exercise: exercise,
        highlighted: _preparing,
      ),
    ];
  }

  /// Portada "¡A entrenar juntos!": entra y se queda hasta que el padre
  /// toca; entonces sale agrandándose y desvaneciéndose. Tapa por completo
  /// la sesión (no se trasluce el contador). Con animaciones reducidas solo
  /// aparece y desaparece con un fundido.
  Widget _buildIntroOverlay(RoutineModel routine) {
    return Positioned.fill(
      child: GestureDetector(
        key: ExerciseSessionScreen.introKey,
        behavior: HitTestBehavior.opaque,
        onTap: _leaveIntro,
        child: AnimatedBuilder(
          animation: Listenable.merge([_introController, _introExitController]),
          builder: (context, child) {
            final fadeIn = _introController.value;
            final leave = Curves.easeIn.transform(_introExitController.value);
            final opacity = fadeIn * (1 - leave);
            var scale = 1.0;
            if (!_reduceMotion) {
              scale = 0.8 +
                  0.2 * Curves.easeOutBack.transform(fadeIn) +
                  0.12 * leave;
            }
            // Fondo opaco: la sesión de abajo solo aparece al salir.
            return ColoredBox(
              color: AppTheme.backgroundDark.withValues(alpha: 1 - leave),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(scale: scale, child: child),
              ),
            );
          },
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/mascota/alien.png',
                    height: 130,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.rocket_launch_rounded,
                      size: 90,
                      color: AppTheme.goldAccent,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '¡A entrenar juntos!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.goldAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_childFirstName y tú contra el Cráter ${routine.nivel}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.goldAccent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: AppTheme.goldAccent.withValues(alpha: 0.6)),
                    ),
                    child: const Text(
                      'Toca cuando estén listos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavingOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: AppTheme.backgroundDark.withValues(alpha: 0.85),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.rocket_launch_rounded,
                  size: 56, color: AppTheme.goldAccent),
              SizedBox(height: 12),
              Text(
                '¡Cráter conquistado!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.goldAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    if (_finishing) return;
    // Se congela la sesión (o la portada) mientras el padre decide.
    final inIntro = _introVisible;
    if (inIntro) {
      _introController.stop();
      _introExitController.stop();
    }
    final wasPaused = _paused;
    if (!inIntro && !wasPaused && !_busy) _togglePause();

    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Salir del cráter?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          _exitMessage(),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Seguir entrenando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Salir', style: TextStyle(color: AppTheme.levelLow)),
          ),
        ],
      ),
    ).then((exit) {
      if (!mounted) return;
      if (exit == true) {
        Navigator.pop(context);
      } else if (inIntro) {
        if (_introVisible) {
          _introController.forward();
          // Si ya estaba saliendo, termina de salir.
          if (_introExitController.value > 0) _introExitController.forward();
        }
      } else if (!wasPaused && _paused) {
        _togglePause();
      }
    });
  }
}

/// Mascota que flota suavemente durante los descansos.
class _FloatingMascot extends StatefulWidget {
  const _FloatingMascot();

  @override
  State<_FloatingMascot> createState() => _FloatingMascotState();
}

class _FloatingMascotState extends State<_FloatingMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -8 * t),
          child: child,
        );
      },
      child: Container(
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
      ),
    );
  }
}

/// Explicación del ejercicio en pasos simples y numerados.
///
/// Mientras la serie se prepara queda destacada (borde dorado y un poco
/// más grande) para que el padre se la lea al niño; al arrancar el
/// ejercicio se suaviza y deja el protagonismo al recurso.
class _ExplanationCard extends StatelessWidget {
  final ExerciseModel exercise;
  final bool highlighted;

  const _ExplanationCard({
    super.key,
    required this.exercise,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final pasos = exercise.pasosSimples;
    final accent = highlighted
        ? AppTheme.goldAccent
        : Colors.white.withValues(alpha: 0.55);

    return AnimatedScale(
      scale: highlighted ? 1.0 : 0.96,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        decoration: BoxDecoration(
          color: highlighted
              ? AppTheme.goldAccent.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlighted
                ? AppTheme.goldAccent.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.08),
            width: highlighted ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_rounded, size: 18, color: accent),
                const SizedBox(width: 6),
                Text(
                  'Así se hace',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < pasos.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.goldAccent
                            .withValues(alpha: highlighted ? 0.9 : 0.25),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: highlighted
                              ? AppTheme.backgroundDark
                              : AppTheme.goldAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        pasos[i],
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: Colors.white
                              .withValues(alpha: highlighted ? 0.95 : 0.75),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (exercise.queUsar != null) _buildGear(),
          ],
        ),
      ),
    );
  }

  /// "Banco" → "banco", pero las siglas quedan igual ("TRX").
  static String _decapitalize(String s) {
    if (s.length < 2 || s[1] != s[1].toLowerCase()) return s;
    return s[0].toLowerCase() + s.substring(1);
  }

  /// "Usa: Silla firme (en vez de banco)": qué tener a mano en casa.
  Widget _buildGear() {
    final usar = exercise.queUsar!;
    final original = exercise.implemento;
    final showOriginal = exercise.reemplazo != null &&
        original != null &&
        original.trim().toLowerCase() != usar.trim().toLowerCase();

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.accentTeal.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: AppTheme.accentTeal.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              EquipmentIcons.forText(usar),
              size: 18,
              color: AppTheme.accentTeal,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Usa: $usar',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (showOriginal)
                      TextSpan(
                        text: ' (en vez de ${_decapitalize(original)})',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
                style: const TextStyle(fontSize: 14, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Duración en palabras para el padre: "45 s", "2 min", "2 min 10 s".
String spokenDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  if (m == 0) return '$s s';
  if (s == 0) return '$m min';
  return '$m min $s s';
}
