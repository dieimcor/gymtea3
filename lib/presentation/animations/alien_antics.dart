import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Las "gracias" del marciano del mapa cuando nadie hace nada.
///
/// Entre una y otra flota tranquilo ([alienIdle]); de vez en cuando hace
/// un número ([AlienAct]): se acerca mucho a la pantalla, se sube al panel
/// de estadísticas, choca contra los bordes, da una voltereta o saluda.
/// Todo es una función pura del avance `t` (0 → 1) y de dónde están las
/// cosas en pantalla ([AlienStage]), así se puede probar sin reloj.
enum AlienAct { closer, panel, edges, spin, wave }

/// Cuánto dura cada número.
Duration alienActDuration(AlienAct act) => switch (act) {
      AlienAct.closer => const Duration(milliseconds: 3600),
      AlienAct.panel => const Duration(milliseconds: 5200),
      AlienAct.edges => const Duration(milliseconds: 4200),
      AlienAct.spin => const Duration(milliseconds: 1800),
      AlienAct.wave => const Duration(milliseconds: 2400),
    };

/// Dónde están las cosas, en coordenadas de pantalla.
class AlienStage {
  /// Centro del marciano en reposo (su lugar junto al cráter).
  final Offset anchor;

  /// Tamaño de la pantalla.
  final Size screen;

  /// Borde superior y centro del panel de estadísticas.
  final double panelTop;
  final double panelCenterX;

  /// Lado del marciano.
  final double size;

  const AlienStage({
    required this.anchor,
    required this.screen,
    required this.panelTop,
    required this.panelCenterX,
    this.size = 72,
  });
}

/// Pose del marciano relativa a su lugar de reposo. [squashX]/[squashY]
/// lo aplastan (al aterrizar o chocar).
typedef AlienPose = ({
  Offset offset,
  double angle,
  double scale,
  double squashX,
  double squashY,
});

const AlienPose _rest =
    (offset: Offset.zero, angle: 0, scale: 1, squashX: 1, squashY: 1);

/// Flotar en reposo. [clock] da una vuelta cada ~16 s.
AlienPose alienIdle(double clock) => (
      offset: Offset(0, math.sin(clock * math.pi * 2 * 5) * 6),
      angle: math.sin(clock * math.pi * 2 * 3) * 0.06,
      scale: 1,
      squashX: 1,
      squashY: 1,
    );

double _ease(double t) => Curves.easeInOut.transform(t.clamp(0.0, 1.0));

/// Avance de 0 a 1 dentro de la ventana [a, b] de t.
double _seg(double t, double a, double b) =>
    ((t - a) / (b - a)).clamp(0.0, 1.0);

/// Aplastón que se recupera: 1 → [amount] → 1 durante la ventana.
double _squash(double t, double a, double b, double amount) {
  if (t < a || t > b) return 1;
  final k = _seg(t, a, b);
  // Golpe seco y vuelve rebotando.
  return 1 + (amount - 1) * math.sin(k * math.pi) * (1 - k * 0.3);
}

/// Salto en arco de [from] a [to] con altura [height].
Offset _arc(Offset from, Offset to, double k, double height) {
  final e = _ease(k);
  return Offset.lerp(from, to, e)! + Offset(0, -height * math.sin(k * math.pi));
}

/// Pose de un número en el instante [t] (0 → 1). Empieza y termina en el
/// lugar de reposo, así encadena sin saltos con el flotar.
AlienPose alienAct(AlienAct act, double t, AlienStage s) {
  t = t.clamp(0.0, 1.0);
  switch (act) {
    case AlienAct.closer:
      return _closer(t, s);
    case AlienAct.panel:
      return _panel(t, s);
    case AlienAct.edges:
      return _edges(t, s);
    case AlienAct.spin:
      return _spin(t);
    case AlienAct.wave:
      return _wave(t);
  }
}

/// Se acerca mucho a la pantalla: vuela al centro, crece hasta casi
/// tapar todo, mira a un lado y al otro, y vuelve.
AlienPose _closer(double t, AlienStage s) {
  final target = Offset(s.screen.width / 2, s.screen.height * 0.42) - s.anchor;
  final e = t < 0.25
      ? _ease(_seg(t, 0, 0.25))
      : t > 0.75
          ? 1 - _ease(_seg(t, 0.75, 1))
          : 1.0;
  final hold = t > 0.25 && t < 0.75 ? _seg(t, 0.25, 0.75) : 0.0;
  // Mira a un lado y al otro mientras está cerca.
  final look = math.sin(hold * math.pi * 2) * 0.12;
  final breathe = 1 + 0.04 * math.sin(hold * math.pi * 4);
  return (
    offset: target * e,
    angle: look,
    scale: (1 + 2.4 * e) * breathe,
    squashX: 1,
    squashY: 1,
  );
}

