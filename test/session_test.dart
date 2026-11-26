import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymtea3/core/constants/app_constants.dart';
import 'package:gymtea3/data/models/difficulty.dart';
import 'package:gymtea3/data/models/exercise_model.dart';
import 'package:gymtea3/data/models/exercise_rating.dart';
import 'package:gymtea3/data/models/routine_model.dart';
import 'package:gymtea3/data/models/session_step.dart';
import 'package:gymtea3/data/models/training_route.dart';
import 'package:gymtea3/data/repositories/exercise_repository.dart';
import 'package:gymtea3/data/repositories/progress_repository.dart';
import 'package:gymtea3/data/services/level_progress_service.dart';
import 'package:gymtea3/presentation/providers/exercise_provider.dart';
import 'package:gymtea3/presentation/providers/progress_provider.dart';
import 'package:gymtea3/presentation/screens/exercises/exercise_session_screen.dart';
import 'package:gymtea3/presentation/screens/rewards/comet_reward_screen.dart';
import 'package:gymtea3/presentation/widgets/how_did_it_go_sheet.dart';
import 'package:gymtea3/presentation/widgets/session_controls.dart';
import 'package:gymtea3/presentation/widgets/session_timer_widget.dart';

ExerciseModel _ex(String id) => ExerciseModel(
      id: id,
      nombre: 'Ejercicio $id',
      descripcion: 'Descripción $id',
      categoria: 'RD',
      dificultad: Dificultad.facil,
    );

