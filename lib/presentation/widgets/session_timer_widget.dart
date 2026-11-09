import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gymtea3/core/theme/app_theme.dart';

/// Timer circular con cuenta regresiva para un bloque de la rutina
/// (una serie de 60s o un descanso).
class SessionTimerWidget extends StatefulWidget {
  /// Segundos del bloque actual.
  final int durationSeconds;

  /// `true` cuando el bloque es un descanso (cambia el color y el rótulo).
  final bool isRest;

  /// Rótulo bajo el contador (nombre del ejercicio o "Descanso").
  final String label;

  /// Se dispara al llegar a cero.
  final VoidCallback? onComplete;

  /// Arranca el contador apenas se monta o cambia de bloque.
  final bool autoStart;

  const SessionTimerWidget({
    super.key,
    required this.durationSeconds,
    required this.label,
    this.isRest = false,
    this.onComplete,
    this.autoStart = false,
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

  /// Segundos transcurridos del bloque actual.
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
    if (_isRunning || !mounted) return;
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

  Color get _color =>
      widget.isRest ? AppTheme.accentTeal : AppTheme.primaryGreen;

  double get _progress {
    if (widget.durationSeconds == 0) return 0;
    return _remainingSeconds / widget.durationSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 190,
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(190, 190),
                painter: _RingPainter(progress: _progress, color: _color),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_remainingSeconds',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                  Text(
                    'segundos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
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
