import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/data/models/exercise_model.dart';
import 'dart:math' as math;

/// Timer circular con countdown para cada fase de la sesión
class SessionTimerWidget extends StatefulWidget {
  final FaseSesion phase;
  final int durationSeconds;
  final VoidCallback? onComplete;

  const SessionTimerWidget({
    super.key,
    required this.phase,
    required this.durationSeconds,
    this.onComplete,
  });

  @override
  State<SessionTimerWidget> createState() => SessionTimerWidgetState();
}

class SessionTimerWidgetState extends State<SessionTimerWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    );
  }

  @override
  void didUpdateWidget(covariant SessionTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase ||
        oldWidget.durationSeconds != widget.durationSeconds) {
      _reset();
    }
  }

  void start() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _controller.forward(from: 1.0 - (_remainingSeconds / widget.durationSeconds));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        setState(() => _isRunning = false);
        widget.onComplete?.call();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void pause() {
    _timer?.cancel();
    _controller.stop();
    setState(() => _isRunning = false);
  }

  void _reset() {
    _timer?.cancel();
    _controller.reset();
    setState(() {
      _remainingSeconds = widget.durationSeconds;
      _isRunning = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  int get elapsedSeconds => widget.durationSeconds - _remainingSeconds;
  bool get isRunning => _isRunning;

  @override
  Widget build(BuildContext context) {
    final color = _phaseColor;
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final progress = _remainingSeconds / widget.durationSeconds;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: CustomPaint(
            painter: _TimerPainter(
              progress: progress,
              color: color,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    _phaseLabel,
                    style: TextStyle(
                      fontSize: 9,
                      color: color.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color get _phaseColor {
    switch (widget.phase) {
      case FaseSesion.activacion:
        return const Color(0xFF26C6DA);
      case FaseSesion.fortalecimiento:
        return AppTheme.primaryGreen;
      case FaseSesion.juego:
        return AppTheme.goldAccent;
    }
  }

  String get _phaseLabel {
    switch (widget.phase) {
      case FaseSesion.activacion:
        return 'ACTIVACIÓN';
      case FaseSesion.fortalecimiento:
        return 'FUERZA';
      case FaseSesion.juego:
        return 'JUEGO';
    }
  }
}

/// Custom painter for the circular timer
class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _TimerPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