void main() {
  group('SessionPlan', () {
    final plan = SessionPlan.build(
      exercises: [_ex('a'), _ex('b')],
      series: 2,
      restSeconds: 20,
    );

    test('serie → descanso → … sin descanso final', () {
      // a1 R a2 R b1 R b2
      expect(plan.length, 7);
      expect(plan.steps.map((s) => s.isRest).toList(),
          [false, true, false, true, false, true, false]);
      expect(plan.steps.last.isRest, isFalse);
      expect(plan[1].seconds, 20);
      expect(plan[0].seconds, AppConstants.exerciseSeconds);
    });

    test('solo las series tienen preparación', () {
      // El padre necesita tiempo para leer los pasos: al menos 4 s.
      expect(AppConstants.prepSeconds, greaterThanOrEqualTo(4));
      for (final s in plan.steps) {
        expect(s.prepSeconds, s.isRest ? 0 : AppConstants.prepSeconds);
      }
    });

    test('anterior: del descanso a la serie recién hecha', () {
      expect(plan.previousWorkIndex(1), 0);
      expect(plan.previousWorkIndex(3), 2);
    });

    test('anterior: de una serie a la serie anterior', () {
      expect(plan.previousWorkIndex(2), 0);
      expect(plan.previousWorkIndex(4), 2);
      expect(plan.previousWorkIndex(6), 4);
    });

    test('anterior: en la primera serie la reinicia', () {
      expect(plan.previousWorkIndex(0), 0);
    });

    test('detecta la última serie de cada ejercicio', () {
      final last = [
        for (var i = 0; i < plan.length; i++)
          if (plan.isLastSerieOfExercise(i)) i,
      ];
      expect(last, [2, 6]);
      expect(plan.isLast(6), isTrue);
      expect(plan.isLast(5), isFalse);
    });

    test('ejercicios completados según lo dejado atrás', () {
      expect(plan.completedExerciseIds(2), isEmpty);
      expect(plan.completedExerciseIds(3), {'a'});
      expect(plan.completedExerciseIds(plan.length), {'a', 'b'});
    });

    test('progreso de 0 a 1', () {
      expect(plan.progressAt(0), 0);
      expect(plan.progressAt(plan.length), 1);
    });
  });

  group('Momento del "¿Cómo le fue?"', () {
    test('después del descanso del ejercicio, y al final en el último', () {
      final plan = SessionPlan.build(
        exercises: [_ex('a'), _ex('b')],
        series: 2,
        restSeconds: 20,
      );
      // a1 · d · a2 · d(cierra a) · b1 · d · b2
      final asks = [
        for (var i = 0; i < plan.length; i++)
          if (plan.asksRatingAt(i)) i,
      ];
      expect(asks, [3, 6]);
      expect(plan[3].isRest, isTrue, reason: 'se pregunta tras el descanso');
      expect(plan[3].exercise.id, 'a');
      expect(plan[6].isLastSerie, isTrue);
      expect(plan.asksRatingAt(2), isFalse,
          reason: 'no al terminar la serie: viene su descanso');
    });
  });

  group('ExerciseRating', () {
    test('1 a 3 estrellas', () {
      expect(ExerciseRating.fromStars(3), ExerciseRating.excelente);
      expect(ExerciseRating.fromStars(0), isNull);
    });
  });

  group('Sesión (widget)', () {
    late ExerciseProvider exercises;
    late ProgressProvider progress;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      exercises = ExerciseProvider(
        exerciseRepository: ExerciseRepository(),
        levelProgressService: LevelProgressService(),
      );
      progress = ProgressProvider(progressRepository: ProgressRepository());
    });

    /// Monta el mapa falso con un botón que abre la sesión del cráter 1.
    ///
    /// Por defecto salta la portada "¡A entrenar juntos!" con un toque, y
    /// deja ~0.8 s de preparación corridos (como antes de la portada).
    Future<void> openSession(
      WidgetTester tester, {
      int level = 1,
      bool skipIntro = true,
      bool reduceMotion = false,
    }) async {
      await tester.runAsync(() async {
        await exercises.loadMapState();
        for (var l = 1; l < level; l++) {
          await exercises.completeLevel(l);
        }
        await exercises.buildRoutine(childId: 'c1', level: level);
      });

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: exercises),
          ChangeNotifierProvider.value(value: progress),
        ],
        child: MaterialApp(
          builder: reduceMotion
              ? (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(disableAnimations: true),
                    child: child!,
                  )
              : null,
          routes: {
            CometRewardScreen.routeName: (_) => const CometRewardScreen(),
          },
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExerciseSessionScreen(),
                  ),
                ),
                child: const Text('mapa'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('mapa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      if (skipIntro) {
        expect(find.byKey(ExerciseSessionScreen.introKey), findsOneWidget);
        await tester.tap(find.byKey(ExerciseSessionScreen.introKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
      }
    }

    double badgeScale(WidgetTester tester) => tester
        .widget<AnimatedScale>(find
            .descendant(
              of: find.byType(SessionTimerWidget),
              matching: find.byType(AnimatedScale),
            )
            .first)
        .scale;

    /// Segundos que muestra el contador de la serie (la insignia de la
    /// esquina). Se lee del timer para no confundirlo con los números de
    /// los pasos de la explicación.
    int shownSeconds(WidgetTester tester) {
      final seconds = tester
          .state<SessionTimerWidgetState>(find.byType(SessionTimerWidget))
          .remainingSeconds;
      expect(find.text('$seconds'), findsOneWidget);
      return seconds;
    }

    Future<void> tapAndPump(WidgetTester tester, Finder f) async {
      await tester.tap(f);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('prep, luego cuenta sola; pausa congela', (tester) async {
      await openSession(tester);

      expect(find.byKey(SessionControls.previousKey), findsOneWidget);
      expect(find.byKey(SessionControls.toggleKey), findsOneWidget);
      expect(find.byKey(SessionControls.nextKey), findsOneWidget);
      expect(find.text('¡Prepárate!'), findsWidgets);
      expect(find.text('Serie 1 de 2'), findsOneWidget);

      // Ya corrieron ~0.8s. Hasta casi el final de la preparación el
      // contador no corre y sigue el "¡Prepárate!".
      final prepMs = AppConstants.prepSeconds * 1000;
      await tester.pump(Duration(milliseconds: prepMs - 800 - 300));
      expect(find.text('¡Prepárate!'), findsWidgets);
      expect(find.text('${TrainingRoute.explorador.seriesSeconds - 1}'),
          findsNothing);

      // Durante la preparación: la explicación simple está a la vista y la
      // insignia del contador (esquina del recurso) sigue oculta.
      expect(find.text('Así se hace'), findsOneWidget);
      expect(badgeScale(tester), 0);

      // Termina la preparación y la serie arranca sola (~3s de serie).
      for (var i = 0; i < 7; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.text('¡Prepárate!'), findsNothing);
      expect(badgeScale(tester), 1);
      final shown = shownSeconds(tester);
      final serie = TrainingRoute.explorador.seriesSeconds;
      expect(shown, lessThan(serie));
      expect(shown, greaterThan(serie - 5));

      // Pausa: el número queda congelado.
      await tester.tap(find.byKey(SessionControls.toggleKey));
      await tester.pump();
      final frozen = '${shownSeconds(tester)}';
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(frozen), findsOneWidget);

      // Continuar: vuelve a correr.
      await tapAndPump(tester, find.byKey(SessionControls.toggleKey));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(frozen), findsNothing);
    });

    testWidgets('siguiente va al descanso y anterior vuelve a la serie',
        (tester) async {
      await openSession(tester);

      await tapAndPump(tester, find.byKey(SessionControls.nextKey));
      expect(find.text('Descanso · 20s'), findsOneWidget);
      expect(find.text('¡Prepárate!'), findsNothing);

      await tapAndPump(tester, find.byKey(SessionControls.previousKey));
      expect(find.text('Serie 1 de 2'), findsOneWidget);
      expect(find.text('¡Prepárate!'), findsWidgets);
    });

    testWidgets('pregunta "¿Cómo le fue?" por ejercicio y guarda al terminar',
        (tester) async {
      await openSession(tester);
      final routine = exercises.previewRoutine!;
      final plan = SessionPlan.fromRoutine(routine);

      for (var i = 0; i < plan.length; i++) {
        await tapAndPump(tester, find.byKey(SessionControls.nextKey));
        if (plan.asksRatingAt(i)) {
          await tester.pump(const Duration(milliseconds: 600));
          expect(find.text('¿Cómo le fue a tu hijo/a?'), findsOneWidget);
          if (i == 3) {
            // El primero (tras su descanso) se salta: no se guarda.
            await tapAndPump(tester, find.byKey(HowDidItGoSheet.skipKey));
          } else {
            await tapAndPump(tester, find.byKey(HowDidItGoSheet.starKey(3)));
            expect(find.text('¡Excelente!'), findsOneWidget);
            await tapAndPump(tester, find.byKey(HowDidItGoSheet.doneKey));
          }
          await tester.pump(const Duration(milliseconds: 400));
        }
      }

      // Guardar + completar el cráter y volver al mapa.
      await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 50),
          ));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(find.text('mapa'), findsOneWidget);
      expect(progress.progressHistory, hasLength(1));
      final saved = progress.progressHistory.single;
      final first = routine.ejercicios.first.id;
      expect(saved.calificaciones.containsKey(first), isFalse);
      for (final e in routine.ejercicios.skip(1)) {
        expect(saved.calificaciones[e.id], 3);
      }
      expect(saved.ejerciciosCompletadosIds.toSet(),
          routine.ejercicios.map((e) => e.id).toSet());
      expect(exercises.isCompleted(1), isTrue);
    });

    testWidgets('si falla el guardado no queda pegado y "siguiente" reintenta',
        (tester) async {
      exercises = _FlakyExerciseProvider(failures: 1);
      await openSession(tester);
      final plan = SessionPlan.fromRoutine(exercises.previewRoutine!);

      for (var i = 0; i < plan.length; i++) {
        await tapAndPump(tester, find.byKey(SessionControls.nextKey));
        if (plan.asksRatingAt(i)) {
          await tester.pump(const Duration(milliseconds: 600));
          await tapAndPump(tester, find.byKey(HowDidItGoSheet.skipKey));
          await tester.pump(const Duration(milliseconds: 400));
        }
      }
      await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 50),
          ));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }

      // Sigue en la sesión, con aviso y sin overlay de guardado.
      expect(find.byType(ExerciseSessionScreen), findsOneWidget);
      expect(find.textContaining('No pudimos guardar'), findsOneWidget);
      expect(exercises.isCompleted(1), isFalse);

      // Reintenta con "siguiente": ahora guarda y vuelve al mapa.
      await tapAndPump(tester, find.byKey(SessionControls.nextKey));
      await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 50),
          ));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(find.text('mapa'), findsOneWidget);
      expect(exercises.isCompleted(1), isTrue);
      // El historial no se duplica por el reintento.
      expect(progress.progressHistory, hasLength(1));
      // Deja que el SnackBar termine para no dejar timers pendientes.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('la portada "¡A entrenar juntos!" va antes de la preparación',
        (tester) async {
      await openSession(tester, skipIntro: false);

      expect(find.byKey(ExerciseSessionScreen.introKey), findsOneWidget);
      expect(find.text('¡A entrenar juntos!'), findsOneWidget);
      // Sin niño registrado se usa el genérico.
      expect(find.text('Tu hijo/a y tú contra el Cráter 1'), findsOneWidget);

      // La portada se cierra sola (~1.6 s).
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(ExerciseSessionScreen.introKey), findsNothing);

      // Recién ahora parte la preparación completa: no corrió debajo.
      final prepMs = AppConstants.prepSeconds * 1000;
      await tester.pump(Duration(milliseconds: prepMs - 1000));
      expect(find.text('¡Prepárate!'), findsWidgets);
      expect(badgeScale(tester), 0);

      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.text('¡Prepárate!'), findsNothing);
      expect(badgeScale(tester), 1);
    });

    testWidgets('un toque salta la portada y parte la preparación',
        (tester) async {
      await openSession(tester, skipIntro: false);
      expect(find.byKey(ExerciseSessionScreen.introKey), findsOneWidget);

      await tester.tap(find.byKey(ExerciseSessionScreen.introKey));
      await tester.pump();
      expect(find.byKey(ExerciseSessionScreen.introKey), findsNothing);
      expect(find.text('¡A entrenar juntos!'), findsNothing);
      expect(find.text('¡Prepárate!'), findsWidgets);

      // La preparación dura lo de siempre desde el toque.
      await tester
          .pump(Duration(milliseconds: AppConstants.prepSeconds * 1000 - 500));
      expect(badgeScale(tester), 0);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 100));
      expect(badgeScale(tester), 1);
    });

    testWidgets('con animaciones reducidas la portada es más corta',
        (tester) async {
      await openSession(tester, skipIntro: false, reduceMotion: true);
      expect(find.byKey(ExerciseSessionScreen.introKey), findsOneWidget);

      // Sin escala: solo fundido.
      final transforms = tester.widgetList<Transform>(find.descendant(
        of: find.byKey(ExerciseSessionScreen.introKey),
        matching: find.byType(Transform),
      ));
      for (final t in transforms) {
        expect(t.transform.getMaxScaleOnAxis(), closeTo(1, 1e-6));
      }

      await tester.pump(ExerciseSessionScreen.introDurationReduced);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(ExerciseSessionScreen.introKey), findsNothing);
      expect(find.text('¡Prepárate!'), findsWidgets);
      // Deja terminar la preparación para no dejar animaciones colgando.
      await tester.pump(const Duration(seconds: AppConstants.prepSeconds + 1));
    });

    testWidgets('muestra "Usa: …" y la serie dura lo de la ruta',
        (tester) async {
      final routine = RoutineModel(
        id: 'r1',
        childId: 'c1',
        nivel: 2,
        dificultad: Dificultad.facil,
        fecha: DateTime(2026),
        ruta: TrainingRoute.astronauta,
        ejercicios: [
          ExerciseModel(
            id: 'x',
            nombre: 'Pararse y sentarse',
            descripcion: 'd',
            categoria: 'RD',
            dificultad: Dificultad.facil,
            implemento: 'Banco',
            reemplazo: 'Silla firme',
          ),
        ],
      );
      exercises = _FixedRoutineProvider(routine);
      await openSession(tester);

      expect(find.textContaining('Usa: Silla firme'), findsOneWidget);
      expect(find.textContaining('(en vez de banco)'), findsOneWidget);

      final timer =
          tester.widget<SessionTimerWidget>(find.byType(SessionTimerWidget));
      expect(timer.durationSeconds, TrainingRoute.astronauta.seriesSeconds);

      // Termina la preparación y el contador parte en 45.
      for (var i = 0; i < 14; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      final shown = tester
          .state<SessionTimerWidgetState>(find.byType(SessionTimerWidget))
          .remainingSeconds;
      expect(shown, lessThan(TrainingRoute.astronauta.seriesSeconds));
      expect(shown, greaterThan(TrainingRoute.astronauta.seriesSeconds - 5));
    });

    testWidgets('sin reemplazo ni implemento no muestra "Usa:"',
        (tester) async {
      exercises = _FixedRoutineProvider(RoutineModel(
        id: 'r2',
        childId: 'c1',
        nivel: 1,
        dificultad: Dificultad.facil,
        fecha: DateTime(2026),
        ejercicios: [_ex('a')],
      ));
      await openSession(tester);
      expect(find.textContaining('Usa:'), findsNothing);
      // Rutina sin ruta (antigua): series de 60 s.
      expect(
          tester
              .widget<SessionTimerWidget>(find.byType(SessionTimerWidget))
              .durationSeconds,
          AppConstants.exerciseSeconds);
    });

    testWidgets('al conquistar el cometa abre la recompensa', (tester) async {
      await openSession(tester, level: AppConstants.cratersPerComet);
      final plan = SessionPlan.fromRoutine(exercises.previewRoutine!);

      for (var i = 0; i < plan.length; i++) {
        await tapAndPump(tester, find.byKey(SessionControls.nextKey));
        if (plan.asksRatingAt(i)) {
          await tester.pump(const Duration(milliseconds: 600));
          await tapAndPump(tester, find.byKey(HowDidItGoSheet.skipKey));
          await tester.pump(const Duration(milliseconds: 400));
        }
      }
      await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 50),
          ));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(find.byType(CometRewardScreen), findsOneWidget);
      expect(find.byType(ExerciseSessionScreen), findsNothing);
      // La recompensa recibe la ruta del padre y nombra su planeta.
      final routeArgs =
          ModalRoute.of(tester.element(find.byType(CometRewardScreen)))!
              .settings
              .arguments as CometRewardArgs;
      expect(routeArgs.route, exercises.route);
      expect(
          find.textContaining(exercises.route.cometAt(0).name), findsWidgets);
    });
  });
}

/// Provider que falla las primeras [failures] veces al completar el nivel.
class _FlakyExerciseProvider extends ExerciseProvider {
  int failures;

  _FlakyExerciseProvider({required this.failures})
      : super(
          exerciseRepository: ExerciseRepository(),
          levelProgressService: LevelProgressService(),
        );

  @override
  Future<LevelCompletion> completeLevel(
    int level, {
    int exercisesDone = 0,
    int elapsedSeconds = 0,
  }) async {
    if (failures > 0) {
      failures--;
      throw Exception('sin espacio');
    }
    return super.completeLevel(
      level,
      exercisesDone: exercisesDone,
      elapsedSeconds: elapsedSeconds,
    );
  }
}

/// Provider con una rutina fija (para probar un ejercicio concreto).
class _FixedRoutineProvider extends ExerciseProvider {
  final RoutineModel fixed;

  _FixedRoutineProvider(this.fixed)
      : super(
          exerciseRepository: ExerciseRepository(),
          levelProgressService: LevelProgressService(),
        );

  @override
  RoutineModel? get previewRoutine => fixed;
}
