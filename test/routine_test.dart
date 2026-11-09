import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:gymtea3/core/constants/app_constants.dart';
import 'package:gymtea3/data/models/difficulty.dart';
import 'package:gymtea3/data/repositories/exercise_repository.dart';

void main() {
  group('Dificultad', () {
    test('mapea los niveles a la dificultad esperada', () {
      expect(Dificultad.forLevel(1), Dificultad.facil);
      expect(Dificultad.forLevel(2), Dificultad.facil);
      expect(Dificultad.forLevel(3), Dificultad.medio);
      expect(Dificultad.forLevel(5), Dificultad.medio);
      expect(Dificultad.forLevel(6), Dificultad.dificil);
      expect(Dificultad.forLevel(7), Dificultad.dificil);
    });

    test('3/4/5 ejercicios y siempre 2 series', () {
      expect(Dificultad.facil.exerciseCount, 3);
      expect(Dificultad.medio.exerciseCount, 4);
      expect(Dificultad.dificil.exerciseCount, 5);

      for (final d in Dificultad.values) {
        expect(d.series, 2);
      }
    });

    test('los descansos son incrementales desde 20s', () {
      expect(Dificultad.facil.restSeconds, 20);
      expect(Dificultad.medio.restSeconds, 25);
      expect(Dificultad.dificil.restSeconds, 30);
      expect(AppConstants.exerciseSeconds, 60);
    });
  });

  group('ExerciseRepository.pickRandom', () {
    late ExerciseRepository repo;

    setUp(() => repo = ExerciseRepository(random: Random(42)));

    test('devuelve la cantidad pedida sin repetir dentro de la rutina',
        () async {
      for (final d in Dificultad.values) {
        final picked = await repo.pickRandom(
          dificultad: d,
          count: d.exerciseCount,
        );
        expect(picked.length, d.exerciseCount);
        expect(picked.map((e) => e.id).toSet().length, d.exerciseCount);
        expect(picked.every((e) => e.dificultad == d), isTrue);
      }
    });

    test('respeta los ids excluidos mientras alcance el pool', () async {
      final first = await repo.pickRandom(
        dificultad: Dificultad.facil,
        count: 3,
      );
      final usedIds = first.map((e) => e.id).toSet();

      final second = await repo.pickRandom(
        dificultad: Dificultad.facil,
        count: 3,
        excludeIds: usedIds,
      );

      expect(second.any((e) => usedIds.contains(e.id)), isFalse);
    });

    test('cada pool alcanza para todos sus cráteres sin repetir', () async {
      for (final d in Dificultad.values) {
        final craters = List.generate(AppConstants.totalCraterCount, (i) => i + 1)
            .where((level) => Dificultad.forLevel(level) == d)
            .length;

        expect(
          await repo.poolSize(d),
          greaterThanOrEqualTo(craters * d.exerciseCount),
          reason: 'El pool ${d.name} no alcanza para sus $craters cráteres',
        );
      }
    });

    test('completa la rutina aunque el pool esté agotado', () async {
      final pool = await repo.getPool(Dificultad.facil);
      final allIds = pool.map((e) => e.id).toSet();

      final picked = await repo.pickRandom(
        dificultad: Dificultad.facil,
        count: 3,
        excludeIds: allIds,
      );

      expect(picked.length, 3);
    });
  });
}
