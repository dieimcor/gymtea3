import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/data/models/difficulty.dart';

enum CraterStatus { completed, available, locked }

/// Posición de un cráter pintado en el sprite del cometa.
///
/// Las coordenadas son fracciones del tamaño de la imagen y salieron de
/// medir las bocas de los cráteres en el arte, así que el marcador cae
/// justo encima del cráter dibujado.
class CraterSpot {
  final double cx;
  final double cy;
  final double rx;
  final double ry;

  const CraterSpot(this.cx, this.cy, this.rx, this.ry);

  /// Los 4 cráteres del sprite, en el orden en que se recorren.
  ///
  /// El primero es la laguna de la cima: en `crater_1` está turquesa
  /// apagada y en `crater_2` se enciende, así que es la que el arte
  /// conquista primero.
  static const List<CraterSpot> all = [
    // La cima va con cy negativa a proposito: el marcador queda flotando
    // en el espacio, justo encima del crater.
    CraterSpot(0.537, -0.055, 0.075, 0.055), // cima
    CraterSpot(0.186, 0.211, 0.075, 0.062), // arriba izquierda
    CraterSpot(0.727, 0.270, 0.105, 0.078), // arriba derecha
    CraterSpot(0.289, 0.865, 0.146, 0.120), // abajo izquierda (el grande)
  ];
}

/// Marcador que se dibuja **sobre** el cráter pintado del sprite.
///
/// No dibuja el cráter: el cráter ya está en la ilustración. Solo agrega
/// el número, el candado o el visto, más la etiqueta de dificultad.
///
/// Está animado para el niño:
/// - el cráter **disponible** late suavemente, invitando a tocarlo;
/// - al pasar a **completado** hace un "pop" con brillo y destellos;
/// - el **bloqueado** tiembla un poco si se toca.
///
/// Con "reducir movimiento" activo no hay latido continuo: el pop de
/// conquista se mantiene (es una sola vez y corto).
class CraterMarker extends StatefulWidget {
  final int level;
  final CraterStatus status;
  final Dificultad dificultad;

  /// Radio del cráter pintado, en píxeles lógicos.
  final Size craterSize;

  /// Ejercicios del cráter en la ruta actual (la ruta Comandante suma
  /// uno). Si es null se usa el de la dificultad.
  final int? exerciseCount;

  final VoidCallback? onTap;

  const CraterMarker({
    super.key,
    required this.level,
    required this.status,
    required this.dificultad,
    required this.craterSize,
    this.exerciseCount,
    this.onTap,
  });

  @override
  State<CraterMarker> createState() => _CraterMarkerState();
}

