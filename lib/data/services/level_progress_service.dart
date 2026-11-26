import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymtea3/core/constants/app_constants.dart';
import 'package:gymtea3/data/models/training_route.dart';

/// Persiste el avance del mapa de cráteres.
///
/// El avance y el registro de ejercicios sorteados se guardan **por ruta**
/// ([route]): cambiar de ruta no borra lo hecho en las otras. Los
/// acumulados de entrenamiento (ejercicios, tiempo, sesiones) son del
/// niño, así que son globales.
///
/// Es deliberadamente independiente de la evaluación funcional y del
/// perfilamiento del niño: el desbloqueo depende solo de los cráteres
/// que ya se completaron en este dispositivo.
class LevelProgressService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Ruta cuyo avance se lee y escribe.
  TrainingRoute route = TrainingRoute.explorador;

  String get _completedKey =>
      '${AppConstants.completedLevelsKey}_${route.name}';
  String get _usedKey => '${AppConstants.usedExerciseIdsKey}_${route.name}';

  // ------------------------------------------------------------
  // Ruta elegida
  // ------------------------------------------------------------

  /// Ruta elegida por el padre (`null` si todavía no elige).
  Future<TrainingRoute?> getSelectedRoute() async {
    final store = await _store;
    return TrainingRoute.fromName(store.getString(AppConstants.trainingRouteKey));
  }

  Future<void> saveSelectedRoute(TrainingRoute value) async {
    final store = await _store;
    await store.setString(AppConstants.trainingRouteKey, value.name);
    route = value;
  }

  // ------------------------------------------------------------
  // Niveles completados
  // ------------------------------------------------------------

  /// Niveles (cráteres) completados al menos una vez.
  Future<Set<int>> getCompletedLevels() async {
    final store = await _store;
    final raw = store.getStringList(_completedKey) ?? const [];
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> markLevelCompleted(int level) async {
    final store = await _store;
    final completed = await getCompletedLevels();
    completed.add(level);
    await store.setStringList(
      _completedKey,
      completed.map((e) => e.toString()).toList(),
    );
  }

  /// Nivel más alto desbloqueado.
  ///
  /// Se parte con el cráter 1 abierto y cada cráter completado abre el
  /// siguiente.
  Future<int> getHighestUnlockedLevel() async {
    final completed = await getCompletedLevels();
    var level = AppConstants.minProgressionLevel;
    while (completed.contains(level) && level < AppConstants.totalCraterCount) {
      level++;
    }
    return level;
  }


  // ------------------------------------------------------------
  // Ejercicios ya sorteados (anti-repetición entre cráteres)
  // ------------------------------------------------------------

  Future<Set<String>> getUsedExerciseIds() async {
    final store = await _store;
    return (store.getStringList(_usedKey) ?? const [])
        .toSet();
  }

  Future<void> addUsedExerciseIds(Iterable<String> ids) async {
    final store = await _store;
    final used = await getUsedExerciseIds();
    used.addAll(ids);
    await store.setStringList(_usedKey, used.toList());
  }

  /// Quita ids del registro — se usa al re-sortear un cráter, para no
  /// quemar ejercicios que al final no se van a ejecutar.
  Future<void> removeUsedExerciseIds(Iterable<String> ids) async {
    final store = await _store;
    final used = await getUsedExerciseIds();
    used.removeAll(ids);
    await store.setStringList(_usedKey, used.toList());
  }

  Future<void> resetUsedExerciseIds() async {
    final store = await _store;
    await store.remove(_usedKey);
  }

  // ------------------------------------------------------------
  // Acumulados de entrenamiento
  // ------------------------------------------------------------

  /// Suma lo hecho en una rutina terminada.
  Future<void> addSession({
    required int exercises,
    required int seconds,
  }) async {
    final store = await _store;
    final stats = await getStats();
    await store.setInt(
        AppConstants.totalExercisesKey, stats.exercises + exercises);
    await store.setInt(AppConstants.totalSecondsKey, stats.seconds + seconds);
    await store.setInt(AppConstants.totalSessionsKey, stats.sessions + 1);
  }

  Future<TrainingStats> getStats() async {
    final store = await _store;
    return TrainingStats(
      exercises: store.getInt(AppConstants.totalExercisesKey) ?? 0,
      seconds: store.getInt(AppConstants.totalSecondsKey) ?? 0,
      sessions: store.getInt(AppConstants.totalSessionsKey) ?? 0,
    );
  }

  /// Borra el avance del mapa de la ruta actual. Los acumulados de
  /// entrenamiento del niño (y el avance de las otras rutas) se conservan.
  Future<void> resetAll() async {
    final store = await _store;
    await store.remove(_completedKey);
    await store.remove(_usedKey);
  }
}

/// Acumulado de entrenamiento que se muestra en el mapa.
class TrainingStats {
  final int exercises;
  final int seconds;
  final int sessions;

  const TrainingStats({
    this.exercises = 0,
    this.seconds = 0,
    this.sessions = 0,
  });

  int get minutes => seconds ~/ 60;
}
