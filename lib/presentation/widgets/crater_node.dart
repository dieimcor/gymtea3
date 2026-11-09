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
  static const List<CraterSpot> all = [
    CraterSpot(0.186, 0.211, 0.075, 0.062), // arriba izquierda
    CraterSpot(0.727, 0.270, 0.105, 0.078), // arriba derecha
    CraterSpot(0.547, 0.937, 0.052, 0.046), // abajo centro
    CraterSpot(0.289, 0.865, 0.146, 0.120), // abajo izquierda (el grande)
  ];
}

/// Marcador que se dibuja **sobre** el cráter pintado del sprite.
///
/// No dibuja el cráter: el cráter ya está en la ilustración. Solo agrega
/// el número, el candado o el visto, más la etiqueta de dificultad.
class CraterMarker extends StatelessWidget {
  final int level;
  final CraterStatus status;
  final Dificultad dificultad;

  /// Radio del cráter pintado, en píxeles lógicos.
  final Size craterSize;

  final VoidCallback? onTap;

  const CraterMarker({
    super.key,
    required this.level,
    required this.status,
    required this.dificultad,
    required this.craterSize,
    this.onTap,
  });

  bool get _isLocked => status == CraterStatus.locked;

  @override
  Widget build(BuildContext context) {
    final badge = (craterSize.shortestSide * 0.85).clamp(30.0, 58.0);

    return Semantics(
      button: !_isLocked,
      label: _isLocked
          ? 'Cráter $level bloqueado'
          : 'Cráter $level, dificultad ${dificultad.label}',
      child: GestureDetector(
        onTap: _isLocked ? null : onTap,
        behavior: HitTestBehavior.opaque,
        // El SizedBox define el area tocable (el crater pintado); el
        // contenido se centra y puede sobresalir sin desbordar el layout.
        child: SizedBox(
          width: craterSize.width,
          height: craterSize.height,
          child: Center(
            child: OverflowBox(
              minWidth: 0,
              minHeight: 0,
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBadge(badge),
                  if (!_isLocked) ...[
                    const SizedBox(height: 3),
                    _buildLabel(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _badgeColor,
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
        boxShadow: [
          BoxShadow(
            color: _badgeColor.withValues(alpha: 0.6),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: _buildBadgeContent(size),
    );
  }

  Widget _buildBadgeContent(double size) {
    switch (status) {
      case CraterStatus.locked:
        return Icon(Icons.lock_rounded, color: Colors.white, size: size * 0.5);
      case CraterStatus.completed:
        return Icon(Icons.check_rounded, color: Colors.white, size: size * 0.6);
      case CraterStatus.available:
        return Text(
          '$level',
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
        '${dificultad.label} · ${dificultad.exerciseCount}',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Color get _badgeColor {
    switch (status) {
      case CraterStatus.locked:
        return const Color(0xFF4A5059);
      case CraterStatus.completed:
        return const Color(0xFF2E9E8F);
      case CraterStatus.available:
        switch (dificultad) {
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
