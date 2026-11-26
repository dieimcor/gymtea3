import 'package:gymtea3/core/constants/app_constants.dart';
import 'package:gymtea3/data/models/exercise_model.dart';
import 'package:gymtea3/data/models/routine_model.dart';

/// Un paso de la sesión: una serie de trabajo de un ejercicio o un descanso.
class SessionStep {
  final ExerciseModel exercise;

  /// Posición (0-based) del ejercicio dentro de la rutina.
  final int exerciseIndex;

  /// Número de serie (1-based) a la que pertenece el paso. En un descanso
  /// es la serie que se acaba de hacer.
  final int serie;

  /// Series totales del ejercicio.
  final int totalSeries;

  final bool isRest;
  final int seconds;

  const SessionStep({
    required this.exercise,
    required this.exerciseIndex,
    required this.serie,
    required this.totalSeries,
    required this.isRest,
    required this.seconds,
  });

  /// `true` si es la última serie de trabajo de su ejercicio.
  bool get isLastSerie => !isRest && serie == totalSeries;

  /// `true` si es el descanso que sigue a la última serie de su ejercicio:
  /// al terminarlo se pregunta "¿Cómo le fue?", antes de que arranque el
  /// ejercicio siguiente.
  bool get closesExercise => isRest && serie == totalSeries;

  /// Segundos de preparación antes de arrancar: solo las series, nunca los
  /// descansos.
  int get prepSeconds => isRest ? 0 : AppConstants.prepSeconds;
}

/// Secuencia plana de pasos de un cráter y la lógica para moverse en ella
/// (anterior / siguiente). Sin dependencias de UI para poder testearla.
class SessionPlan {
  final List<SessionStep> steps;

  const SessionPlan(this.steps);

  /// Arma serie → descanso → serie → … sin descanso final.
  factory SessionPlan.fromRoutine(RoutineModel routine) => SessionPlan.build(
        exercises: routine.ejercicios,
        series: routine.series,
        restSeconds: routine.restSeconds,
        exerciseSeconds: routine.exerciseSeconds,
      );

  factory SessionPlan.build({
    required List<ExerciseModel> exercises,
    required int series,
    required int restSeconds,
    int exerciseSeconds = AppConstants.exerciseSeconds,
  }) {
    final steps = <SessionStep>[];
    for (var e = 0; e < exercises.length; e++) {
      for (var serie = 1; serie <= series; serie++) {
        steps.add(SessionStep(
          exercise: exercises[e],
          exerciseIndex: e,
          serie: serie,
          totalSeries: series,
          isRest: false,
          seconds: exerciseSeconds,
        ));
        steps.add(SessionStep(
          exercise: exercises[e],
          exerciseIndex: e,
          serie: serie,
          totalSeries: series,
          isRest: true,
          seconds: restSeconds,
        ));
      }
    }
    // El último descanso sobra.
    if (steps.isNotEmpty && steps.last.isRest) steps.removeLast();
    return SessionPlan(List.unmodifiable(steps));
  }

  int get length => steps.length;
  bool get isEmpty => steps.isEmpty;
  SessionStep operator [](int i) => steps[i];

  bool isLast(int index) => index >= steps.length - 1;

  /// Paso al que lleva "anterior" desde [index]:
  /// - desde un descanso, a la serie recién hecha;
  /// - desde una serie, a la serie de trabajo anterior;
  /// - en la primera serie, la misma (se reinicia).
  int previousWorkIndex(int index) {
    if (steps.isEmpty) return 0;
    final from = index.clamp(0, steps.length - 1);
    final start = steps[from].isRest ? from : from - 1;
    for (var i = start; i >= 0; i--) {
      if (!steps[i].isRest) return i;
    }
    return from;
  }

  /// `true` si el paso [index] es la última serie de su ejercicio.
  bool isLastSerieOfExercise(int index) =>
      index >= 0 && index < steps.length && steps[index].isLastSerie;

  /// `true` si al salir del paso [index] se pregunta "¿Cómo le fue?":
  /// - al terminar el descanso que sigue a la última serie de un ejercicio
  ///   (así no interrumpe el ejercicio siguiente ya empezado);
  /// - en el último ejercicio, que no tiene descanso después, al terminar
  ///   su última serie.
  bool asksRatingAt(int index) {
    if (index < 0 || index >= steps.length) return false;
    final step = steps[index];
    return step.closesExercise || (step.isLastSerie && isLast(index));
  }

  /// Ejercicios cuya última serie quedó atrás.
  ///
  /// [upTo] es el índice del primer paso que todavía NO cuenta; al terminar
  /// la rutina se pasa `length` para incluir el último paso.
  Set<String> completedExerciseIds(int upTo) {
    final done = <String>{};
    for (var i = 0; i < upTo && i < steps.length; i++) {
      if (steps[i].isLastSerie) done.add(steps[i].exercise.id);
    }
    return done;
  }

  /// Avance de 0 a 1 según los pasos ya dejados atrás.
  double progressAt(int index) =>
      steps.isEmpty ? 0 : (index / steps.length).clamp(0, 1).toDouble();
}
