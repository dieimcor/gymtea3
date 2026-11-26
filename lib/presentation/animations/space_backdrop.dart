import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fondo vivo del mapa: "viaje en movimiento". Tres capas de estrellas a
/// distinta velocidad, un planeta lejano que cruza y asteroides que pasan
/// girando, para que se sienta que el cometa viaja.
///
/// Los colores son **fijos**: el tono de cada cometa solo cambia sus
/// assets (el sprite), nunca el fondo. Lo que cambia con la dificultad es
/// la [intensity] (0 = Explorador, calmo · 1 = Astronauta · 2 = Comandante,
/// más rápido y con más asteroides). Con "reducir movimiento" queda quieto.
class SpaceBackdrop extends StatefulWidget {
  /// 0, 1 o 2 según la ruta (`TrainingRoute.nivel - 1`).
  final int intensity;

  const SpaceBackdrop({super.key, this.intensity = 0});

  @override
  State<SpaceBackdrop> createState() => _SpaceBackdropState();
}

class _SpaceBackdropState extends State<SpaceBackdrop>
    with SingleTickerProviderStateMixin {
  // Un ciclo largo; todo lo que se mueve es periódico dentro de él.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );
  final List<Offset> _stars = _seededStars(150);

  static List<Offset> _seededStars(int n) {
    final r = math.Random(42);
    return List.generate(n, (_) => Offset(r.nextDouble(), r.nextDouble()));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: ParallaxPainter(
            intensity: widget.intensity.clamp(0, 2),
            stars: _stars,
            repaint: _controller,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class ParallaxPainter extends CustomPainter {
  final int intensity;
  final List<Offset> stars;
  final Animation<double> repaint;

  ParallaxPainter({
    required this.intensity,
    required this.stars,
    required this.repaint,
  }) : super(repaint: repaint);

  /// Multiplicador de velocidad por dificultad.
  double get speed => const [1.0, 1.5, 2.2][intensity];

  /// Asteroides que pasan por ciclo.
  int get rocks => const [1, 2, 4][intensity];

  static const Color _planetLight = Color(0xFFFFCC80);
  static const Color _planetDark = Color(0xFF6A3A1E);

  @override
  void paint(Canvas canvas, Size s) {
    final t = repaint.value; // 0..1 en 60 s

    // Planeta lejano que cruza el cielo (colores fijos, no del cometa).
    final pc = Offset(s.width * (1.25 - 1.5 * t), s.height * 0.3);
    // Su atmósfera ilumina el espacio alrededor.
    canvas.drawCircle(
      pc,
      110,
      Paint()
        ..shader = RadialGradient(colors: [
          _planetLight.withValues(alpha: 0.22),
          _planetLight.withValues(alpha: 0.06),
          _planetLight.withValues(alpha: 0),
        ], stops: const [
          0.3,
          0.6,
          1
        ]).createShader(Rect.fromCircle(center: pc, radius: 110)),
    );
    canvas.drawCircle(
      pc,
      40,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [_planetLight, _planetDark],
        ).createShader(Rect.fromCircle(center: pc, radius: 40)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: pc, width: 120, height: 24),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white.withValues(alpha: 0.3),
    );

    // Tres capas de estrellas: lejos lento, cerca rápido.
    const layers = [
      (v: 6.0, r: 0.8, a: 0.45),
      (v: 12.0, r: 1.2, a: 0.7),
      (v: 24.0, r: 1.9, a: 0.95),
    ];
    final p = Paint();
    // Resplandor alrededor de cada fuente de luz (estrellas cercanas y
    // brillantes): ilumina el espacio que las rodea.
    final halo = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final bigHalo = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    final ray = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;
    for (var l = 0; l < layers.length; l++) {
      final layer = layers[l];
      for (var i = l; i < stars.length; i += 3) {
        final x = ((stars[i].dx - t * layer.v * speed) % 1.0 + 1.0) % 1.0;
        final c = Offset(x * s.width, stars[i].dy * s.height);
        final bright = l == 2 && i % 7 == 2;
        if (l == 2) {
          // Titila: el brillo late con su propio ritmo.
          final tw = 0.6 + 0.4 * math.sin(t * math.pi * 2 * 20 + i);
          halo.color = const Color(0xFFCFE3FF).withValues(alpha: 0.35 * tw);
          canvas.drawCircle(c, bright ? 7 : 4.5, halo);
          if (bright) {
            bigHalo.color =
                const Color(0xFFBFD8FF).withValues(alpha: 0.28 * tw);
            canvas.drawCircle(c, 22, bigHalo);
            // Destello en cruz.
            final len = 8 + 6 * tw;
            ray.color = Colors.white.withValues(alpha: 0.55 * tw);
            canvas.drawLine(c - Offset(len, 0), c + Offset(len, 0), ray);
            canvas.drawLine(c - Offset(0, len), c + Offset(0, len), ray);
          }
        }
        p.color = Colors.white.withValues(alpha: layer.a);
        canvas.drawCircle(c, bright ? layer.r * 1.5 : layer.r, p);
      }
    }

    // Asteroides que cruzan girando, en diagonal.
    final rock = Paint()..color = const Color(0xFF8D7B68);
    final shade = Paint()..color = Colors.black.withValues(alpha: 0.3);
    for (var k = 0; k < rocks; k++) {
      final phase = ((t * 5 * speed) + k / rocks) % 1.0;
      if (phase > 0.5) continue; // cruza en la primera mitad de su vuelta
      final q = phase / 0.5;
      final y0 = s.height * (0.2 + 0.18 * k);
      final c = Offset(s.width * (1.1 - 1.3 * q), y0 + s.height * 0.12 * q);
      final size = 9.0 + 4 * (k % 2);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-q * math.pi * 3);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: size * 1.4, height: size),
          rock);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(size * 0.2, size * 0.15),
              width: size * 0.6,
              height: size * 0.4),
          shade);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ParallaxPainter old) => old.intensity != intensity;
}
