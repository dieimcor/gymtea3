import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gymtea3/presentation/animations/alien_antics.dart';
import 'package:gymtea3/presentation/animations/space_backdrop.dart';
import 'package:gymtea3/presentation/screens/home/crater_map_screen.dart';

void main() {
  test('el cometa se balancea lento y no tiembla', () {
    const cycle = 16.0; // s, ciclo del marciano
    for (final level in [2, 3]) {
      // Cuenta cruces por cero dentro del ciclo: 3 vaivenes = 5 cruces.
      var crossings = 0;
      var maxAmp = 0.0;
      double? prev;
      for (var i = 0; i <= 16000; i++) {
        final v = cometSway(i / 16000, level);
        maxAmp = v.abs() > maxAmp ? v.abs() : maxAmp;
        if (prev != null && prev != 0 && v != 0 && (prev < 0) != (v < 0)) {
          crossings++;
        }
        prev = v;
      }
      final (:start, :end) = cometSwayWindow;
      final seconds = (end - start) * cycle;
      // Frecuencia ≤ 3 Hz (antes ~19 Hz).
      expect((crossings + 1) / 2 / seconds, lessThanOrEqualTo(3));
      expect(maxAmp, lessThanOrEqualTo(4.0));
    }
    // Explorador no se mueve.
    for (var i = 0; i <= 100; i++) {
      expect(cometSway(i / 100, 1), 0);
    }
  });

  test('la dificultad sube la velocidad y los asteroides', () {
    ParallaxPainter painter(int i) => ParallaxPainter(
          intensity: i,
          stars: const [],
          repaint: const AlwaysStoppedAnimation(0),
        );
    expect(painter(0).speed, lessThan(painter(1).speed));
    expect(painter(1).speed, lessThan(painter(2).speed));
    expect(painter(0).rocks, lessThan(painter(2).rocks));
  });

  testWidgets('con "reducir movimiento" el fondo queda quieto', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: SpaceBackdrop(intensity: 2),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  group('Gracias del marciano', () {
    const stage = AlienStage(
      anchor: Offset(300, 600),
      screen: Size(412, 915),
      panelTop: 160,
      panelCenterX: 206,
    );

    test('cada número empieza y termina en su lugar', () {
      for (final act in AlienAct.values) {
        for (final t in [0.0, 1.0]) {
          final p = alienAct(act, t, stage);
          expect(p.offset.distance, lessThan(1), reason: '$act en t=$t');
          expect(p.scale, closeTo(1, 0.01), reason: '$act en t=$t');
          expect(p.squashX, closeTo(1, 0.01));
          expect(p.squashY, closeTo(1, 0.01));
        }
      }
    });

    test('se acerca mucho a la pantalla', () {
      final p = alienAct(AlienAct.closer, 0.5, stage);
      expect(p.scale, greaterThan(3));
      // Llega cerca del centro de la pantalla.
      final center = stage.anchor + p.offset;
      expect((center.dx - 206).abs(), lessThan(5));
    });

    test('se sube al panel de estadísticas', () {
      final p = alienAct(AlienAct.panel, 0.28, stage);
      final center = stage.anchor + p.offset;
      // Parado sobre el panel, aplastado al aterrizar.
      expect((center.dy - stage.panelTop).abs(), lessThan(stage.size / 2));
      expect((center.dx - stage.panelCenterX).abs(), lessThan(5));
      expect(p.squashY, lessThan(1));
    });

    test('choca contra los dos bordes', () {
      final left = stage.anchor + alienAct(AlienAct.edges, 0.26, stage).offset;
      final right = stage.anchor + alienAct(AlienAct.edges, 0.59, stage).offset;
      expect(left.dx, lessThan(stage.size));
      expect(right.dx, greaterThan(stage.screen.width - stage.size));
      expect(alienAct(AlienAct.edges, 0.26, stage).squashX, lessThan(1));
    });

    test('la voltereta da una vuelta completa', () {
      expect(alienAct(AlienAct.spin, 0.9, stage).angle,
          closeTo(math.pi * 2, 0.01));
    });

    test('no repite el número anterior', () {
      final random = math.Random(7);
      AlienAct? last;
      for (var i = 0; i < 50; i++) {
        final next = nextAlienAct(random, last);
        expect(next, isNot(last));
        last = next;
      }
    });
  });
}
