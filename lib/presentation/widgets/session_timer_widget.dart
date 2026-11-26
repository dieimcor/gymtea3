import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gymtea3/core/theme/app_theme.dart';

/// Timer circular con cuenta regresiva para un paso de la rutina
/// (una serie de 60s o un descanso).
///
/// - Descanso: anillo grande al centro de la pantalla.
/// - Serie ([compact]): insignia chica que va en la esquina superior
///   derecha del recurso del ejercicio, para que lo protagonista sea el
///   ejercicio. Durante la preparación ([preparing]) la insignia no se
///   muestra: el "¡Prepárate!" vive solo alrededor del botón central, y el
///   contador no corre hasta que la pantalla llama a
///   [SessionTimerWidgetState.start].
class SessionTimerWidget extends StatefulWidget {
  /// Segundos del paso actual.
  final int durationSeconds;

  /// `true` cuando el paso es un descanso (cambia el color y el rótulo).
  final bool isRest;

  /// Rótulo bajo el contador (nombre del ejercicio o "Descanso").
  final String label;

  /// Se dispara al llegar a cero.
  final VoidCallback? onComplete;

  /// Arranca el contador apenas se monta.
  final bool autoStart;

  /// La serie está en su preparación (la insignia se oculta).
  final bool preparing;

  /// Insignia redonda bajo el recurso del ejercicio (serie).
  final bool compact;

  /// Lo que va dentro del anillo grande del descanso (el marciano).
  final Widget? center;

  /// Lado de la insignia en modo [compact].
  static const double compactSize = 88;

  /// Lado del anillo grande del descanso.
  static const double restRingSize = 250;

  const SessionTimerWidget({
    super.key,
    required this.durationSeconds,
    required this.label,
    this.isRest = false,
    this.onComplete,
    this.autoStart = false,
    this.preparing = false,
    this.compact = false,
    this.center,
  });

  @override
  State<SessionTimerWidget> createState() => SessionTimerWidgetState();
}

class SessionTimerWidgetState extends State<SessionTimerWidget> {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;

  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;

  /// Segundos transcurridos del paso actual.
  int get elapsedSeconds => widget.durationSeconds - _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => start());
    }
  }

  @override
  void didUpdateWidget(covariant SessionTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label ||
        oldWidget.isRest != widget.isRest ||
        oldWidget.durationSeconds != widget.durationSeconds) {
      reset(autoStart: widget.autoStart);
    }
  }

  void start() {
    if (_isRunning || !mounted || _remainingSeconds <= 0) return;
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });
        widget.onComplete?.call();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void pause() {
    _timer?.cancel();
    if (mounted) setState(() => _isRunning = false);
  }

  void toggle() => _isRunning ? pause() : start();

  void reset({bool autoStart = false}) {
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _remainingSeconds = widget.durationSeconds;
      _isRunning = false;
    });
    if (autoStart) start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// `true` en los últimos 5 segundos de una serie: el número se agranda y
  /// se pone dorado para avisar que ya casi termina.
  bool get _hurry => !widget.isRest && _isRunning && _remainingSeconds <= 5;

  /// Animaciones reducidas: sin "latido" del número ni pop elástico; el
  /// aviso de los últimos segundos queda solo en el color dorado.
  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) == true;

  /// Escala del número: se agranda en el apuro salvo con animaciones
  /// reducidas.
  double _hurryScale(double big) => _hurry && !_reduceMotion ? big : 1;

  Curve get _popCurve => _reduceMotion ? Curves.easeOut : Curves.elasticOut;

  Color get _color {
    if (widget.isRest) return AppTheme.restTeal;
    if (_hurry) return AppTheme.goldAccent;
    return AppTheme.primaryGreen;
  }

  double get _progress {
    if (widget.durationSeconds == 0) return 0;
    return _remainingSeconds / widget.durationSeconds;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) return _buildBadge();

    // Descanso: anillo grande que se vacía con el marciano adentro y, bajo
    // él, el único número de la pantalla.
    const ring = SessionTimerWidget.restRingSize;
    return Column(
      children: [
        SizedBox(
          width: ring,
          height: ring,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // El anillo se vacía de forma continua, no a saltos.
              TweenAnimationBuilder<double>(
                tween: Tween(end: _progress),
                duration: const Duration(milliseconds: 900),
                builder: (context, value, _) => TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: _color),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, color, _) => CustomPaint(
                    size: const Size(ring, ring),
                    painter: _RingPainter(
                      progress: value,
                      color: color ?? _color,
                      trackColor: _color.withValues(alpha: 0.16),
                    ),
                  ),
                ),
              ),
              if (widget.center != null) widget.center!,
            ],
          ),
        ),
        const SizedBox(height: 14),
        Semantics(
          label: '$_remainingSeconds segundos',
          child: ExcludeSemantics(
            child: Text(
              '$_remainingSeconds',
              key: const ValueKey('rest-seconds'),
              style: AppTheme.numbers(size: 30),
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: child,
          ),
          child: Text(
            widget.label,
            key: ValueKey(widget.label),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  /// Insignia bajo el recurso: anillo + número. Aparece con un "pop"
  /// cuando termina la preparación y arranca la serie.
  Widget _buildBadge() {
    const size = SessionTimerWidget.compactSize;
    final shown = !widget.preparing;

    return AnimatedScale(
      scale: shown ? 1 : 0,
      duration: Duration(milliseconds: shown && !_reduceMotion ? 450 : 150),
      curve: shown ? _popCurve : Curves.easeIn,
      child: Semantics(
        label: '$_remainingSeconds segundos',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.backgroundDark,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: _progress),
                duration: const Duration(milliseconds: 900),
                builder: (context, value, _) => TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: _color),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, color, _) => CustomPaint(
                    size: const Size(size, size),
                    painter: _RingPainter(
                      progress: value,
                      color: color ?? _color,
                      trackColor: (color ?? _color).withValues(alpha: 0.18),
                      strokeWidth: 7,
                      inset: 6,
                    ),
                  ),
                ),
              ),
              AnimatedScale(
                scale: _hurryScale(1.2),
                duration: const Duration(milliseconds: 400),
                curve: _popCurve,
                child: Text(
                  '$_remainingSeconds',
                  style: AppTheme.numbers(
                    size: 30,
                    color:
                        _color == AppTheme.primaryGreen ? Colors.white : _color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final double inset;
  final Color? trackColor;

  _RingPainter({
    required this.progress,
    required this.color,
    this.trackColor,
    this.strokeWidth = 12,
    this.inset = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - inset;

    final track = Paint()
      ..color = trackColor ?? Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
