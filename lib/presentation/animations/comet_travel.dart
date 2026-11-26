import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/core/theme/comet_theme.dart';

/// Cometa completo (la esfera entera, fondo transparente). Se usa en las
/// transiciones — viaje entre cometas, vuelta de cara y despegue — para
/// que el cometa nunca se vea recortado; el tablero usa el sprite de 4
/// cráteres (`cometSpriteFor`).
const String kFullCometAsset = 'assets/images/craters/cometa_completo.png';

/// Proporción ancho / alto de [kFullCometAsset] (1280 × 1020).
const double kFullCometAspect = 1280 / 1020;

/// Sprite del cometa pintado con el aspecto de su vuelta.
///
/// El arte es uno solo: el tono se cambia con un [ColorFiltered] (si el
/// tema no es el original) y detrás va un halo radial del color del tema,
/// así cada vuelta se ve como un cometa distinto.
class ThemedCometSprite extends StatelessWidget {
  final String sprite;
  final CometTheme theme;

  /// Intensidad del halo, de 0 a 1 (fija).
  final double glowStrength;

  /// Si se pasa, el halo "respira" con esta animación (0 a 1) sin
  /// reconstruir el sprite: solo cambia la opacidad del halo.
  final Animation<double>? glowAnimation;

  const ThemedCometSprite({
    super.key,
    required this.sprite,
    required this.theme,
    // Sin halo por defecto: el tono del cometa solo cambia el asset, no
    // el fondo que lo rodea.
    this.glowStrength = 0,
    this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      sprite,
      fit: BoxFit.fill,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
    if (!theme.isOriginal) {
      image = ColorFiltered(colorFilter: theme.colorFilter, child: image);
    }

    final strength = glowStrength.clamp(0.0, 1.0);

    // El halo se dibuja a intensidad completa y se atenúa con opacidad:
    // así animarlo no obliga a repintar el sprite filtrado.
    Widget halo = Transform.scale(
      scale: 1.25,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 0.55,
            colors: [
              theme.glow.withValues(alpha: 0.42),
              theme.glow.withValues(alpha: 0.14),
              theme.glow.withValues(alpha: 0),
            ],
            stops: const [0, 0.55, 1],
          ),
        ),
      ),
    );
    final animation = glowAnimation;
    halo = animation != null
        ? FadeTransition(opacity: animation, child: halo)
        : Opacity(opacity: strength, child: halo);

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        // El halo es más grande que el sprite para que "respire" afuera.
        Positioned.fill(child: IgnorePointer(child: halo)),
        // El sprite (con su filtro de color) queda en su propia capa.
        RepaintBoundary(child: image),
      ],
    );
  }
}

/// Viaje de un cometa al siguiente (~3 s).
///
/// Se dibuja encima del mapa y bloquea los toques mientras dura:
/// 1. el cometa conquistado se aleja y se achica,
/// 2. las estrellas se estiran como si fuéramos a toda velocidad,
/// 3. el marciano cruza volando,
/// 4. el nuevo cometa llega acercándose con su color.
///
/// Al terminar llama a [onFinished] y quien lo muestra lo saca.
///
/// Con "reducir movimiento" activo (`MediaQuery.disableAnimations`) el
/// viaje es un fundido corto ([reducedDuration]) entre los dos cometas.
class CometTravel extends StatefulWidget {
  final CometTheme from;
  final CometTheme to;

  /// Sprite del cometa que se deja. Por defecto el cometa completo, así
  /// nunca se ve cortado mientras viaja.
  final String fromSprite;

  /// Sprite del cometa que llega (por defecto, también el completo).
  final String toSprite;

  /// Proporción ancho / alto de los sprites.
  final double aspect;

  final Duration duration;

  /// Duración del fundido cuando se pide reducir el movimiento.
  static const Duration reducedDuration = Duration(milliseconds: 700);

  final VoidCallback? onFinished;

  const CometTravel({
    super.key,
    required this.from,
    required this.to,
    this.fromSprite = kFullCometAsset,
    this.toSprite = kFullCometAsset,
    this.aspect = kFullCometAspect,
    this.duration = const Duration(milliseconds: 3200),
    this.onFinished,
  });

  /// Texto grande del viaje.
  static String messageFor(CometTheme to) => '¡Rumbo al ${to.name}!';

  @override
  State<CometTravel> createState() => _CometTravelState();
}

