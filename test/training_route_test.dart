import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymtea3/core/theme/comet_theme.dart';
import 'package:gymtea3/data/models/difficulty.dart';
import 'package:gymtea3/data/models/equipment.dart';
import 'package:gymtea3/data/models/training_route.dart';
import 'package:gymtea3/data/repositories/exercise_repository.dart';
import 'package:gymtea3/data/services/level_progress_service.dart';
import 'package:gymtea3/presentation/providers/exercise_provider.dart';

void main() {
  group('TrainingRoute', () {
    test('series de 30 / 45 / 60 s y solo Comandante suma un ejercicio', () {
      expect(TrainingRoute.explorador.seriesSeconds, 30);
      expect(TrainingRoute.astronauta.seriesSeconds, 45);
      expect(TrainingRoute.comandante.seriesSeconds, 60);
      expect(TrainingRoute.explorador.extraExercises, 0);
      expect(TrainingRoute.astronauta.extraExercises, 0);
      expect(TrainingRoute.comandante.extraExercises, 1);
    });

    test('cada ruta tiene planetas propios, sin compartirlos', () {
      final all = <CometTheme>[];
      for (final r in TrainingRoute.values) {
        expect(r.comets.length, greaterThanOrEqualTo(2));
        all.addAll(r.comets);
      }
      expect(all.map((c) => c.name).toSet().length, all.length);
    });

    test('el equipo permitido crece con la ruta', () {
      expect(Equipo.especial.fitsIn(TrainingRoute.explorador.maxEquipo),
          isFalse);
      expect(
          Equipo.basico.fitsIn(TrainingRoute.explorador.maxEquipo), isFalse);
      expect(Equipo.basico.fitsIn(TrainingRoute.astronauta.maxEquipo), isTrue);
      expect(
          Equipo.especial.fitsIn(TrainingRoute.comandante.maxEquipo), isTrue);
    });
  });

  group('Catálogo por ruta', () {
    final repo = ExerciseRepository();

    test('Explorador nunca pide equipo; Astronauta nunca equipo especial', () {
      for (final d in Dificultad.values) {
        expect(
          repo
              .poolFor(d, route: TrainingRoute.explorador)
              .every((e) => e.equipo == Equipo.libre),
          isTrue,
        );
        expect(
          repo
              .poolFor(d, route: TrainingRoute.astronauta)
              .every((e) => e.equipo != Equipo.especial),
          isTrue,
        );
      }
    });

    test('todo ejercicio con equipo trae un reemplazo de casa', () async {
      for (final e in await repo.getAll()) {
        if (e.equipo != Equipo.libre || e.implemento != null) {
          expect(e.reemplazo, isNotNull, reason: e.id);
          expect(e.reemplazo!.length, lessThanOrEqualTo(55), reason: e.id);
        }
      }
    });

    test('si una ruta queda corta, completa con dificultades vecinas', () {
      final pool =
          repo.poolFor(Dificultad.dificil, route: TrainingRoute.explorador,
              minSize: 12);
      expect(pool.length, 12);
      expect(pool.map((e) => e.id).toSet().length, 12, reason: 'sin repetir');
      expect(pool.every((e) => e.equipo == Equipo.libre), isTrue);
    });
  });

  group('Provider con rutas', () {
    late ExerciseProvider provider;

    ExerciseProvider build() => ExerciseProvider(
          exerciseRepository: ExerciseRepository(),
          levelProgressService: LevelProgressService(),
        );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = build();
    });

    test('sin ruta guardada pide elegir; al elegir queda guardada', () async {
      await provider.loadMapState();
      expect(provider.hasSelectedRoute, isFalse);

      await provider.selectRoute(TrainingRoute.astronauta);
      final again = build();
      await again.loadMapState();
      expect(again.hasSelectedRoute, isTrue);
      expect(again.route, TrainingRoute.astronauta);
    });

    test('la rutina usa las series y la cantidad de la ruta', () async {
      await provider.selectRoute(TrainingRoute.explorador);
      var r = await provider.buildRoutine(childId: 'c', level: 1);
      expect(r.exerciseSeconds, 30);
      expect(r.ejercicios.length, 3);

      await provider.selectRoute(TrainingRoute.comandante);
      r = await provider.buildRoutine(childId: 'c', level: 1);
      expect(r.exerciseSeconds, 60);
      expect(r.ejercicios.length, 4);
      r = await provider.buildRoutine(childId: 'c', level: 12);
      expect(r.ejercicios.length, 6);
    });

    test('cada ruta guarda su propio avance', () async {
      await provider.selectRoute(TrainingRoute.explorador);
      await provider.completeLevel(1);
      await provider.completeLevel(2);
      expect(provider.completedLevels, {1, 2});

      await provider.selectRoute(TrainingRoute.comandante);
      expect(provider.completedLevels, isEmpty);
      expect(provider.highestUnlockedLevel, 1);

      await provider.selectRoute(TrainingRoute.explorador);
      expect(provider.completedLevels, {1, 2});
    });

    test('el cometa del mapa es el de la ruta', () async {
      await provider.selectRoute(TrainingRoute.astronauta);
      expect(provider.cometTheme(0), CometTheme.lavanda);
      expect(provider.cometTheme(1), CometTheme.frutilla);
    });
  });
}
