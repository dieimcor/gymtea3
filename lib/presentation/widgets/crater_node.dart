import 'package:flutter/material.dart';

import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/data/models/difficulty.dart';

enum CraterStatus { completed, available, locked }

/// Cráter del mapa principal — un cráter por nivel.
///
/// Se dibuja en Flutter (no es un sprite) para que escale a cualquier
/// cantidad de niveles manteniendo la paleta de la ilustración:
/// boca marrón = disponible, laguna turquesa = completado, apagado = bloqueado.
class CraterNode extends StatelessWidget {
  final int level;
  final CraterStatus status;
  final Dificultad dificultad;
  final double size;
  final VoidCallback? onTap;

  const CraterNode({
    super.key,
    required this.level,
    required this.status,
    required this.dificultad,
    this.size = 132,
    this.onTap,
  });

  bool get _isLocked => status == CraterStatus.locked;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: !_isLocked,
      label: _isLocked
          ? 'Cráter $level bloqueado'
          : 'Cráter $level, dificultad ${dificultad.label}',
      child: GestureDetector(
        onTap: _isLocked ? null : onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCrater(),
            const SizedBox(height: 10),
            Text(
              'Cráter $level',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _isLocked
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            _buildBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildCrater() {
    return SizedBox(
      width: size,
      height: size * 0.78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Borde elevado del cráter (la roca alrededor de la boca)
          Container(
            width: size,
            height: size * 0.78,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(
                Radius.elliptical(size / 2, size * 0.39),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _isLocked
                    ? const [Color(0xFF5A5F6B), Color(0xFF3C414B)]
                    : const [Color(0xFFF6E0A4), Color(0xFFD9A05B)],
              ),
              boxShadow: [
                if (!_isLocked)
                  BoxShadow(
                    color: _glowColor.withValues(alpha: 0.45),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
              ],
            ),
          ),

          // Boca del cráter
          Container(
            width: size * 0.74,
            height: size * 0.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.elliptical(size * 0.37, size * 0.25),
              ),
              gradient: RadialGradient(
                colors: _mouthColors,
              ),
            ),
            alignment: Alignment.center,
            child: _buildMouthContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMouthContent() {
    switch (status) {
      case CraterStatus.locked:
        return Icon(
          Icons.lock_rounded,
          color: Colors.white.withValues(alpha: 0.45),
          size: size * 0.2,
        );
      case CraterStatus.completed:
        return Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: size * 0.26,
        );
      case CraterStatus.available:
        return Text(
          '$level',
          style: TextStyle(
            fontSize: size * 0.26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 6),
            ],
          ),
        );
    }
  }

  Widget _buildBadge() {
    if (_isLocked) {
      return Text(
        'Bloqueado',
        style: TextStyle(
          fontSize: 11,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _difficultyColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _difficultyColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${dificultad.label} · ${dificultad.exerciseCount} ejercicios',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _difficultyColor,
        ),
      ),
    );
  }

  List<Color> get _mouthColors {
    switch (status) {
      case CraterStatus.completed:
        return const [Color(0xFF4FC3C7), Color(0xFF2E7D7F)];
      case CraterStatus.available:
        return const [Color(0xFF8A4B20), Color(0xFF3E1F0C)];
      case CraterStatus.locked:
        return const [Color(0xFF2A2E37), Color(0xFF14171D)];
    }
  }

  Color get _glowColor => status == CraterStatus.completed
      ? const Color(0xFF4FC3C7)
      : AppTheme.goldAccent;

  Color get _difficultyColor {
    switch (dificultad) {
      case Dificultad.facil:
        return AppTheme.levelHigh;
      case Dificultad.medio:
        return AppTheme.goldAccent;
      case Dificultad.dificil:
        return const Color(0xFFFF8A65);
    }
  }
}