class _CometTravelState extends State<CometTravel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Estrellas del efecto velocidad: fijas para que no "salten" por frame.
  late final List<SpeedStar> _stars;

  /// `true` si el sistema pide reducir el movimiento.
  bool _reduced = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final random = math.Random(7);
    _stars = List.generate(90, (_) => SpeedStar.random(random));

    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onFinished?.call();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery no se puede leer en initState: se arranca aquí, una vez.
    if (_started) return;
    _started = true;
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduced) _controller.duration = CometTravel.reducedDuration;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Avance local de [t] dentro de la ventana [begin, end], con curva.
  static double _phase(double t, double begin, double end,
      [Curve curve = Curves.linear]) {
    if (t <= begin) return 0;
    if (t >= end) return 1;
    return curve.transform((t - begin) / (end - begin));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: CometTravel.messageFor(widget.to),
      liveRegion: true,
      child: AbsorbPointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => _reduced
                  ? _buildReducedFrame(size, _controller.value)
                  : _buildFrame(size, _controller.value),
            );
          },
        ),
      ),
    );
  }

  /// Versión tranquila: fondo quieto, el cometa nuevo aparece en su
  /// lugar con el mensaje y todo se desvanece. Sin estrellas ni giros.
  Widget _buildReducedFrame(Size size, double t) {
    final backdrop = _phase(t, 0, 0.2) * (1 - _phase(t, 0.8, 1));
    final cometWidth = math.min(size.width * 0.78, 360.0);
    final cometHeight = cometWidth / widget.aspect;

    return Opacity(
      opacity: backdrop.clamp(0.0, 1.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppTheme.backgroundDark),
          Center(
            child: SizedBox(
              width: cometWidth,
              height: cometHeight,
              child: ThemedCometSprite(
                sprite: widget.toSprite,
                theme: widget.to,
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: size.height * 0.16,
            child: Text(
              CometTravel.messageFor(widget.to),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrame(Size size, double t) {
    // Fondo: entra rápido, se va al final dejando ver el mapa nuevo.
    final backdrop = _phase(t, 0, 0.08) * (1 - _phase(t, 0.88, 1));

    // Velocidad de las estrellas: sube, se mantiene y frena.
    final speed = math.sin(math.pi * _phase(t, 0.05, 0.9)).clamp(0.0, 1.0);

    final cometWidth = math.min(size.width * 0.78, 360.0);
    final cometHeight = cometWidth / widget.aspect;
    final center = Offset(size.width / 2, size.height * 0.52);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        Opacity(
          opacity: backdrop,
          child: CustomPaint(
            painter: SpeedStarsPainter(
              stars: _stars,
              progress: t,
              speed: speed,
              // Estrellas siempre blancas: el fondo no toma el color del cometa.
              tint: Colors.white,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        _buildLeavingComet(t, center, cometWidth, cometHeight, size),
        _buildArrivingComet(t, center, cometWidth, cometHeight, size),
        _buildAlien(t, size),
        _buildMessage(t, size),
      ],
    );
  }

  /// El cometa conquistado se va hacia arriba a la izquierda, girando.
  Widget _buildLeavingComet(
      double t, Offset center, double w, double h, Size size) {
    final p = _phase(t, 0.04, 0.42, Curves.easeInCubic);
    if (p >= 1) return const SizedBox.shrink();

    final scale = 1 - 0.92 * p;
    final dx = -size.width * 0.32 * p;
    final dy = -size.height * 0.34 * p;
    final opacity = (1 - _phase(t, 0.3, 0.42)) * _phase(t, 0, 0.06);

    return Positioned(
      left: center.dx - w / 2 + dx,
      top: center.dy - h / 2 + dy,
      width: w,
      height: h,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: -0.7 * p,
          child: Transform.scale(
            scale: scale,
            child: ThemedCometSprite(
              sprite: widget.fromSprite,
              theme: widget.from,
            ),
          ),
        ),
      ),
    );
  }

  /// El cometa nuevo llega desde lejos (abajo a la derecha) y se acerca.
  Widget _buildArrivingComet(
      double t, Offset center, double w, double h, Size size) {
    final p = _phase(t, 0.55, 0.9, Curves.easeOutBack);
    if (p <= 0) return const SizedBox.shrink();

    final scale = 0.06 + 0.94 * p;
    final rest = 1 - p;
    final dx = size.width * 0.3 * rest;
    final dy = size.height * 0.28 * rest;
    final opacity = _phase(t, 0.55, 0.65) * (1 - _phase(t, 0.9, 1));

    return Positioned(
      left: center.dx - w / 2 + dx,
      top: center.dy - h / 2 + dy,
      width: w,
      height: h,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: 0.5 * rest,
          child: Transform.scale(
            scale: scale,
            child: ThemedCometSprite(
              sprite: widget.toSprite,
              theme: widget.to,
              glowStrength: 0,
            ),
          ),
        ),
      ),
    );
  }

  /// El marciano cruza la pantalla de izquierda a derecha, ondulando.
  Widget _buildAlien(double t, Size size) {
    final p = _phase(t, 0.2, 0.78, Curves.easeInOutSine);
    if (p <= 0 || p >= 1) return const SizedBox.shrink();

    const alienSize = 96.0;
    final x = -alienSize + (size.width + alienSize * 2) * p;
    final y = size.height * 0.62 + math.sin(p * math.pi * 3) * 26;

    return Positioned(
      left: x - alienSize / 2,
      top: y - alienSize / 2,
      width: alienSize,
      height: alienSize,
      child: Transform.rotate(
        angle: 0.18 + math.sin(p * math.pi * 3) * 0.12,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.to.glow.withValues(alpha: 0.35),
                blurRadius: 30,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/mascota/alien.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.rocket_launch_rounded,
              color: AppTheme.goldAccent,
              size: 56,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(double t, Size size) {
    final inP = _phase(t, 0.1, 0.32, Curves.elasticOut);
    final outP = _phase(t, 0.82, 0.92);
    final opacity = (_phase(t, 0.1, 0.16) * (1 - outP)).clamp(0.0, 1.0);
    if (opacity <= 0) return const SizedBox.shrink();

    return Positioned(
      left: 24,
      right: 24,
      top: size.height * 0.16,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: 0.4 + 0.6 * inP,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                CometTravel.messageFor(widget.to),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: widget.to.glow, blurRadius: 18),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nuevos cráteres los esperan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una estrella del efecto velocidad, en coordenadas polares desde el
/// centro de la pantalla. La usan el viaje y el despegue (`LaunchScreen`).
class SpeedStar {
  final double angle;

  /// Distancia inicial, como fracción del radio de la pantalla.
  final double offset;

  /// Qué tan rápido corre (las cercanas corren más).
  final double pace;
  final double width;

  const SpeedStar(this.angle, this.offset, this.pace, this.width);

  factory SpeedStar.random(math.Random r) => SpeedStar(
        r.nextDouble() * math.pi * 2,
        r.nextDouble(),
        0.6 + r.nextDouble() * 0.9,
        0.8 + r.nextDouble() * 1.6,
      );
}

/// Estrellas que salen del centro y se estiran según [speed].
class SpeedStarsPainter extends CustomPainter {
  final List<SpeedStar> stars;
  final double progress;
  final double speed;
  final Color tint;

  /// Centro del que salen las estrellas, como fracción del alto.
  final double centerY;

  SpeedStarsPainter({
    required this.stars,
    required this.progress,
    required this.speed,
    required this.tint,
    this.centerY = 0.52,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppTheme.backgroundDark.withValues(alpha: 0.94),
    );

    final center = Offset(size.width / 2, size.height * centerY);
    final maxR = size.longestSide * 0.75;
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (final star in stars) {
      // Cada estrella avanza hacia afuera y vuelve a nacer en el centro.
      final travel = (star.offset + progress * 2.2 * star.pace) % 1.0;
      final dist = 12 + travel * travel * maxR;
      final length = 2 + speed * (28 + travel * 160) * star.pace;

      final dir = Offset(math.cos(star.angle), math.sin(star.angle));
      final head = center + dir * dist;
      final tail = center + dir * math.max(0, dist - length);

      paint
        ..strokeWidth = star.width * (0.6 + travel)
        ..color = Color.lerp(Colors.white, tint, 0.35 * travel)!
            .withValues(alpha: (0.35 + 0.65 * travel).clamp(0.0, 1.0));
      canvas.drawLine(tail, head, paint);
    }
  }

  @override
  bool shouldRepaint(SpeedStarsPainter old) =>
      old.progress != progress ||
      old.speed != speed ||
      old.tint != tint ||
      old.centerY != centerY;
}
