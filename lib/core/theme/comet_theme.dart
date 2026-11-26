import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Aspecto de cada cometa del viaje.
///
/// El arte trae un solo cometa (con sus 5 estados de avance). Para que
/// cada vuelta se sienta como un cometa nuevo, el mismo sprite se pinta
/// con otro tono ([hueDegrees]), otro halo ([glow]) y otro nombre.
@immutable
class CometTheme {
  final String name;

  /// Rotación de tono aplicada al sprite, en grados. 0 = arte original.
  final double hueDegrees;

  /// Saturación relativa (1 = original).
  final double saturation;

  /// Color del halo que rodea al cometa.
  final Color glow;

  const CometTheme({
    required this.name,
    required this.hueDegrees,
    required this.glow,
    this.saturation = 1,
  });

  static const limon =
      CometTheme(name: 'Cometa Limón', hueDegrees: 0, glow: Color(0xFF7FD8E8));
  static const lavanda = CometTheme(
      name: 'Cometa Lavanda', hueDegrees: 225, glow: Color(0xFFC89BFF));
  static const menta =
      CometTheme(name: 'Cometa Menta', hueDegrees: 95, glow: Color(0xFF7DF2B0));
  static const frutilla = CometTheme(
      name: 'Cometa Frutilla', hueDegrees: 300, glow: Color(0xFFFF8FB8));
  static const oceano = CometTheme(
      name: 'Cometa Océano', hueDegrees: 160, glow: Color(0xFF6FB6FF));
  static const volcan = CometTheme(
    name: 'Cometa Volcán',
    hueDegrees: 330,
    saturation: 1.25,
    glow: Color(0xFFFF7A45),
  );

  /// Todos los cometas, en un orden en que dos seguidos nunca se parecen.
  /// Cada ruta de entrenamiento usa su propio par (ver `TrainingRoute`).
  static const List<CometTheme> palette = [
    limon,
    lavanda,
    menta,
    frutilla,
    oceano,
    volcan,
  ];

  /// Cometa de la vuelta [roundIndex] (0-based).
  static CometTheme forRound(int roundIndex) =>
      palette[roundIndex.abs() % palette.length];

  /// `true` si el sprite se dibuja tal cual, sin filtro de color.
  bool get isOriginal => hueDegrees % 360 == 0 && saturation == 1;

  /// Filtro de color para el sprite (rotación de tono + saturación).
  ColorFilter get colorFilter =>
      ColorFilter.matrix(hueRotationMatrix(hueDegrees, saturation));

  /// Matriz 5×4 de rotación de tono (luminancia preservada) con ajuste de
  /// saturación, en el formato de [ColorFilter.matrix].
  static List<double> hueRotationMatrix(double degrees, [double sat = 1]) {
    final r = degrees * math.pi / 180;
    final c = math.cos(r);
    final s = math.sin(r);
    const lr = 0.213, lg = 0.715, lb = 0.072;

    // Rotación de tono.
    final h = <double>[
      lr + c * (1 - lr) + s * (-lr),
      lg + c * (-lg) + s * (-lg),
      lb + c * (-lb) + s * (1 - lb),
      lr + c * (-lr) + s * 0.143,
      lg + c * (1 - lg) + s * 0.140,
      lb + c * (-lb) + s * (-0.283),
      lr + c * (-lr) + s * (-(1 - lr)),
      lg + c * (-lg) + s * lg,
      lb + c * (1 - lb) + s * lb,
    ];

    // Saturación.
    final sr = (1 - sat) * lr, sg = (1 - sat) * lg, sb = (1 - sat) * lb;
    final m = <double>[
      sr + sat, sg, sb,
      sr, sg + sat, sb,
      sr, sg, sb + sat,
    ];

    // m × h (3×3).
    final out = List<double>.filled(9, 0);
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        var v = 0.0;
        for (var k = 0; k < 3; k++) {
          v += m[i * 3 + k] * h[k * 3 + j];
        }
        out[i * 3 + j] = v;
      }
    }

    return [
      out[0], out[1], out[2], 0, 0,
      out[3], out[4], out[5], 0, 0,
      out[6], out[7], out[8], 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}
