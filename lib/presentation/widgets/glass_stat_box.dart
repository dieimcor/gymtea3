import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Caja de estadística estilo "vidrio" (glassmorphism, sin fondo sólido):
/// desenfoca lo que hay detrás y deja un borde claro.
///
/// Cuando [value] sube (al volver al mapa tras un cráter), espera [delay]
/// —así las tres cajas suben en cascada—, cuenta desde el valor anterior,
/// da un saltito y deja flotar un "+N" del color de la caja. La primera
/// vez cuenta desde 0. Con "reducir movimiento" muestra el valor sin
/// animar.
class GlassStatBox extends StatefulWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;

  /// Formato del número (p. ej. segundos → "24 min").
  final String Function(int value)? format;

  /// Formato del "+N" (p. ej. segundos → "+6 min").
  final String Function(int delta)? formatDelta;

  /// Espera antes de animar, para la cascada.
  final Duration delay;

  /// Borde de la caja: el color de la ruta (la dificultad elegida).
  final Color? borderColor;

  const GlassStatBox({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.format,
    this.formatDelta,
    this.delay = Duration.zero,
    this.borderColor,
  });

  static const Duration countDuration = Duration(milliseconds: 900);

  @override
  State<GlassStatBox> createState() => _GlassStatBoxState();
}

class _GlassStatBoxState extends State<GlassStatBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: GlassStatBox.countDuration,
  );

  int _from = 0;
  int _to = 0;
  int _delta = 0;
  bool _reduced = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_started) return;
    _started = true;
    _to = widget.value;
    if (_reduced) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(GlassStatBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == _to) return;
    final shownNow = _shown;
    final grew = widget.value > _to;
    _from = shownNow;
    _delta = grew ? widget.value - _to : 0;
    _to = widget.value;
    if (_reduced) {
      _controller.value = 1;
      return;
    }
    _controller.value = 0;
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _shown {
    final t = Curves.easeOutCubic.transform(_controller.value);
    return (_from + (_to - _from) * t).round();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 7, 6, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: widget.borderColor?.withValues(alpha: 0.9) ??
                  Colors.white.withValues(alpha: 0.2),
              width: widget.borderColor != null ? 1.6 : 1,
            ),
            boxShadow: widget.borderColor == null
                ? null
                : [
                    BoxShadow(
                      color: widget.borderColor!.withValues(alpha: 0.25),
                      blurRadius: 12,
                    ),
                  ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final animating = t > 0 && t < 1 && _delta > 0;
              // Saltito al empezar a contar.
              final bump = animating
                  ? 1 + 0.18 * (1 - Curves.elasticOut.transform(t))
                  : 1.0;
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.22),
                          boxShadow: animating
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.6),
                                    blurRadius: 14,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(widget.icon, size: 15, color: color),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.scale(
                              alignment: Alignment.centerLeft,
                              scale: bump.clamp(0.8, 1.4),
                              child: Text(
                                widget.format?.call(_shown) ?? '$_shown',
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_delta > 0 && t > 0 && t < 1)
                    Positioned(
                      top: -4 - 22 * t,
                      right: 2,
                      child: Opacity(
                        opacity: (t < 0.2 ? t / 0.2 : 1 - (t - 0.2) / 0.8)
                            .clamp(0.0, 1.0),
                        child: Text(
                          widget.formatDelta?.call(_delta) ?? '+$_delta',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: color,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
