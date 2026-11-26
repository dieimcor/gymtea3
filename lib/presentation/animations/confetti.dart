import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Explosión de confeti dibujada con [CustomPainter] (sin paquetes).
///
/// Lanza las piezas desde [origin] hacia arriba; luego caen con gravedad
/// y un leve vaivén, girando, hasta desvanecerse. Se reproduce una vez al
/// montarse y otra vez cada vez que cambia [trigger].
///
/// Con animaciones reducidas (`MediaQuery.disableAnimations`) no dibuja
/// nada: para niños con sensibilidad sensorial, cientos de piezas en
/// movimiento pueden ser demasiado.
class ConfettiBurst extends StatefulWidget {
  /// Cantidad de piezas.
  final int particleCount;

  /// Duración total de la animación.
  final Duration duration;

  /// Punto de lanzamiento, en coordenadas de [Alignment].
  final Alignment origin;

  /// Colores del confeti.
  final List<Color> colors;

  /// Cambiar este valor relanza la explosión.
  final int trigger;

  /// Semilla para que la forma de la explosión sea reproducible.
  final int seed;

  const ConfettiBurst({
    super.key,
    this.particleCount = 90,
    this.duration = const Duration(milliseconds: 3800),
    this.origin = const Alignment(0, -0.2),
    this.colors = defaultColors,
    this.trigger = 0,
    this.seed = 7,
  });

  /// Paleta alegre por defecto.
  static const List<Color> defaultColors = [
    Color(0xFFFFD54F),
    Color(0xFFFF8FB8),
    Color(0xFF7FD8E8),
    Color(0xFF7DF2B0),
    Color(0xFFC89BFF),
    Color(0xFFFFA36C),
  ];

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);

  late List<ConfettiParticle> _particles = _generate();

  List<ConfettiParticle> _generate() => ConfettiParticle.generate(
        count: widget.particleCount,
        colors: widget.colors,
        seed: widget.seed + widget.trigger,
      );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ConfettiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger ||
        oldWidget.particleCount != widget.particleCount) {
      _particles = _generate();
      _controller
        ..duration = widget.duration
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(
            animation: _controller,
            particles: _particles,
            origin: widget.origin,
          ),
        ),
      ),
    );
  }
}

/// Una pieza de confeti. Posiciones en fracciones del tamaño del lienzo.
@immutable
class ConfettiParticle {
  /// Velocidad inicial (fracción del lienzo por unidad de progreso).
  final double vx;
  final double vy;

  /// Retraso de salida (0..1 del progreso total).
  final double delay;

  final double size;
  final double spin;
  final double swayPhase;
  final Color color;

  /// `true` = círculo; `false` = tira rectangular.
  final bool round;

  const ConfettiParticle({
    required this.vx,
    required this.vy,
    required this.delay,
    required this.size,
    required this.spin,
    required this.swayPhase,
    required this.color,
    required this.round,
  });

  /// Gravedad en fracción del lienzo por unidad² de progreso.
  static const double gravity = 3.2;

  static List<ConfettiParticle> generate({
    required int count,
    required List<Color> colors,
    int seed = 7,
  }) {
    final rnd = math.Random(seed);
    return List.generate(count, (i) {
      // Abanico hacia arriba (entre -160° y -20°).
      final angle = -math.pi / 2 + (rnd.nextDouble() - 0.5) * math.pi * 0.78;
      final speed = 0.9 + rnd.nextDouble() * 0.7;
      return ConfettiParticle(
        vx: math.cos(angle) * speed * 0.7,
        vy: math.sin(angle) * speed,
        delay: rnd.nextDouble() * 0.18,
        size: 6 + rnd.nextDouble() * 7,
        spin: (rnd.nextDouble() - 0.5) * 18,
        swayPhase: rnd.nextDouble() * math.pi * 2,
        color: colors[i % colors.length],
        round: rnd.nextDouble() < 0.3,
      );
    });
  }

  /// Posición relativa al origen (fracciones del lienzo) en el progreso
  /// local [t] (0 = recién lanzada).
  Offset offsetAt(double t) {
    // El aire frena el avance horizontal; el vaivén lo hace "flotar".
    final drag = 1 - math.exp(-3 * t);
    final x = vx * drag / 2.5 + math.sin(t * 9 + swayPhase) * 0.02 * t;
    final y = vy * t + 0.5 * gravity * t * t;
    return Offset(x, y);
  }
}

class _ConfettiPainter extends CustomPainter {
  final Animation<double> animation;
  final List<ConfettiParticle> particles;
  final Alignment origin;

  _ConfettiPainter({
    required this.animation,
    required this.particles,
    required this.origin,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation.value;
    if (progress <= 0 || progress >= 1) return;

    final o = origin.alongSize(size);
    final paint = Paint();

    for (final p in particles) {
      final t = (progress - p.delay) / (1 - p.delay);
      if (t <= 0) continue;

      final rel = p.offsetAt(t);
      final pos = o + Offset(rel.dx * size.width, rel.dy * size.height);
      if (pos.dy > size.height + 20) continue;

      // Se desvanece en el último tramo.
      final fade = t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: fade);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size * 0.45, paint);
      } else {
        // El "aleteo" de la tira: se achica y agranda en un eje.
        final flutter = 0.35 + 0.65 * math.cos(t * 14 + p.swayPhase).abs();
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.5 * flutter,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.particles != particles || old.origin != origin;
}