/// Se sube al panel de estadísticas: salta hasta su borde, aterriza
/// aplastándose, camina dando saltitos y vuelve de un brinco.
AlienPose _panel(double t, AlienStage s) {
  // Parado sobre las cajas de estadísticas (bajo la fila del cometa), no
  // en el borde de arriba del panel, que queda pegado a la barra del
  // teléfono.
  final seat = Offset(s.panelCenterX, s.panelTop + s.size * 0.15) - s.anchor;
  const walk = 46.0;

  if (t < 0.25) {
    final k = _seg(t, 0, 0.25);
    return (
      offset: _arc(Offset.zero, seat, k, 120),
      angle: math.sin(k * math.pi) * -0.35,
      scale: 1,
      squashX: 1,
      squashY: 1,
    );
  }
  if (t < 0.66) {
    // Aterriza y camina: va y vuelve con saltitos.
    final k = _seg(t, 0.3, 0.66);
    final dx = math.sin(k * math.pi * 2) * walk;
    final hop = (math.sin(k * math.pi * 6)).abs() * 10;
    return (
      offset: seat + Offset(dx, -hop),
      angle: math.cos(k * math.pi * 2) * 0.14,
      scale: 1,
      squashX: _squash(t, 0.25, 0.32, 1.25),
      squashY: _squash(t, 0.25, 0.32, 0.72),
    );
  }
  if (t < 0.94) {
    final k = _seg(t, 0.66, 0.94);
    return (
      offset: _arc(seat, Offset.zero, k, 80),
      angle: math.sin(k * math.pi) * 0.4,
      scale: 1,
      squashX: 1,
      squashY: 1,
    );
  }
  return (
    offset: Offset.zero,
    angle: 0,
    scale: 1,
    squashX: _squash(t, 0.94, 1, 1.2),
    squashY: _squash(t, 0.94, 1, 0.78),
  );
}

/// Choca contra los bordes: sale disparado a la izquierda, se aplasta en
/// el borde, rebota hasta el otro lado, se aplasta otra vez y vuelve
/// mareado a su lugar.
AlienPose _edges(double t, AlienStage s) {
  final half = s.size / 2;
  final y = -50.0;
  final left = Offset(half * 0.8 - s.anchor.dx, y);
  final right = Offset(s.screen.width - half * 0.8 - s.anchor.dx, y);

  Offset offset;
  if (t < 0.22) {
    final k = Curves.easeIn.transform(_seg(t, 0, 0.22));
    offset = Offset.lerp(Offset.zero, left, k)!;
  } else if (t < 0.3) {
    offset = left;
  } else if (t < 0.55) {
    final k = _ease(_seg(t, 0.3, 0.55));
    offset = Offset.lerp(left, right, k)! +
        Offset(0, -30 * math.sin(_seg(t, 0.3, 0.55) * math.pi));
  } else if (t < 0.63) {
    offset = right;
  } else {
    final k = _ease(_seg(t, 0.63, 1));
    offset = Offset.lerp(right, Offset.zero, k)!;
  }

  // Mareado al volver: se bambolea cada vez menos.
  final dizzy = t > 0.63
      ? math.sin(_seg(t, 0.63, 1) * math.pi * 5) * 0.35 * (1 - _seg(t, 0.63, 1))
      : 0.0;
  final hitL = t >= 0.22 && t <= 0.3;
  final hitR = t >= 0.55 && t <= 0.63;
  return (
    offset: offset,
    angle: dizzy + (hitL ? -0.12 : 0) + (hitR ? 0.12 : 0),
    scale: 1,
    squashX: _squash(t, 0.22, 0.3, 0.6) * _squash(t, 0.55, 0.63, 0.6),
    squashY: _squash(t, 0.22, 0.3, 1.25) * _squash(t, 0.55, 0.63, 1.25),
  );
}

/// Voltereta: salta y da una vuelta completa en el aire.
AlienPose _spin(double t) {
  final up = math.sin(t * math.pi);
  return (
    offset: Offset(0, -60 * up),
    angle: _ease(_seg(t, 0.1, 0.9)) * math.pi * 2,
    scale: 1 + 0.1 * up,
    squashX: _squash(t, 0.9, 1, 1.15),
    squashY: _squash(t, 0.9, 1, 0.8),
  );
}

/// Saluda: se agranda un poco y se mece de lado a lado.
AlienPose _wave(double t) {
  final e = math.sin(t * math.pi);
  return (
    offset: Offset(0, -14 * e),
    angle: math.sin(t * math.pi * 6) * 0.3 * e,
    scale: 1 + 0.18 * e,
    squashX: 1,
    squashY: 1,
  );
}

/// Elige el próximo número sin repetir el anterior.
AlienAct nextAlienAct(math.Random random, AlienAct? last) {
  final options = [
    for (final a in AlienAct.values)
      if (a != last) a
  ];
  return options[random.nextInt(options.length)];
}

/// Pausa de flotar entre números (de 4 a 7 s).
Duration alienIdleGap(math.Random random) =>
    Duration(milliseconds: 4000 + random.nextInt(3000));

/// Junta el flotar y el número en curso.
AlienPose combineAlienPose(AlienPose idle, AlienPose? act) {
  if (act == null) return idle;
  return (
    offset: idle.offset + act.offset,
    angle: idle.angle + act.angle,
    scale: act.scale,
    squashX: act.squashX,
    squashY: act.squashY,
  );
}

/// Pose neutra (sin número).
const AlienPose alienRestPose = _rest;
