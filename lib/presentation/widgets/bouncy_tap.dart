import 'package:flutter/material.dart';

/// Envuelve cualquier botón para que "rebote" al tocarlo: se achica al
/// presionar y vuelve con un pequeño resorte. Pensado para una UI
/// infantil; no reemplaza al `onPressed` del hijo, solo anima.
class BouncyTap extends StatefulWidget {
  final Widget child;

  /// Escala mínima al presionar.
  final double pressedScale;

  const BouncyTap({super.key, required this.child, this.pressedScale = 0.9});

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap>
    with SingleTickerProviderStateMixin {
  // Se crean en initState (no perezosos): con movimiento reducido el build
  // no los toca, y crearlos recién en dispose busca ancestros ya inactivos.
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 380),
    );
    _scale = Tween<double>(
      begin: 1,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.elasticIn,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Con movimiento reducido no hay rebote al tocar.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return widget.child;
    }
    return Listener(
      onPointerDown: (_) => _controller.forward(),
      onPointerUp: (_) => _controller.reverse(),
      onPointerCancel: (_) => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
