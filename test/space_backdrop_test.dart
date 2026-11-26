import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gymtea3/presentation/animations/space_backdrop.dart';
import 'package:gymtea3/presentation/screens/home/crater_map_screen.dart';

void main() {
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

  test('el marciano mezcla flotar, acercarse, girar y saltar', () {
    final poses = [for (var i = 0; i <= 100; i++) alienMotion(i / 100)];
    expect(poses.map((p) => p.scale).reduce((a, b) => a > b ? a : b),
        greaterThan(1.4), reason: 'se acerca a la pantalla');
    expect(poses.map((p) => p.angle).reduce((a, b) => a > b ? a : b),
        greaterThan(5), reason: 'da una vuelta completa');
    expect(poses.map((p) => p.offset.dy).reduce((a, b) => a < b ? a : b),
        lessThan(-30), reason: 'salta');
    // El ciclo empieza y termina igual (sin saltos al repetirse).
    expect(alienMotion(0).scale, alienMotion(1).scale);
  });
}
