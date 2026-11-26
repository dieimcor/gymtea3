import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gymtea3/core/constants/app_constants.dart';
import 'package:gymtea3/data/models/difficulty.dart';
import 'package:gymtea3/data/models/exercise_media.dart';
import 'package:gymtea3/data/models/exercise_model.dart';
import 'package:gymtea3/data/models/training_route.dart';
import 'package:gymtea3/data/repositories/exercise_repository.dart';
import 'package:gymtea3/presentation/widgets/exercise_media_slot.dart';

void main() {
  group('Dificultad', () {
    test('mapea los niveles a la dificultad esperada', () {
      expect(Dificultad.forLevel(1), Dificultad.facil);
      expect(Dificultad.forLevel(4), Dificultad.facil);
      expect(Dificultad.forLevel(5), Dificultad.medio);
      expect(Dificultad.forLevel(10), Dificultad.medio);
      expect(Dificultad.forLevel(11), Dificultad.dificil);
      expect(Dificultad.forLevel(16), Dificultad.dificil);
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

  group('Recurso visual de ejercicios', () {
    test('ningun ejercicio trae recurso todavia: todos muestran el espacio',
        () async {
      // Las graficas, GIFs y videos se estan disenando. Hasta entonces
      // todos los ejercicios deben quedar con el espacio reservado.
      final todos = await ExerciseRepository().getAll();
      expect(todos, isNotEmpty);
      for (final e in todos) {
        expect(e.media, isNull, reason: '${e.id} ya tiene un recurso asignado');
      }
    });

    test('todos traen 2 o 3 pasos simples y cortos', () async {
      final todos = await ExerciseRepository().getAll();
      for (final e in todos) {
        expect(e.pasos.length, inInclusiveRange(2, 3), reason: e.id);
        for (final paso in e.pasos) {
          expect(paso.length, lessThanOrEqualTo(55),
              reason: '${e.id}: "$paso" es largo para leerlo de corrido');
        }
      }
    });

    test('pasos viajan en JSON y sin pasos se usa la descripción', () {
      final e = ExerciseModel(
        id: 'x',
        nombre: 'X',
        descripcion: 'Descripción larga',
        categoria: 'RD',
        dificultad: Dificultad.facil,
      );
      expect(e.pasosSimples, ['Descripción larga']);
      final conPasos = ExerciseModel.fromJson({...e.toJson(), 'pasos': ['a', 'b']});
      expect(conPasos.pasosSimples, ['a', 'b']);
    });

    test('media se guarda y se lee en JSON', () {
      final e = ExerciseModel(
        id: 'rd-1',
        nombre: 'Sentadilla',
        descripcion: 'x',
        categoria: 'RD',
        dificultad: Dificultad.facil,
        media: const ExerciseMedia.video('assets/images/ejercicios/rd-1.mp4'),
      );
      final back = ExerciseModel.fromJson(e.toJson());
      expect(back.media, e.media);
      expect(ExerciseModel.fromJson({...e.toJson(), 'media': null}).media,
          isNull);
    });

    test('lee el formato anterior imagen_asset / imagen_url', () {
      final base = {
        'id': 'cd-1',
        'nombre': 'Puente',
        'descripcion': 'x',
        'categoria': 'CD',
        'dificultad': 'facil',
      };
      expect(
        ExerciseModel.fromJson({...base, 'imagen_asset': 'a/cd-1.gif'}).media,
        const ExerciseMedia.gif('a/cd-1.gif'),
      );
      expect(
        ExerciseModel.fromJson({...base, 'imagen_url': 'https://x/cd-1.png'})
            .media
            ?.esRemoto,
        isTrue,
      );
    });

    testWidgets('sin recurso, el espacio muestra el nombre y no rompe',
        (tester) async {
      final e = ExerciseModel(
        id: 'rd-1',
        nombre: 'Sentadilla con banco',
        descripcion: 'x',
        categoria: 'RD',
        dificultad: Dificultad.facil,
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Center(child: ExerciseMediaSlot(exercise: e))),
      ));
      expect(find.text('Sentadilla con banco'), findsOneWidget);
      expect(tester.getSize(find.byType(ExerciseMediaSlot)),
          const Size(220, 165));
      expect(tester.takeException(), isNull);
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

    test('en cada ruta, cada dificultad alcanza una rutina sin relleno', () {
      for (final route in TrainingRoute.values) {
        for (final d in Dificultad.values) {
          final needed = d.exerciseCount + route.extraExercises;
          expect(
            repo.poolFor(d, route: route).length,
            greaterThanOrEqualTo(needed),
            reason: 'Ruta ${route.name}, pool ${d.name}: no alcanza $needed',
          );
        }
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
