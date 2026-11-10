import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymtea3/core/constants/app_constants.dart';

/// Persiste el avance del mapa de cráteres.
///
/// Es deliberadamente independiente de la evaluación funcional y del
/// perfilamiento del niño: el desbloqueo depende solo de los cráteres
/// que ya se completaron en este dispositivo.
class LevelProgressService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ------------------------------------------------------------
  // Niveles completados
  // ------------------------------------------------------------

  /// Niveles (cráteres) completados al menos una vez.
  Future<Set<int>> getCompletedLevels() async {
    final store = await _store;
    final raw = store.getStringList(AppConstants.completedLevelsKey) ?? const [];
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> markLevelCompleted(int level) async {
    final store = await _store;
    final completed = await getCompletedLevels();
    completed.add(level);
    await store.setStringList(
      AppConstants.completedLevelsKey,
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
    return (store.getStringList(AppConstants.usedExerciseIdsKey) ?? const [])
        .toSet();
  }

  Future<void> addUsedExerciseIds(Iterable<String> ids) async {
    final store = await _store;
    final used = await getUsedExerciseIds();
    used.addAll(ids);
    await store.setStringList(AppConstants.usedExerciseIdsKey, used.toList());
  }

  /// Quita ids del registro — se usa al re-sortear un cráter, para no
  /// quemar ejercicios que al final no se van a ejecutar.
  Future<void> removeUsedExerciseIds(Iterable<String> ids) async {
    final store = await _store;
    final used = await getUsedExerciseIds();
    used.removeAll(ids);
    await store.setStringList(AppConstants.usedExerciseIdsKey, used.toList());
  }

  Future<void> resetUsedExerciseIds() async {
    final store = await _store;
    await store.remove(AppConstants.usedExerciseIdsKey);
  }

  /// Borra todo el avance del mapa.
  Future<void> resetAll() async {
    final store = await _store;
    await store.remove(AppConstants.completedLevelsKey);
    await store.remove(AppConstants.usedExerciseIdsKey);
  }
}