class _CraterMarkerState extends State<CraterMarker>
    with TickerProviderStateMixin {
  /// Latido del disponible (se repite mientras siga disponible).
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  /// "Pop" de conquista (una sola vez).
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// Temblor al tocar un bloqueado.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  late final Animation<double> _popScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: 1, end: 1.45)
          .chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 25,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.45, end: 1)
          .chain(CurveTween(curve: Curves.elasticOut)),
      weight: 75,
    ),
  ]).animate(_pop);

  bool get _isLocked => widget.status == CraterStatus.locked;

  /// `true` si el sistema pide reducir el movimiento.
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncPulse();
  }

  @override
  void didUpdateWidget(CraterMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo celebra si es el mismo cráter: al renumerar la tanda el
    // marcador recibe otro nivel y eso no es una conquista.
    if (oldWidget.level == widget.level &&
        oldWidget.status != CraterStatus.completed &&
        widget.status == CraterStatus.completed) {
      _pop.forward(from: 0);
    }
    if (oldWidget.status != widget.status) _syncPulse();
  }

  void _syncPulse() {
    if (widget.status == CraterStatus.available && !_reduceMotion) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _pop.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_isLocked) {
      _shake.forward(from: 0);
      return;
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final badge = (widget.craterSize.shortestSide * 0.85).clamp(30.0, 58.0);

    return Semantics(
      button: !_isLocked,
      label: _isLocked
          ? 'Cráter ${widget.level} bloqueado'
          : 'Cráter ${widget.level}, dificultad ${widget.dificultad.label}',
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        // El SizedBox define el area tocable (el crater pintado); el
        // contenido se centra y puede sobresalir sin desbordar el layout.
        child: SizedBox(
          width: widget.craterSize.width,
          height: widget.craterSize.height,
          child: Center(
            child: OverflowBox(
              minWidth: 0,
              minHeight: 0,
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAnimatedBadge(badge),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: _isLocked
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: _buildLabel(),
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

  Widget _buildAnimatedBadge(double size) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _pop, _shake]),
      builder: (context, _) {
        final beat = Curves.easeInOut.transform(_pulse.value);
        final scale = (1 + 0.08 * beat) * _popScale.value;
        final shakeT = _shake.value;
        final shakeDx = math.sin(shakeT * math.pi * 6) * 6 * (1 - shakeT);

        return Transform.translate(
          offset: Offset(shakeDx, 0),
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (widget.status == CraterStatus.available && !_reduceMotion)
                  _buildPulseRing(size, beat),
                if (_pop.isAnimating) ..._buildPopEffects(size, _pop.value),
                Transform.scale(
                  scale: scale,
                  child: _buildBadge(size, glow: beat + _popGlow),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Brillo extra durante el pop (sube rápido y se apaga).
  double get _popGlow =>
      _pop.isAnimating ? math.sin(math.pi * _pop.value) * 2 : 0;

  /// Aro que se expande desde el disponible al ritmo del latido.
  Widget _buildPulseRing(double size, double beat) {
    final ring = size * (1.05 + 0.35 * beat);
    return IgnorePointer(
      child: OverflowBox(
        maxWidth: ring,
        maxHeight: ring,
        child: Container(
          width: ring,
          height: ring,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _badgeColor.withValues(alpha: 0.55 * (1 - beat) + 0.1),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  /// Onda y destellos que salen del cráter recién conquistado.
  List<Widget> _buildPopEffects(double size, double t) {
    final wave = size * (1 + 1.6 * Curves.easeOut.transform(t));
    final fade = (1 - t).clamp(0.0, 1.0);

    return [
      IgnorePointer(
        child: OverflowBox(
          maxWidth: wave,
          maxHeight: wave,
          child: Container(
            width: wave,
            height: wave,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.goldAccent.withValues(alpha: 0.8 * fade),
                width: 3,
              ),
            ),
          ),
        ),
      ),
      for (var i = 0; i < 6; i++)
        IgnorePointer(
          child: Transform.translate(
            offset: Offset.fromDirection(
              i * math.pi / 3 - math.pi / 2,
              size * (0.4 + 0.9 * Curves.easeOut.transform(t)),
            ),
            child: Opacity(
              opacity: fade,
              child: Icon(
                Icons.star_rounded,
                size: size * 0.32,
                color: AppTheme.goldAccent,
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildBadge(double size, {double glow = 0}) {
    final color = _badgeColor;
    // Container simple: el brillo ya se anima con el latido y el pop; un
    // AnimatedContainer aquí interpolaría la sombra en cada frame.
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 14 + 10 * glow,
            spreadRadius: 1 + 2 * glow,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey('${widget.status}-${widget.level}'),
          child: _buildBadgeContent(size),
        ),
      ),
    );
  }

  Widget _buildBadgeContent(double size) {
    switch (widget.status) {
      case CraterStatus.locked:
        return Icon(Icons.lock_rounded, color: Colors.white, size: size * 0.5);
      case CraterStatus.completed:
        return Icon(Icons.check_rounded, color: Colors.white, size: size * 0.6);
      case CraterStatus.available:
        return Text(
          '${widget.level}',
          style: TextStyle(
            fontSize: size * 0.52,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
    }
  }

  Widget _buildLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${widget.dificultad.label} · '
        '${widget.exerciseCount ?? widget.dificultad.exerciseCount}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Color get _badgeColor {
    switch (widget.status) {
      case CraterStatus.locked:
        return const Color(0xFF4A5059);
      case CraterStatus.completed:
        return const Color(0xFF2E9E8F);
      case CraterStatus.available:
        switch (widget.dificultad) {
          case Dificultad.facil:
            return AppTheme.levelHigh;
          case Dificultad.medio:
            return const Color(0xFFE09B2D);
          case Dificultad.dificil:
            return const Color(0xFFE2553C);
        }
    }
  }
}
