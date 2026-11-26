import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gymtea3/core/theme/comet_theme.dart';
import 'package:gymtea3/presentation/animations/comet_travel.dart';

/// "Vuelta" del cometa al terminar su primera cara de 4 cráteres (~2,6 s).
///
/// El tablero muestra un sprite recortado del cometa (4 cráteres); girarlo
/// tal cual dejaría ver el corte. Por eso la vuelta pasa por el cometa
/// completo ([kFullCometAsset]):
/// 1. el sprite de 4 cráteres se aleja (se achica y se funde) y en su
///    lugar aparece el cometa completo,
/// 2. el cometa completo da media vuelta, como si camináramos hacia su
///    otro lado,
/// 3. se vuelve a acercar y se funde en el sprite de 4 cráteres de la
///    cara nueva.
///
/// Se dibuja en el mismo lugar y tamaño que el cometa del tablero
/// ([width] × [height], con [headroom] arriba), así el cambio calza.
/// Con "reducir movimiento" es un fundido corto sin giro.
class CometTurn extends StatefulWidget {
  final CometTheme theme;

  /// Sprite de la cara que se deja (sus 4 cráteres conquistados).
  final String fromSprite;

  /// Sprite de la cara que llega.
  final String toSprite;

  final double width;
  final double height;
  final double headroom;

  final Duration duration;
  static const Duration reducedDuration = Duration(milliseconds: 650);

  final VoidCallback? onFinished;

  const CometTurn({
    super.key,
    required this.theme,
    required this.fromSprite,
    required this.toSprite,
    required this.width,
    required this.height,
    required this.headroom,
    this.duration = const Duration(milliseconds: 2600),
    this.onFinished,
  });

  /// Texto que acompaña la vuelta.
  static const String message = '¡Dan la vuelta al cometa!';
  static const String subtitle = 'Del otro lado los esperan 4 cráteres nuevos';

  @override
  State<CometTurn> createState() => _CometTurnState();
}

class _CometTurnState extends State<CometTurn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onFinished?.call();
        });

  bool _reduced = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduced) _controller.duration = CometTurn.reducedDuration;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static double _phase(double t, double begin, double end,
      [Curve curve = Curves.linear]) {
    if (t <= begin) return 0;
    if (t >= end) return 1;
    return curve.transform((t - begin) / (end - begin));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${CometTurn.message} ${CometTurn.subtitle}',
      liveRegion: true,
      child: AbsorbPointer(
        child: SizedBox(
          width: widget.width,
          height: widget.height + widget.headroom,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _reduced
                ? _buildReduced(_controller.value)
                : _buildFrame(_controller.value),
          ),
        ),
      ),
    );
  }

  Widget _sprite(String asset, {double glow = 0}) => ThemedCometSprite(
        sprite: asset,
        theme: widget.theme,
        glowStrength: glow,
      );

  Widget _buildReduced(double t) {
    final out = 1 - _phase(t, 0, 0.5);
    final inn = _phase(t, 0.5, 1);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          top: widget.headroom,
          width: widget.width,
          height: widget.height,
          child: Opacity(opacity: out, child: _sprite(widget.fromSprite)),
        ),
        Positioned(
          left: 0,
          top: widget.headroom,
          width: widget.width,
          height: widget.height,
          child: Opacity(opacity: inn, child: _sprite(widget.toSprite)),
        ),
      ],
    );
  }

  Widget _buildFrame(double t) {
    final w = widget.width;
    final h = widget.height;
    final top = widget.headroom;

    // El cometa completo "lejos": más chico que el sprite, centrado en el
    // área del cometa para que se vea entero.
    final fullW = math.min(w * 0.62, (h + top) * 0.78 * kFullCometAspect);
    final fullH = fullW / kFullCometAspect;
    final fullCenter = Offset(w / 2, top + h * 0.5);

    // El sprite de 4 cráteres NUNCA se achica (sus bordes son un recorte
    // recto): se acerca apenas y se funde. Lo que se aleja, gira y vuelve
    // es el cometa completo, que es redondo y se ve limpio a cualquier
    // tamaño.
    final fromOpacity = 1 - _phase(t, 0.06, 0.2);
    final fromScale = 1 + 0.08 * _phase(t, 0, 0.2);

    // z: 1 = cerca (el completo cubre lo mismo que el sprite), 0 = lejos.
    final goAway = _phase(t, 0.04, 0.34, Curves.easeInOutCubic);
    final comeBack = _phase(t, 0.66, 0.96, Curves.easeInOutCubic);
    final z = 1 - goAway + comeBack;
    final fullIn = _phase(t, 0.04, 0.16);
    final fullOut = _phase(t, 0.86, 0.98);
    final spin = _phase(t, 0.3, 0.7, Curves.easeInOutCubic);
    // Cerca: grande y bajo (se ve la parte de arriba, como el sprite);
    // lejos: entero y centrado.
    const nearScale = 2.3;
    final fullScale = 1 + (nearScale - 1) * z;
    final lift = -math.sin(math.pi * spin) * 14 + h * 0.42 * z;

    // La cara nueva aparece mientras el completo está "cerca".
    final toOpacity = _phase(t, 0.84, 0.97);
    final toScale = 1.08 - 0.08 * _phase(t, 0.84, 1, Curves.easeOutCubic);

    final messageIn = _phase(t, 0.24, 0.42, Curves.easeOutBack);
    final messageOpacity =
        (_phase(t, 0.24, 0.34) * (1 - _phase(t, 0.72, 0.84))).clamp(0.0, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (fromOpacity > 0)
          Positioned(
            left: 0,
            top: top,
            width: w,
            height: h,
            child: Opacity(
              opacity: fromOpacity,
              child: Transform.scale(
                scale: fromScale,
                child: _sprite(widget.fromSprite),
              ),
            ),
          ),
        if (fullIn > 0 && fullOut < 1)
          Positioned(
            left: fullCenter.dx - fullW / 2,
            top: fullCenter.dy - fullH / 2 + lift,
            width: fullW,
            height: fullH,
            child: Opacity(
              opacity: (fullIn * (1 - fullOut)).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: fullScale,
                child: Transform.rotate(
                  angle: math.pi * spin,
                  child: _sprite(kFullCometAsset, glow: 0),
                ),
              ),
            ),
          ),
        if (toOpacity > 0)
          Positioned(
            left: 0,
            top: top,
            width: w,
            height: h,
            child: Opacity(
              opacity: toOpacity,
              child: Transform.scale(
                scale: toScale,
                child: _sprite(widget.toSprite),
              ),
            ),
          ),
        if (messageOpacity > 0)
          Positioned(
            left: 0,
            right: 0,
            top: math.max(0, top - 70),
            child: Opacity(
              opacity: messageOpacity,
              child: Transform.scale(
                scale: 0.6 + 0.4 * messageIn,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CometTurn.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: widget.theme.glow, blurRadius: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CometTurn.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
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
}
