import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymtea3/core/constants/app_constants.dart';
import 'package:gymtea3/data/models/difficulty.dart';
import 'package:gymtea3/data/models/exercise_model.dart';
import 'package:gymtea3/data/models/routine_model.dart';
import 'package:gymtea3/data/models/training_route.dart';
import 'package:gymtea3/data/repositories/auth_repository.dart';
import 'package:gymtea3/data/repositories/exercise_repository.dart';
import 'package:gymtea3/data/services/auth_service.dart';
import 'package:gymtea3/data/services/level_progress_service.dart';
import 'package:gymtea3/data/services/storage_service.dart';
import 'package:gymtea3/presentation/animations/comet_travel.dart';
import 'package:gymtea3/presentation/animations/comet_turn.dart';
import 'package:gymtea3/presentation/providers/auth_provider.dart';
import 'package:gymtea3/presentation/providers/exercise_provider.dart';
import 'package:gymtea3/presentation/screens/home/crater_map_screen.dart';
import 'package:gymtea3/presentation/widgets/crater_node.dart';
import 'package:gymtea3/presentation/widgets/crater_preview_dialog.dart';
import 'package:gymtea3/presentation/widgets/equipment_chip.dart';
import 'package:gymtea3/presentation/widgets/progress_panel.dart';

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

      // Mismo cometa, su otra cara: números nuevos sobre el mismo sprite.
      expect(provider.levelsInRound, [5, 6, 7, 8]);
      expect(provider.firstLevelInRound, 5);
      expect(provider.highestUnlockedLevel, 5);
      expect(provider.cometIndex, 0);
      expect(provider.faceInComet, 1);
      expect(provider.isLastFaceOfComet, isTrue);
      expect(provider.hasNextRound, isTrue);
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
      // La serie dura lo de la ruta (Explorador: 30 s), no 60 fijos.
      expect(routine.ruta, TrainingRoute.explorador);
      expect(find.text('${routine.exerciseSeconds}s'), findsOneWidget);
      expect(find.text('20s descanso'), findsOneWidget);
      expect(find.text('Explorador'), findsOneWidget);

      // "Para este cráter necesitan": lo que hay que tener a mano.
      expect(find.byKey(CraterPreviewDialog.gearKey), findsOneWidget);
      expect(find.text('Para este cráter necesitan'), findsOneWidget);
      final gear = {
        for (final e in routine.ejercicios)
          if (e.queUsar != null) EquipmentIcons.shortLabel(e.queUsar!),
      };
      if (gear.isEmpty) {
        expect(find.text(CraterPreviewDialog.noGearText), findsOneWidget);
      } else {
        for (final g in gear) {
          expect(
            find.descendant(
              of: find.byKey(CraterPreviewDialog.gearKey),
              matching: find.text(g),
            ),
            findsOneWidget,
          );
        }
      }

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
        return provider.buildRoutine(childId: 'c', level: 12);
      });

      await _showDialogFor(tester, provider, routine!);

      expect(routine.ejercicios.length, 5);
      expect(find.text('Dificultad Difícil'), findsOneWidget);
      expect(find.text('30s descanso'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('el pop-up junta lo que necesitan sin repetir',
        (tester) async {
      ExerciseModel ex(String id, {String? implemento, String? reemplazo}) =>
          ExerciseModel(
            id: id,
            nombre: 'Ejercicio $id',
            descripcion: 'd',
            categoria: 'RD',
            dificultad: Dificultad.facil,
            implemento: implemento,
            reemplazo: reemplazo,
          );
      RoutineModel routineOf(List<ExerciseModel> list) => RoutineModel(
            id: 'r',
            childId: 'c',
            nivel: 2,
            dificultad: Dificultad.facil,
            fecha: DateTime(2026),
            ruta: TrainingRoute.astronauta,
            ejercicios: list,
          );

      await _showDialogFor(
        tester,
        provider,
        routineOf([
          ex('a', implemento: 'Banco', reemplazo: 'Silla firme'),
          ex('b', implemento: 'Banco', reemplazo: 'Silla firme'),
          ex('c',
              implemento: 'Elástico',
              reemplazo: 'Toalla: tú tiras del otro extremo'),
          ex('d'),
        ]),
      );
      final inGear = find.byKey(CraterPreviewDialog.gearKey);
      expect(find.descendant(of: inGear, matching: find.text('Silla firme')),
          findsOneWidget);
      expect(find.descendant(of: inGear, matching: find.text('Toalla')),
          findsOneWidget);
      expect(find.text(CraterPreviewDialog.noGearText), findsNothing);
      expect(find.text('45s'), findsOneWidget);
      expect(find.text('Astronauta'), findsOneWidget);
      expect(EquipmentIcons.forText('Sofá o silla firme'),
          Icons.weekend_rounded);

      Navigator.of(tester.element(inGear)).pop();
      await tester.pumpAndSettle();

      await _showDialogFor(tester, provider, routineOf([ex('a'), ex('b')]));
      expect(find.text(CraterPreviewDialog.noGearText), findsOneWidget);
    });
  });

  group('Tandas', () {
    test('el total de niveles es multiplo de los crateres del sprite', () {
      expect(AppConstants.totalCraterCount % AppConstants.initialCraterCount, 0,
          reason: 'Si no, la ultima tanda deja crateres sin nivel');
    });
  });

  group('Sprite del cometa', () {
    test('un estado distinto por cada cantidad de conquistados', () {
      final vistos = <String>{};
      for (var done = 0; done <= cratersPerSprite; done++) {
        vistos.add(cometSpriteFor(done));
      }
      expect(vistos.length, cratersPerSprite + 1);
    });

    test('ninguno conquistado usa el primer sprite', () {
      expect(cometSpriteFor(0), endsWith('crater_1.png'));
    });

    test('los cuatro conquistados usan el sprite con todo turquesa', () {
      expect(cometSpriteFor(cratersPerSprite), endsWith('crater_5.png'));
    });

    test('no se pasa del ultimo sprite', () {
      expect(cometSpriteFor(99), cometSpriteFor(cratersPerSprite));
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
      for (var done = 0; done <= cratersPerSprite; done++) {
        final ruta = cometSpriteFor(done);
        expect(File(ruta).existsSync(), isTrue,
            reason: 'Falta el sprite de $done conquistados: $ruta');
      }
    });
  });

  group('Conquista de cometas (LevelCompletion)', () {
    test('completar los cráteres 1 a 3 no completa el cometa', () async {
      await provider.loadMapState();
      for (var level = 1; level <= 3; level++) {
        final result = await provider.completeLevel(level);
        expect(result.level, level);
        expect(result.cometIndex, 0);
        expect(result.cometCompleted, isFalse, reason: 'cráter $level');
        expect(result.journeyCompleted, isFalse);
      }
    });

    test('el cráter 4 solo termina la primera cara, no el cometa', () async {
      await provider.loadMapState();
      LevelCompletion? result;
      for (var level = 1; level <= 4; level++) {
        result = await provider.completeLevel(level);
      }
      expect(result!.cometIndex, 0);
      expect(result.cometCompleted, isFalse);
    });

    test('el cráter 8 completa el primer cometa', () async {
      await provider.loadMapState();
      for (var level = 1; level <= 7; level++) {
        await provider.completeLevel(level);
      }
      final result = await provider.completeLevel(8);

      expect(result.cometIndex, 0);
      expect(result.cometCompleted, isTrue);
      expect(result.journeyCompleted, isFalse);
    });

    test('rejugar el cráter 8 no vuelve a dar la recompensa', () async {
      await provider.loadMapState();
      for (var level = 1; level <= 8; level++) {
        await provider.completeLevel(level);
      }
      final again = await provider.completeLevel(8);

      expect(again.cometCompleted, isFalse);
      expect(again.journeyCompleted, isFalse);
    });

    test('el cráter 16 completa el último cometa y el viaje', () async {
      await provider.loadMapState();
      LevelCompletion? last;
      for (var level = 1; level <= AppConstants.totalCraterCount; level++) {
        last = await provider.completeLevel(level);
      }

      expect(last!.level, AppConstants.totalCraterCount);
      expect(last.cometIndex, provider.totalComets - 1);
      expect(last.cometCompleted, isTrue);
      expect(last.journeyCompleted, isTrue);
    });

    test('cometIndexOf y levelsOfComet agrupan de a 8 (dos caras)', () {
      expect(ExerciseProvider.cometIndexOf(1), 0);
      expect(ExerciseProvider.cometIndexOf(8), 0);
      expect(ExerciseProvider.cometIndexOf(9), 1);
      expect(ExerciseProvider.cometIndexOf(16), 1);
      expect(provider.levelsOfComet(0), [1, 2, 3, 4, 5, 6, 7, 8]);
      expect(provider.levelsOfComet(1), [9, 10, 11, 12, 13, 14, 15, 16]);
      expect(provider.totalComets, 2);
    });
  });

  group('roundIndex', () {
    test('parte en 0 y sube al conquistar el primer cometa', () async {
      await provider.loadMapState();
      expect(provider.roundIndex, 0);

      for (var level = 1; level <= 3; level++) {
        await provider.completeLevel(level);
        expect(provider.roundIndex, 0, reason: 'tras el cráter $level');
      }

      await provider.completeLevel(4);
      expect(provider.roundIndex, 1);
      expect(provider.cometIndex, 0, reason: 'la otra cara, mismo cometa');

      for (var level = 5; level <= 8; level++) {
        await provider.completeLevel(level);
      }
      expect(provider.roundIndex, 2);
      expect(provider.cometIndex, 1);
    });

    test('al terminar todo no se pasa del último cometa', () async {
      await provider.loadMapState();
      for (var level = 1; level <= AppConstants.totalCraterCount; level++) {
        await provider.completeLevel(level);
      }
      expect(provider.cometIndex, provider.totalComets - 1);
      expect(provider.roundIndex,
          AppConstants.totalCraterCount ~/ AppConstants.initialCraterCount - 1);
    });
  });

  group('Animaciones del mapa', () {
    testWidgets('el panel cuenta desde 0 y luego desde el valor previo',
        (tester) async {
      Widget panel(int completed, int exercises) => MaterialApp(
            home: Scaffold(
              body: ProgressPanel(
                completed: completed,
                total: 8,
                stats: TrainingStats(
                  exercises: exercises,
                  seconds: 600,
                  sessions: completed,
                ),
                cometName: 'Cometa Limón',
                cometNumber: 1,
                totalComets: 2,
              ),
            ),
          );

      await tester.pumpWidget(panel(2, 6));
      // Recién montado todavía va contando desde 0.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('6'), findsNothing);

      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text('2'), findsWidgets, reason: 'cráteres');
      expect(find.text('6'), findsOneWidget, reason: 'ejercicios');
      expect(find.text('10 min'), findsOneWidget);
      expect(find.textContaining('Cometa Limón'), findsOneWidget);

      // Sube a 4 cráteres y 9 ejercicios: cuenta desde lo anterior y
      // muestra el "+3" de la caja de ejercicios.
      await tester.pumpWidget(panel(4, 9));
      // El conteo arranca tras su espera (cascada): un frame para iniciar
      // y otro para avanzar.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('+3'), findsOneWidget);
      final mid = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => int.tryParse(t.data ?? ''))
          .whereType<int>()
          .where((v) => v >= 6 && v <= 9);
      expect(mid, isNotEmpty, reason: 'no vuelve a contar desde 0');

      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text('4'), findsWidgets, reason: 'cráteres');
      expect(find.text('9'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('el cráter recién conquistado hace pop con destellos',
        (tester) async {
      Widget marker(CraterStatus status) => MaterialApp(
            home: Scaffold(
              body: Center(
                child: CraterMarker(
                  level: 2,
                  status: status,
                  dificultad: Dificultad.forLevel(2),
                  craterSize: const Size(80, 70),
                ),
              ),
            ),
          );

      await tester.pumpWidget(marker(CraterStatus.available));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('2'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNothing);

      await tester.pumpWidget(marker(CraterStatus.completed));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(6));

      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('el bloqueado tiembla al tocarlo y no abre nada',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: CraterMarker(
              level: 3,
              status: CraterStatus.locked,
              dificultad: Dificultad.forLevel(3),
              craterSize: const Size(80, 70),
              onTap: () => taps++,
            ),
          ),
        ),
      ));

      await tester.tap(find.byType(CraterMarker));
      await tester.pump(const Duration(milliseconds: 500));
      expect(taps, 0);
      expect(tester.takeException(), isNull);
    });
  });

  group('Mapa completo', () {
    Widget mapApp(ExerciseProvider p) => MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(
                authRepository: AuthRepository(
                  authService: AuthService(),
                  storageService: StorageService(),
                ),
              ),
            ),
            ChangeNotifierProvider<ExerciseProvider>.value(value: p),
          ],
          child: const MaterialApp(home: CraterMapScreen()),
        );

    Future<void> completeUpTo(int last) async {
      await provider.loadMapState();
      for (var level = 1; level <= last; level++) {
        await provider.completeLevel(level);
      }
    }

    /// Monta el mapa y deja que termine la primera carga.
    Future<void> mountMap(WidgetTester tester) async {
      await tester.pumpWidget(mapApp(provider));
      await tester.pump();
      // La carga usa SharedPreferences: se deja correr con tiempo real.
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
    }

    testWidgets('carga el mapa con su cometa y sin viaje', (tester) async {
      await tester.runAsync(() => completeUpTo(1));
      await mountMap(tester);

      expect(find.byType(ProgressPanel), findsOneWidget);
      expect(find.byType(CraterMarker), findsNWidgets(4));
      expect(find.textContaining('Cometa Limón'), findsOneWidget);
      expect(find.byType(CometTravel), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('el marciano va en la capa de arriba, sobre el panel',
        (tester) async {
      await tester.runAsync(() => completeUpTo(1));
      await mountMap(tester);

      final alien = find.byKey(const ValueKey('map-alien'));
      expect(alien, findsOneWidget);
      // Sigue a su ancla en el cometa, pero no vive dentro del recorte.
      expect(
          find.ancestor(
              of: alien, matching: find.byType(CompositedTransformFollower)),
          findsOneWidget);
      expect(find.ancestor(of: alien, matching: find.byType(ClipRect)),
          findsNothing);
      expect(find.ancestor(of: alien, matching: find.byType(IgnorePointer)),
          findsWidgets);
      // Se dibuja después (encima) del panel de progreso.
      final order = tester.allElements.map((e) => e.widget).toList();
      expect(order.indexWhere((w) => w.key == const ValueKey('map-alien')),
          greaterThan(order.indexWhere((w) => w is ProgressPanel)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('en la primera carga no hay viaje aunque sea otro cometa',
        (tester) async {
      await tester.runAsync(() => completeUpTo(8));
      await mountMap(tester);

      expect(find.byType(CometTravel), findsNothing);
      expect(find.byType(CometTurn), findsNothing);
      expect(find.textContaining(provider.cometTheme(1).name), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('en 360x640 los 4 cráteres quedan dentro de la pantalla',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.runAsync(() => completeUpTo(0));
      await mountMap(tester);

      const screen = Rect.fromLTWH(0, 0, 360, 640);
      for (var i = 0; i < cratersPerSprite; i++) {
        final rect = tester.getRect(find.byKey(ValueKey('crater-spot-$i')));
        expect(rect.top, greaterThanOrEqualTo(screen.top), reason: 'cráter $i');
        expect(rect.bottom, lessThanOrEqualTo(screen.bottom),
            reason: 'cráter $i');
        expect(rect.left, greaterThanOrEqualTo(screen.left),
            reason: 'cráter $i');
        expect(rect.right, lessThanOrEqualTo(screen.right),
            reason: 'cráter $i');
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('al volver al mapa no abre cráteres mientras se sincroniza',
        (tester) async {
      await tester.runAsync(() => completeUpTo(1));
      await mountMap(tester);

      // Cambia el provider (como al volver de una sesión) y, antes de que
      // se copie el estado nuevo, el mapa ignora los toques.
      await tester.runAsync(() => provider.completeLevel(2));
      await tester.pump();

      final absorbers = tester.widgetList<AbsorbPointer>(find.descendant(
        of: find.byType(CraterMapScreen),
        matching: find.byType(AbsorbPointer),
      ));
      expect(absorbers.any((a) => a.absorbing), isTrue);

      await tester.pump(mapSyncDelay);
      await tester.pump(const Duration(milliseconds: 1500));
      final after = tester.widgetList<AbsorbPointer>(find.descendant(
        of: find.byType(CraterMapScreen),
        matching: find.byType(AbsorbPointer),
      ));
      expect(after.any((a) => a.absorbing), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('al terminar la primera cara el cometa da la vuelta',
        (tester) async {
      await tester.runAsync(() => completeUpTo(3));
      await mountMap(tester);

      await tester.runAsync(() => provider.completeLevel(4));
      await tester.pump();
      await tester.pump(mapSyncDelay);
      await tester.pump(const Duration(milliseconds: 800));

      // Vuelta (con el cometa completo), no viaje: sigue el mismo cometa.
      expect(find.byType(CometTurn), findsOneWidget);
      expect(find.byType(CometTravel), findsNothing);
      expect(find.text(CometTurn.message), findsOneWidget);
      final absorbers = tester.widgetList<AbsorbPointer>(find.descendant(
        of: find.byType(CraterMapScreen),
        matching: find.byType(AbsorbPointer),
      ));
      expect(absorbers.any((a) => a.absorbing), isTrue);

      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byType(CometTurn), findsNothing);
      expect(find.textContaining(provider.cometTheme(0).name), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('al conquistar el cometa viaja al siguiente y bloquea toques',
        (tester) async {
      await tester.runAsync(() => completeUpTo(7));
      await mountMap(tester);
      expect(find.byType(CometTravel), findsNothing);

      await tester.runAsync(() => provider.completeLevel(8));
      await tester.pump();
      await tester.pump(mapSyncDelay);
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.byType(CometTravel), findsOneWidget);
      expect(find.text('¡Rumbo al ${provider.cometTheme(1).name}!'),
          findsOneWidget);
      // Mientras viaja el panel sigue mostrando el cometa anterior.
      expect(find.textContaining('Cometa Limón'), findsOneWidget);

      // Los toques al mapa no pasan durante el viaje.
      final absorbers = tester.widgetList<AbsorbPointer>(find.descendant(
        of: find.byType(CraterMapScreen),
        matching: find.byType(AbsorbPointer),
      ));
      expect(absorbers.any((a) => a.absorbing), isTrue);

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byType(CometTravel), findsNothing);
      expect(find.textContaining(provider.cometTheme(1).name), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
