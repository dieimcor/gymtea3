import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/core/theme/comet_theme.dart';
import 'package:gymtea3/data/models/training_route.dart';
import 'package:gymtea3/presentation/animations/comet_travel.dart';
import 'package:gymtea3/presentation/providers/exercise_provider.dart';

/// Despegue: la introducción que se ve después de elegir la ruta.
///
/// 1. cuenta regresiva grande 3 · 2 · 1 (cada número aparece con un pop),
/// 2. el marciano despega con su llama mientras las estrellas se estiran,
/// 3. el primer planeta de la ruta se acerca con "¡Rumbo al …!",
/// 4. se pasa al mapa (`/home`).
///
/// Dura ~3,8 s y se puede saltar tocando la pantalla. Con "reducir
/// movimiento" activo es solo un fundido corto con el planeta y el texto.
class LaunchScreen extends StatefulWidget {
  static const String routeName = '/launch';

  /// Duración completa del despegue.
  static const Duration duration = Duration(milliseconds: 3800);

  /// Duración con "reducir movimiento".
  static const Duration reducedDuration = Duration(milliseconds: 600);

  /// Ruta a la que se va al terminar.
  final String nextRoute;

  const LaunchScreen({super.key, this.nextRoute = '/home'});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: LaunchScreen.duration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _finish();
        });

  /// Estrellas fijas para que no "salten" entre frames.
  late final List<SpeedStar> _stars = () {
    final random = math.Random(11);
    return List.generate(110, (_) => SpeedStar.random(random));
  }();

  bool _reduced = false;
  bool _started = false;
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduced) _controller.duration = LaunchScreen.reducedDuration;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Va al mapa (una sola vez: al terminar o al tocar para saltar).
  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    _controller.stop();
    Navigator.pushReplacementNamed(context, widget.nextRoute);
  }

  /// Avance local de [t] dentro de la ventana [begin, end], con curva.
  static double _phase(double t, double begin, double end,
      [Curve curve = Curves.linear]) {
    if (t <= begin) return 0;
    if (t >= end) return 1;
    return curve.transform((t - begin) / (end - begin));
  }

  /// Segundos del despegue completo pasados a fracción del controlador.
  static double _s(double seconds) =>
      seconds * 1000 / LaunchScreen.duration.inMilliseconds;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExerciseProvider>();
    final route = provider.route;
    final comet = provider.cometTheme(provider.cometIndex);
    // El despegue muestra el cometa completo; el tablero, el de 4 cráteres.
    const sprite = kFullCometAsset;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: Semantics(
          liveRegion: true,
          label: '${CometTravel.messageFor(comet)} Toca para continuar.',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => _reduced
                    ? _buildReduced(
                        size, _controller.value, route, comet, sprite)
                    : _buildFrame(
                        size, _controller.value, route, comet, sprite),
              );
            },
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Despegue completo
  // ------------------------------------------------------------------

  Widget _buildFrame(Size size, double t, TrainingRoute route, CometTheme comet,
      String sprite) {
    // Las estrellas arrancan lentas y aceleran al despegar.
    final speed = 0.12 + 0.88 * _phase(t, _s(1.6), _s(2.6), Curves.easeIn);
    // Al final todo se desvanece hacia el mapa.
    final outro = 1 - _phase(t, _s(3.5), 1);

    return Opacity(
      opacity: outro.clamp(0.0, 1.0),
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: SpeedStarsPainter(
                stars: _stars,
                progress: t,
                speed: speed,
                tint: Colors.white,
                centerY: 0.42,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          _buildPlanet(size, t, comet, sprite),
          _buildRocketAlien(size, t, route),
          _buildCountdown(size, t, route),
          _buildMessage(size, t, route, comet),
          _buildSkipHint(t),
        ],
      ),
    );
  }

  /// 3 · 2 · 1, cada número ~0,7 s, con pop elástico.
  Widget _buildCountdown(Size size, double t, TrainingRoute route) {
    const step = 0.7;
    for (var i = 0; i < 3; i++) {
      final begin = _s(step * i);
      final end = _s(step * (i + 1));
      if (t < begin || t >= end) continue;

      final p = _phase(t, begin, end);
      final pop = Curves.elasticOut.transform((p * 1.6).clamp(0.0, 1.0));
      final fade = 1 - _phase(p, 0.7, 1);

      return Positioned(
        left: 0,
        right: 0,
        top: size.height * 0.16,
        child: Opacity(
          opacity: fade.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.3 + 0.7 * pop,
            child: Text(
              '${3 - i}',
              key: ValueKey('countdown-${3 - i}'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 120,
                height: 1,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(color: route.color, blurRadius: 30),
                  Shadow(
                    color: AppTheme.goldAccent.withValues(alpha: 0.6),
                    blurRadius: 60,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  /// El marciano espera temblando de emoción y despega con su llama.
  Widget _buildRocketAlien(Size size, double t, TrainingRoute route) {
    final rise = _phase(t, _s(1.9), _s(2.9), Curves.easeInCubic);
    if (rise >= 1) return const SizedBox.shrink();

    const alienSize = 120.0;
    final baseTop = size.height * 0.58;
    final top = baseTop - rise * (baseTop + alienSize * 2.2);

    // Tiembla un poco durante la cuenta (motor encendido).
    final rumble = t < _s(1.9) ? math.sin(t * 160) * 1.6 : 0.0;

    // La llama crece al despegar y titila.
    final ignition = _phase(t, _s(1.2), _s(2.1), Curves.easeOut);
    final flicker = 0.85 + 0.15 * math.sin(t * 90);
    final flameHeight = (20 + 90 * ignition) * flicker;

    // El fuego envuelve al marciano: un halo de llamas detrás que lo rodea
    // y se estira en la cola, y lenguas delante de sus costados. Así no se
    // ve como un efecto pegado bajo el sprite.
    final fire = FireAura(
      ignition: ignition,
      tail: flameHeight,
      time: t * 3.8,
    );

    return Positioned(
      left: (size.width - alienSize) / 2 + rumble,
      top: top,
      width: alienSize,
      height: alienSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: fire.behind()),
          ),
          Image.asset(
            'assets/images/mascota/alien.png',
            width: alienSize,
            height: alienSize,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.rocket_launch_rounded,
              color: AppTheme.goldAccent,
              size: 80,
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: fire.front()),
          ),
        ],
      ),
    );
  }

  /// El primer planeta de la ruta llega desde el fondo.
  Widget _buildPlanet(Size size, double t, CometTheme comet, String sprite) {
    final p = _phase(t, _s(2.4), _s(3.3), Curves.easeOutBack);
    if (p <= 0) return const SizedBox.shrink();

    final w = math.min(size.width * 0.72, 340.0);
    final h = w / kFullCometAspect;
    final opacity = _phase(t, _s(2.4), _s(2.7));

    return Positioned(
      left: (size.width - w) / 2,
      top: size.height * 0.46 - h / 2,
      width: w,
      height: h,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: 0.4 * (1 - p),
          child: Transform.scale(
            scale: 0.05 + 0.95 * p,
            child: ThemedCometSprite(sprite: sprite, theme: comet),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(
      Size size, double t, TrainingRoute route, CometTheme comet) {
    final inP = _phase(t, _s(2.6), _s(3.2), Curves.elasticOut);
    final opacity = _phase(t, _s(2.6), _s(2.8));
    if (opacity <= 0) return const SizedBox.shrink();

    return Positioned(
      left: 24,
      right: 24,
      top: size.height * 0.1,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: 0.5 + 0.5 * inP,
          child: _MessageBlock(route: route, comet: comet),
        ),
      ),
    );
  }

  Widget _buildSkipHint(double t) {
    final opacity = _phase(t, _s(0.6), _s(1.2)) * 0.55;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 28,
      child: SafeArea(
        top: false,
        child: Opacity(
          opacity: opacity,
          child: const Text(
            'Toca para continuar',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Movimiento reducido
  // ------------------------------------------------------------------

  Widget _buildReduced(Size size, double t, TrainingRoute route,
      CometTheme comet, String sprite) {
    final w = math.min(size.width * 0.66, 320.0);
    final h = w / kFullCometAspect;
    final opacity = Curves.easeOut.transform(t);

    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _MessageBlock(route: route, comet: comet),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: w,
            height: h,
            child: ThemedCometSprite(sprite: sprite, theme: comet),
          ),
        ],
      ),
    );
  }
}

/// "¡Rumbo al …!" con el chip de la ruta.
class _MessageBlock extends StatelessWidget {
  final TrainingRoute route;
  final CometTheme comet;

  const _MessageBlock({required this.route, required this.comet});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          CometTravel.messageFor(comet),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [Shadow(color: comet.glow, blurRadius: 20)],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: route.color.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: route.color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(route.icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                'Ruta ${route.label}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Fuego que envuelve al marciano al despegar. Se pinta en dos capas
/// alrededor de su caja (el sprite va entre ambas):
/// - [behind]: resplandor, una envoltura de llamas que lo rodea por
///   completo y se estira hacia abajo en la cola, y lenguas que titilan;
/// - [front]: un borde caliente en su mitad de abajo y lenguas que suben
///   por sus costados, por delante del sprite.
///
/// [ignition] va de 0 (motor apenas encendido) a 1 (despegue), [tail] es
/// el largo de la cola en px y [time] avanza en segundos para el titileo.
class FireAura {
  final double ignition;
  final double tail;
  final double time;

  const FireAura({
    required this.ignition,
    required this.tail,
    required this.time,
  });

  CustomPainter behind() => _FireBehindPainter(this);
  CustomPainter front() => _FireFrontPainter(this);

  static const _white = Color(0xFFFFFDE7);
  static const _yellow = Color(0xFFFFF59D);
  static const _amber = Color(0xFFFFB74D);
  static const _orange = Color(0xFFFF7043);

  /// Envoltura en forma de gota: un círculo ondulado alrededor del
  /// marciano que hacia abajo se angosta y se estira en la cola.
  Path envelope(Size size, {double scale = 1, double phase = 0}) {
    final c = Offset(size.width / 2, size.height * 0.52);
    final r = size.width * 0.5 * (0.88 + 0.16 * ignition) * scale;
    final length = (tail + size.height * 0.25) * scale;
    final path = Path();
    const n = 72;
    for (var i = 0; i <= n; i++) {
      final a = -math.pi / 2 + i / n * math.pi * 2;
      final down = math.max(0.0, math.sin(a));
      // Bordes que lamen: ondas que suben con el tiempo.
      final wobble = 1 +
          (0.05 + 0.04 * ignition) *
              math.sin(a * 7 + time * 14 + phase) *
              (0.4 + 0.6 * down);
      final x =
          c.dx + math.cos(a) * r * wobble * (1 - 0.55 * math.pow(down, 2.5));
      final y = c.dy + math.sin(a) * r * wobble + length * math.pow(down, 4);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  /// Lengua de fuego: nace en [base] y apunta en [angle] (0 = abajo).
  static Path lick(Offset base, double angle, double length, double width) {
    final dir = Offset(math.sin(angle), math.cos(angle));
    final perp = Offset(dir.dy, -dir.dx);
    final tip = base + dir * length;
    final l = base + perp * (width / 2);
    final r = base - perp * (width / 2);
    final lc = l + dir * (length * 0.55);
    final rc = r + dir * (length * 0.55);
    return Path()
      ..moveTo(l.dx, l.dy)
      ..quadraticBezierTo(lc.dx, lc.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(rc.dx, rc.dy, r.dx, r.dy)
      ..arcToPoint(l, radius: Radius.circular(width / 2))
      ..close();
  }
}

class _FireBehindPainter extends CustomPainter {
  final FireAura fire;
  _FireBehindPainter(this.fire);

  @override
  void paint(Canvas canvas, Size size) {
    final ign = fire.ignition;
    final c = Offset(size.width / 2, size.height * 0.52);
    final flicker = 0.9 + 0.1 * math.sin(fire.time * 40);

    // Motor apenas encendido: solo una llamita bajo los pies.
    final pilot = Paint()
      ..color = FireAura._amber.withValues(alpha: 0.8 * flicker)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(
      FireAura.lick(
        Offset(c.dx, size.height * 0.9),
        0,
        fire.tail * flicker * (1 - ign),
        16,
      ),
      pilot,
    );
    if (ign <= 0.02) return;

    // El envoltorio crece con el encendido (sin manchas antes).
    final heat = math.pow(ign.clamp(0.0, 1.0), 2.5).toDouble();

    // Resplandor amplio.
    canvas.drawCircle(
      c,
      size.width * (0.62 + 0.25 * ign),
      Paint()
        ..color = FireAura._amber.withValues(alpha: 0.35 * heat * flicker)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    final outer = fire.envelope(size);
    final vertical = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        FireAura._yellow.withValues(alpha: 0.45 * heat),
        FireAura._amber.withValues(alpha: 0.75 * heat),
        FireAura._orange.withValues(alpha: 0.85 * heat),
        FireAura._orange.withValues(alpha: 0),
      ],
      stops: const [0, 0.4, 0.75, 1],
    ).createShader(outer.getBounds());

    // Capa externa difusa, capa media y núcleo blanco-amarillo.
    canvas.drawPath(
      outer,
      Paint()
        ..shader = vertical
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      fire.envelope(size, scale: 0.86, phase: 2.1),
      Paint()
        ..shader = vertical
        ..blendMode = BlendMode.plus,
    );
    canvas.drawPath(
      fire.envelope(size, scale: 0.7, phase: 4.2),
      Paint()
        ..color = FireAura._white.withValues(alpha: 0.55 * heat)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Lenguas que se desprenden de la cola y los costados.
    if (ign <= 0) return;
    for (var i = 0; i < 6; i++) {
      final side = i.isEven ? 1.0 : -1.0;
      final k = (i ~/ 2) / 2; // 0, 0.5, 1
      final a = math.pi * (0.15 + 0.3 * k) * side;
      final base = c +
          Offset(math.sin(a), math.cos(a)) * (size.width * 0.42) +
          Offset(0, size.height * 0.1 * k);
      final len = (18 + fire.tail * 0.45) *
          ign *
          (0.7 + 0.3 * math.sin(fire.time * (11 + i * 3) + i));
      canvas.drawPath(
        FireAura.lick(base, -a * 0.5, len, 12 + 4 * k),
        Paint()
          ..color = (i < 2 ? FireAura._yellow : FireAura._amber)
              .withValues(alpha: 0.7 * ign)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(_FireBehindPainter old) =>
      old.fire.ignition != fire.ignition ||
      old.fire.tail != fire.tail ||
      old.fire.time != fire.time;
}

class _FireFrontPainter extends CustomPainter {
  final FireAura fire;
  _FireFrontPainter(this.fire);

  @override
  void paint(Canvas canvas, Size size) {
    final ign = fire.ignition;
    if (ign <= 0) return;
    final c = Offset(size.width / 2, size.height * 0.52);
    final r = size.width * 0.44;

    // Borde caliente en la mitad de abajo: el fuego lo abraza.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      math.pi * 0.05,
      math.pi * 0.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = FireAura._amber.withValues(alpha: 0.55 * ign)
        ..blendMode = BlendMode.plus
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Lenguas que suben por los costados, por delante del sprite.
    for (var i = 0; i < 4; i++) {
      final side = i.isEven ? 1.0 : -1.0;
      final low = i < 2;
      final a = math.pi * (low ? 0.3 : 0.45) * side;
      final base = c + Offset(math.sin(a), math.cos(a)) * r;
      final len = size.width *
          (low ? 0.28 : 0.2) *
          ign *
          (0.65 + 0.35 * math.sin(fire.time * (13 + i * 4) + i * 1.7));
      // Apuntan hacia arriba y afuera: suben pegadas al cuerpo.
      final angle = math.pi - side * (low ? 0.5 : 0.25);
      canvas.drawPath(
        FireAura.lick(base, angle, len, 9),
        Paint()
          ..color = FireAura._yellow.withValues(alpha: 0.5 * ign)
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
    }
  }

  @override
  bool shouldRepaint(_FireFrontPainter old) =>
      old.fire.ignition != fire.ignition || old.fire.time != fire.time;
}
