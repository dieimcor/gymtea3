import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gymtea3/core/constants/app_constants.dart';
import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/presentation/widgets/bouncy_tap.dart';

/// Controles de la sesión, como en la primera versión de la app:
/// **anterior · pausa · siguiente**, con un gran círculo blanco al centro.
///
/// Durante la preparación de una serie, un anillo dorado se llena alrededor
/// del botón de pausa y aparece "¡Prepárate!", para que se entienda que el
/// ejercicio está por empezar solo.
class SessionControls extends StatelessWidget {
  /// `true` si algo está corriendo (preparación o contador).
  final bool isRunning;

  /// `true` mientras corre (o está congelada) la preparación de la serie.
  final bool preparing;

  /// Avance de la preparación, de 0 a 1.
  final Animation<double>? prepAnimation;

  final VoidCallback? onPrevious;
  final VoidCallback? onTogglePause;
  final VoidCallback? onNext;

  /// Atenúa "anterior" (p.ej. en la primera serie recién empezada).
  final bool previousDimmed;

  static const previousKey = Key('session_previous');
  static const toggleKey = Key('session_toggle');
  static const nextKey = Key('session_next');

  const SessionControls({
    super.key,
    required this.isRunning,
    this.preparing = false,
    this.prepAnimation,
    this.onPrevious,
    this.onTogglePause,
    this.onNext,
    this.previousDimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "¡Prepárate!" (o "En pausa", en cualquier momento) aparece con un
        // saltito sobre los controles.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: preparing || !isRunning
              ? Padding(
                  key: ValueKey(
                      preparing && isRunning ? 'prep-label' : 'pause-label'),
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    preparing && isRunning ? '¡Prepárate!' : 'En pausa',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.goldAccent,
                    ),
                  ),
                )
              : const SizedBox(key: ValueKey('no-prep'), height: 0),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SideButton(
              key: previousKey,
              icon: Icons.skip_previous_rounded,
              tooltip: 'Anterior',
              dimmed: previousDimmed,
              onPressed: onPrevious,
            ),
            _PauseButton(
              key: toggleKey,
              isRunning: isRunning,
              preparing: preparing,
              prepAnimation: prepAnimation,
              onPressed: onTogglePause,
            ),
            _SideButton(
              key: nextKey,
              icon: Icons.skip_next_rounded,
              tooltip: 'Siguiente',
              onPressed: onNext,
            ),
          ],
        ),
      ],
    );
  }
}

class _SideButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool dimmed;
  final VoidCallback? onPressed;

  const _SideButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.dimmed = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      child: IconButton(
        icon: Icon(icon),
        iconSize: 50,
        tooltip: tooltip,
        color: dimmed ? Colors.white24 : Colors.white,
        onPressed: onPressed,
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  final bool isRunning;
  final bool preparing;
  final Animation<double>? prepAnimation;
  final VoidCallback? onPressed;

  static const double _size = 84;
  static const double _ringSize = 108;

  const _PauseButton({
    super.key,
    required this.isRunning,
    required this.preparing,
    this.prepAnimation,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final anim = prepAnimation ?? const AlwaysStoppedAnimation(0.0);
    // Con animaciones reducidas el botón no "respira" (el anillo basta).
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) == true;

    final button = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: IconButton(
        tooltip: isRunning ? 'Pausar' : 'Continuar',
        iconSize: 50,
        color: const Color(0xFF8BC34A),
        onPressed: onPressed,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, a) => RotationTransition(
            turns: Tween(begin: 0.75, end: 1.0).animate(a),
            child: ScaleTransition(scale: a, child: child),
          ),
          child: Icon(
            isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey(isRunning),
          ),
        ),
      ),
    );

    return SizedBox(
      width: _ringSize,
      height: _ringSize,
      child: AnimatedBuilder(
        animation: anim,
        builder: (context, child) {
          // Mientras se prepara, el botón "respira" una vez por segundo.
          final breathe = preparing && !reduceMotion
              ? 1.0 +
                  0.06 *
                      math
                          .sin(anim.value * math.pi * AppConstants.prepSeconds)
                          .abs()
              : 1.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                opacity: preparing ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: CustomPaint(
                  size: const Size(_ringSize, _ringSize),
                  painter: _PrepRingPainter(
                    progress: preparing ? anim.value : 0,
                  ),
                ),
              ),
              Transform.scale(scale: breathe, child: child),
            ],
          );
        },
        child: BouncyTap(child: button),
      ),
    );
  }
}

/// Anillo dorado que se llena alrededor del botón de pausa.
class _PrepRingPainter extends CustomPainter {
  final double progress;

  _PrepRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppTheme.goldAccent.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = AppTheme.goldAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PrepRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
