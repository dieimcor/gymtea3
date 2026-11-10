import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymtea3/core/constants/app_constants.dart';
import 'package:gymtea3/data/models/difficulty.dart';
import 'package:gymtea3/data/models/routine_model.dart';
import 'package:gymtea3/data/repositories/exercise_repository.dart';
import 'package:gymtea3/data/services/level_progress_service.dart';
import 'package:gymtea3/presentation/providers/exercise_provider.dart';
import 'package:gymtea3/presentation/screens/home/crater_map_screen.dart';
import 'package:gymtea3/presentation/widgets/crater_node.dart';
import 'package:gymtea3/presentation/widgets/crater_preview_dialog.dart';

/// Monta widgets sin depender de AuthProvider (que necesita secure storage).
Widget _wrap(ExerciseProvider provider, Widget child) {
  return ChangeNotifierProvider<ExerciseProvider>.value(
    value: provider,
    child: MaterialApp(home: child),
  );
}

/// Abre el pop-up como lo hace la app: dentro de una ruta de dialogo.
Future<void> _showDialogFor(
  WidgetTester tester,
  ExerciseProvider provider,
  RoutineModel routine,
) async {
  await tester.pumpWidget(_wrap(
    provider,
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showDialog<bool>(
          context: context,
          builder: (_) =>
              CraterPreviewDialog(routine: routine, onReshuffle: () {}),
        ),
        child: const Text('abrir'),
      ),
    ),
  ));

  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExerciseProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    provider = ExerciseProvider(
      exerciseRepository: ExerciseRepository(),
      levelProgressService: LevelProgressService(),
    );
  });

  group('Estado del mapa', () {
    test('parte con el cráter 1 abierto y la primera tanda visible', () async {
      await provider.loadMapState();

      expect(provider.levelsInRound, [1, 2, 3, 4]);
      expect(provider.firstLevelInRound, 1);
      expect(provider.highestUnlockedLevel, 1);
      expect(provider.isUnlocked(1), isTrue);
      expect(provider.isUnlocked(2), isFalse);
      expect(provider.completedLevels, isEmpty);
    });

    test('completar un cráter abre el siguiente', () async {
      await provider.loadMapState();
      await provider.completeLevel(1);

      expect(provider.isCompleted(1), isTrue);
      expect(provider.highestUnlockedLevel, 2);
      expect(provider.isUnlocked(2), isTrue);
      expect(provider.isUnlocked(3), isFalse);
    });

    test('al conquistar los 4, los cráteres se renumeran con los siguientes',
        () async {
      await provider.loadMapState();
      expect(provider.levelsInRound, [1, 2, 3, 4]);
      expect(provider.hasNextRound, isTrue);

      for (var level = 1; level <= 4; level++) {
        await provider.completeLevel(level);
      }

      // Mismo cometa, numeros nuevos: no aparece una segunda pagina.
      expect(provider.levelsInRound, [5, 6, 7, 8]);
      expect(provider.firstLevelInRound, 5);
      expect(provider.highestUnlockedLevel, 5);
      expect(provider.hasNextRound, isFalse);
    });

    test('la tanda nunca pasa del total de niveles', () async {
      await provider.loadMapState();
      for (var level = 1; level <= AppConstants.totalCraterCount; level++) {
        await provider.completeLevel(level);
      }

      expect(provider.levelsInRound.last,
          lessThanOrEqualTo(AppConstants.totalCraterCount));
      expect(provider.levelsInRound.length,
          lessThanOrEqualTo(AppConstants.initialCraterCount));
    });

    test('cada nivel de la tanda cae en un cráter distinto del sprite',
        () async {
      await provider.loadMapState();
      for (var level = 1; level <= 4; level++) {
        await provider.completeLevel(level);
      }

      final indices = provider.levelsInRound
          .map((l) => l - provider.firstLevelInRound)
          .toList();
      expect(indices, [0, 1, 2, 3]);
      for (final i in indices) {
        expect(i, lessThan(CraterSpot.all.length));
      }
    });

    test('el avance sobrevive a recrear el provider', () async {
      await provider.loadMapState();
      await provider.completeLevel(1);

      final otro = ExerciseProvider(
        exerciseRepository: ExerciseRepository(),
        levelProgressService: LevelProgressService(),
      );
      await otro.loadMapState();

      expect(otro.isCompleted(1), isTrue);
      expect(otro.highestUnlockedLevel, 2);
    });

    test('no repite ejercicios entre cráteres consecutivos', () async {
      await provider.loadMapState();

      final primera = await provider.buildRoutine(childId: 'c', level: 1);
      final idsPrimera = primera.ejercicios.map((e) => e.id).toSet();
      await provider.completeLevel(1);

      final segunda = await provider.buildRoutine(childId: 'c', level: 2);
      final idsSegunda = segunda.ejercicios.map((e) => e.id).toSet();

      expect(idsPrimera.intersection(idsSegunda), isEmpty);
    });

    test('reiniciar el avance vuelve al estado inicial', () async {
      await provider.loadMapState();
      await provider.completeLevel(1);
      await provider.resetProgress();

      expect(provider.completedLevels, isEmpty);
      expect(provider.highestUnlockedLevel, 1);
    });
  });

  group('Render', () {
    testWidgets('el mapa marca 4 cráteres: 1 disponible y 3 bloqueados',
        (tester) async {
      await tester.runAsync(provider.loadMapState);

      await tester.pumpWidget(_wrap(
        provider,
        Scaffold(
          body: Row(
            children: [
              for (final level in provider.levelsInRound)
                CraterMarker(
                  level: level,
                  status: provider.isCompleted(level)
                      ? CraterStatus.completed
                      : provider.isUnlocked(level)
                          ? CraterStatus.available
                          : CraterStatus.locked,
                  dificultad: Dificultad.forLevel(level),
                  craterSize: const Size(80, 70),
                ),
            ],
          ),
        ),
      ));
      await tester.pump();

      expect(find.byType(CraterMarker), findsNWidgets(4));
      // El disponible muestra su numero; los bloqueados, un candado.
      expect(find.text('1'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('hay una posición de cráter por cada nivel del sprite',
        (tester) async {
      expect(CraterSpot.all.length, 4);
      for (final spot in CraterSpot.all) {
        expect(spot.cx, inInclusiveRange(0.0, 1.0));
        // cy puede ser negativa: el marcador de la cima flota sobre el
        // cometa, en el espacio.
        expect(spot.cy, inInclusiveRange(-0.2, 1.0));
      }
      // La cima es el primero y es el unico que flota por encima.
      expect(CraterSpot.all.first.cy, lessThan(0));
    });

    testWidgets('el pop-up lista los ejercicios y los tiempos del nivel',
        (tester) async {
      final routine = await tester.runAsync(() async {
        await provider.loadMapState();
        return provider.buildRoutine(childId: 'c', level: 1);
      });

      await _showDialogFor(tester, provider, routine!);

      expect(find.text('Cráter 1'), findsOneWidget);
      expect(find.text('Dificultad Fácil'), findsOneWidget);
      expect(find.text('3 ejercicios'), findsOneWidget);
      expect(find.text('2 series'), findsOneWidget);
      expect(find.text('60s'), findsOneWidget);
      expect(find.text('20s descanso'), findsOneWidget);

      // El nombre puede aparecer dos veces: en la fila y, si el ejercicio
      // todavia no tiene PNG, dentro del placeholder de la imagen.
      for (final exercise in routine.ejercicios) {
        expect(find.text(exercise.nombre), findsAtLeastNWidgets(1));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('el pop-up de un cráter difícil muestra 5 ejercicios y 30s',
        (tester) async {
      final routine = await tester.runAsync(() async {
        await provider.loadMapState();
        return provider.buildRoutine(childId: 'c', level: 6);
      });

      await _showDialogFor(tester, provider, routine!);

      expect(routine.ejercicios.length, 5);
      expect(find.text('Dificultad Difícil'), findsOneWidget);
      expect(find.text('30s descanso'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Tandas', () {
    test('el total de niveles es multiplo de los crateres del sprite', () {
      expect(AppConstants.totalCraterCount % AppConstants.initialCraterCount,
          0,
          reason: 'Si no, la ultima tanda deja crateres sin nivel');
    });
  });

  group('Sprite del cometa', () {
    test('un estado distinto por cada cantidad de conquistados', () {
      final vistos = <String>{};
      for (var done = 0; done <= cratersPerComet; done++) {
        vistos.add(cometSpriteFor(done));
      }
      expect(vistos.length, cratersPerComet + 1);
    });

    test('ninguno conquistado usa el primer sprite', () {
      expect(cometSpriteFor(0), endsWith('crater_1.png'));
    });

    test('los cuatro conquistados usan el sprite con todo turquesa', () {
      expect(cometSpriteFor(cratersPerComet), endsWith('crater_5.png'));
    });

    test('no se pasa del ultimo sprite', () {
      expect(cometSpriteFor(99), cometSpriteFor(cratersPerComet));
    });
  });

  group('Assets', () {
    test('los PNG declarados en el código existen en disco', () {
      const requeridos = [
        'assets/images/craters/fondo_estrellas.png',
        'assets/images/mascota/alien.png',
        'assets/images/mascota/alien_calificacion.png',
      ];

      for (final ruta in requeridos) {
        expect(File(ruta).existsSync(), isTrue, reason: 'Falta $ruta');
      }

      // Un sprite por cada cantidad de cráteres conquistados, de 0 a 4.
      for (var done = 0; done <= cratersPerComet; done++) {
        final ruta = cometSpriteFor(done);
        expect(File(ruta).existsSync(), isTrue,
            reason: 'Falta el sprite de $done conquistados: $ruta');
      }
    });
  });
}
