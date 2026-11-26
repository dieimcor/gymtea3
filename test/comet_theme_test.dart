import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gymtea3/core/theme/comet_theme.dart';
import 'package:gymtea3/presentation/animations/comet_travel.dart';

void main() {
  group('CometTheme', () {
    test('el primer cometa es el arte original, sin filtro', () {
      final first = CometTheme.forRound(0);
      expect(first.isOriginal, isTrue);
      expect(first.hueDegrees % 360, 0);
    });

    test('cada vuelta de la paleta tiene un tono y un nombre distintos', () {
      final n = CometTheme.palette.length;
      final hues = {
        for (var i = 0; i < n; i++) CometTheme.forRound(i).hueDegrees
      };
      final names = {for (var i = 0; i < n; i++) CometTheme.forRound(i).name};
      expect(hues.length, n);
      expect(names.length, n);
    });

    test('las vueltas siguientes al primero se pintan con filtro', () {
      for (var i = 1; i < CometTheme.palette.length; i++) {
        expect(CometTheme.forRound(i).isOriginal, isFalse,
            reason: 'La vuelta $i se veria igual a la primera');
      }
    });

    test('dos vueltas seguidas nunca se ven iguales', () {
      for (var i = 0; i < 20; i++) {
        expect(CometTheme.forRound(i).hueDegrees,
            isNot(CometTheme.forRound(i + 1).hueDegrees));
      }
    });

    test('la paleta se repite en ciclo', () {
      final n = CometTheme.palette.length;
      expect(identical(CometTheme.forRound(n), CometTheme.forRound(0)), isTrue);
      expect(identical(CometTheme.forRound(n + 2), CometTheme.forRound(2)),
          isTrue);
    });

    test('la matriz de 0 grados es la identidad', () {
      final m = CometTheme.hueRotationMatrix(0);
      const identity = [
        1, 0, 0, 0, 0, //
        0, 1, 0, 0, 0, //
        0, 0, 1, 0, 0, //
        0, 0, 0, 1, 0, //
      ];
      expect(m.length, 20);
      for (var i = 0; i < 20; i++) {
        expect(m[i], closeTo(identity[i], 1e-9), reason: 'posicion $i');
      }
    });

    test('rotar el tono conserva la luminancia del gris', () {
      // Un gris (r = g = b) debe seguir siendo gris: cada fila suma 1.
      final m = CometTheme.hueRotationMatrix(225);
      for (var row = 0; row < 3; row++) {
        final sum = m[row * 5] + m[row * 5 + 1] + m[row * 5 + 2];
        expect(sum, closeTo(1, 1e-9));
      }
    });

    test('el mensaje del viaje nombra al cometa de destino', () {
      expect(CometTravel.messageFor(CometTheme.forRound(1)),
          '¡Rumbo al ${CometTheme.forRound(1).name}!');
    });
  });

  group('ThemedCometSprite', () {
    testWidgets('el original no lleva filtro y los demas si', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Row(
          children: [
            SizedBox(
              width: 100,
              height: 90,
              child: ThemedCometSprite(
                key: const ValueKey('orig'),
                sprite: 'assets/images/craters/crater_1.png',
                theme: CometTheme.forRound(0),
              ),
            ),
            SizedBox(
              width: 100,
              height: 90,
              child: ThemedCometSprite(
                key: const ValueKey('otro'),
                sprite: 'assets/images/craters/crater_1.png',
                theme: CometTheme.forRound(1),
              ),
            ),
          ],
        ),
      ));

      expect(
        find.descendant(
            of: find.byKey(const ValueKey('orig')),
            matching: find.byType(ColorFiltered)),
        findsNothing,
      );
      expect(
        find.descendant(
            of: find.byKey(const ValueKey('otro')),
            matching: find.byType(ColorFiltered)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('CometTravel', () {
    testWidgets('dura unos 3 s, muestra el destino y avisa al terminar',
        (tester) async {
      var finished = false;
      await tester.pumpWidget(MaterialApp(
        home: CometTravel(
          from: CometTheme.forRound(0),
          to: CometTheme.forRound(1),
          fromSprite: 'assets/images/craters/crater_5.png',
          toSprite: 'assets/images/craters/crater_1.png',
          onFinished: () => finished = true,
        ),
      ));

      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.text('¡Rumbo al Cometa Lavanda!'), findsOneWidget);
      expect(finished, isFalse);

      await tester.pump(const Duration(milliseconds: 2200));
      expect(finished, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
