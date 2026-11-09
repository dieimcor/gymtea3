import 'package:gymtea3/core/constants/app_constants.dart';

/// Dificultad de un cráter (nivel).
///
/// Define cuántos ejercicios trae la rutina y cuánto se descansa.
/// El descanso es **incremental**: a mayor dificultad, más recuperación.
enum Dificultad {
  facil,
  medio,
  dificil;

  /// Cantidad de ejercicios distintos que trae la rutina.
  int get exerciseCount {
    switch (this) {
      case Dificultad.facil:
        return 3;
      case Dificultad.medio:
        return 4;
      case Dificultad.dificil:
        return 5;
    }
  }

  /// Series por ejercicio — 2 en todas las dificultades.
  int get series => AppConstants.seriesPerExercise;

  /// Segundos de descanso entre series y entre ejercicios.
  int get restSeconds {
    switch (this) {
      case Dificultad.facil:
        return AppConstants.baseRestSeconds; // 20s
      case Dificultad.medio:
        return AppConstants.baseRestSeconds + 5; // 25s
      case Dificultad.dificil:
        return AppConstants.baseRestSeconds + 10; // 30s
    }
  }

  String get label {
    switch (this) {
      case Dificultad.facil:
        return 'Fácil';
      case Dificultad.medio:
        return 'Medio';
      case Dificultad.dificil:
        return 'Difícil';
    }
  }

  /// Duración estimada de la rutina en segundos
  /// (N ejercicios × 2 series × 60s + descansos intermedios).
  int get estimatedSeconds {
    final blocks = exerciseCount * series;
    final work = blocks * AppConstants.exerciseSeconds;
    final rests = (blocks - 1) * restSeconds;
    return work + rests;
  }

  /// Dificultad asignada a un nivel/cráter.
  /// Niveles 1-2 → fácil · 3-5 → medio · 6+ → difícil.
  static Dificultad forLevel(int level) {
    if (level <= 2) return Dificultad.facil;
    if (level <= 5) return Dificultad.medio;
    return Dificultad.dificil;
  }

  static Dificultad fromName(String? name) {
    return Dificultad.values.firstWhere(
      (d) => d.name == name,
      orElse: () => Dificultad.facil,
    );
  }
}
