import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/core/theme/comet_theme.dart';
import 'package:gymtea3/data/models/reward_messages.dart';
import 'package:gymtea3/data/models/training_route.dart';
import 'package:gymtea3/presentation/animations/confetti.dart';
import 'package:gymtea3/presentation/screens/rewards/comet_reward_screen.dart';

void main() {
  group('RewardMessages', () {
    test('título, encabezado o mensaje incluyen el nombre del niño', () {
      for (var comet = 0; comet < 10; comet++) {
        for (var seed = 0; seed < 5; seed++) {
          final m = RewardMessages.forComet('Sofía', comet, seed: seed);
          expect(m.title, contains('Sofía'));
          expect('${m.headline} ${m.message}', contains('Sofía'));
          expect(m.gesture, isNotEmpty);
          expect(m.message, isNot(contains('{n}')));
          expect(m.headline, isNot(contains('{n}')));
        }
      }
    });

    test('el título nombra el cometa conquistado', () {
      final m = RewardMessages.forComet('Tomás', 1);
      expect(m.title, '¡Tomás conquistó el ${CometTheme.forRound(1).name}!');
    });

    test('con ruta, el cometa es el planeta de esa ruta', () {
      for (final route in TrainingRoute.values) {
        for (var c = 0; c < 4; c++) {
          final m = RewardMessages.forComet('Tomás', c, route: route);
          expect(m.title, '¡Tomás conquistó el ${route.cometAt(c).name}!');
        }
      }
      // Astronauta parte en el Cometa Lavanda, no en el Limón de la paleta.
      expect(
          RewardMessages.forComet('Tomás', 0, route: TrainingRoute.astronauta)
              .title,
          contains('Cometa Lavanda'));
    });

    test('un nombre de cometa explícito manda', () {
      final m = RewardMessages.forComet('Ana', 0,
          cometName: 'Cometa Volcán', route: TrainingRoute.explorador);
      expect(m.title, '¡Ana conquistó el Cometa Volcán!');
    });

    test('es determinístico para el mismo cometa y semilla', () {
      final a = RewardMessages.forComet('Ana', 3, seed: 42);
      final b = RewardMessages.forComet('Ana', 3, seed: 42);
      expect(a.message, b.message);
      expect(a.gesture, b.gesture);
    });

    test('varía entre cometas consecutivos y entre semillas', () {
      for (var c = 0; c < 12; c++) {
        final now = RewardMessages.forComet('Ana', c);
        final next = RewardMessages.forComet('Ana', c + 1);
        expect(now.message, isNot(next.message));
      }

      final bySeed = {
        for (var s = 0; s < RewardMessages.cometVariantCount; s++)
          RewardMessages.forComet('Ana', 0, seed: s).gesture,
      };
      expect(bySeed.length, RewardMessages.cometVariantCount);
    });

    test('incluye gestos de vínculo (abrazo, chocar los cinco, orgullo…)', () {
      final gestures = {
        for (var s = 0; s < RewardMessages.cometVariantCount; s++)
          RewardMessages.forComet('Ana', 0, seed: s).gesture.toLowerCase(),
      }.join(' | ');
      expect(gestures, contains('abrazo'));
      expect(gestures, contains('chocar los cinco'));
      expect(gestures, contains('orgulloso'));
      expect(gestures, contains('bailar'));
      expect(gestures, contains('familia'));
    });

    test('el viaje completo tiene textos propios', () {
      final cometTexts = {
        for (var s = 0; s < RewardMessages.cometVariantCount; s++)
          RewardMessages.forComet('Luz', 4, seed: s).message,
      };
      for (var s = 0; s < 6; s++) {
        final j =
            RewardMessages.forComet('Luz', 4, seed: s, journeyCompleted: true);
        expect(j.title, '¡Luz completó el viaje!');
        expect(cometTexts, isNot(contains(j.message)));
        expect('${j.headline} ${j.message}', contains('Luz'));
      }
    });

    test('sin nombre usa un genérico y usa solo el primer nombre', () {
      final empty = RewardMessages.forComet('   ', 0);
      expect(empty.title, startsWith('¡Tu hijo/a'));

      final full = RewardMessages.forComet('María José Pérez', 0);
      expect(full.title, startsWith('¡María conquistó'));
    });

    test('el genérico "tu hijo/a" (sesión sin niño) no se recorta', () {
      final m = RewardMessages.forComet('tu hijo/a', 0);
      expect(m.title, startsWith('¡Tu hijo/a conquistó'));
      // Nunca un "tu" suelto (p.ej. "un abrazo a tu y dile…").
      expect('${m.title} ${m.headline} ${m.message}',
          isNot(matches(RegExp(r'tu(?! hijo/a)', caseSensitive: false))));
    });

    test('índices negativos no rompen', () {
      expect(
          () => RewardMessages.forComet('Ana', -3, seed: -7), returnsNormally);
    });
  });

  group('ConfettiParticle', () {
    test('sale hacia arriba y luego cae por gravedad', () {
      final ps = ConfettiParticle.generate(
          count: 30, colors: ConfettiBurst.defaultColors);
      expect(ps, hasLength(30));
      for (final p in ps) {
        expect(p.vy, lessThan(0));
        expect(p.offsetAt(0.1).dy, lessThan(0));
        expect(p.offsetAt(1).dy, greaterThan(p.offsetAt(0.5).dy));
      }
    });
  });

  group('CometRewardScreen', () {
    Future<void> pumpReward(
      WidgetTester tester,
      CometRewardArgs? args, {
      bool reduceMotion = false,
    }) async {
      await tester.binding.setSurfaceSize(const Size(400, 860));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        builder: reduceMotion
            ? (context, child) => MediaQuery(
                  data:
                      MediaQuery.of(context).copyWith(disableAnimations: true),
                  child: child!,
                )
            : null,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  CometRewardScreen.routeName,
                  arguments: args,
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
        routes: {
          CometRewardScreen.routeName: (_) => const CometRewardScreen(seed: 0),
        },
      ));
      await tester.tap(find.text('abrir'));
      // Transición de página + entrada escalonada.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 2000));
    }

    testWidgets('muestra título, mensaje al padre y cierra con pop',
        (tester) async {
      const args = CometRewardArgs(
        childName: 'Sofía',
        cometIndex: 0,
        journeyCompleted: false,
      );
      final expected = RewardMessages.forComet('Sofía', 0, seed: 0);

      await pumpReward(tester, args);

      expect(find.text(expected.title), findsOneWidget);
      expect(find.text(expected.headline), findsOneWidget);
      expect(find.text(expected.message), findsOneWidget);
      expect(find.text('Gesto sugerido: ${expected.gesture}'), findsOneWidget);
      expect(find.byType(ConfettiBurst), findsOneWidget);

      // Tocar al alien relanza el confeti sin romper nada.
      await tester.tap(find.byType(Image).last);
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('¡Al siguiente cometa!'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byType(CometRewardScreen), findsNothing);
      expect(find.text('abrir'), findsOneWidget);
    });

    testWidgets('con ruta muestra el planeta y la ruta', (tester) async {
      const args = CometRewardArgs(
        childName: 'Sofía',
        cometIndex: 1,
        journeyCompleted: false,
        route: TrainingRoute.comandante,
      );
      expect(args.comet, TrainingRoute.comandante.cometAt(1));

      await pumpReward(tester, args);
      expect(
        find.text(
            '¡Sofía conquistó el ${TrainingRoute.comandante.cometAt(1).name}!'),
        findsOneWidget,
      );
      expect(find.text('Ruta Comandante'), findsOneWidget);
    });

    testWidgets('con animaciones reducidas no hay confeti ni rebotes',
        (tester) async {
      await pumpReward(
        tester,
        const CometRewardArgs(
          childName: 'Sofía',
          cometIndex: 0,
          journeyCompleted: false,
        ),
        reduceMotion: true,
      );
      expect(find.byType(ConfettiBurst), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ConfettiBurst),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
      expect(find.text('¡Al siguiente cometa!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('viaje completo cambia el botón', (tester) async {
      await pumpReward(
        tester,
        const CometRewardArgs(
          childName: 'Tomás',
          cometIndex: 4,
          journeyCompleted: true,
        ),
      );
      expect(find.text('¡Tomás completó el viaje!'), findsOneWidget);
      expect(find.text('¡Viaje completo! Volver al mapa'), findsOneWidget);
    });

    testWidgets('sin argumentos usa valores genéricos', (tester) async {
      await pumpReward(tester, null);
      expect(find.byType(CometRewardScreen), findsOneWidget);
      expect(find.textContaining('Tu hijo/a'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
