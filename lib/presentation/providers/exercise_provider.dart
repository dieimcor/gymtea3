import 'package:flutter/material.dart';

import 'package:gymtea3/core/constants/app_constants.dart';
import 'package:gymtea3/core/theme/comet_theme.dart';
import 'package:gymtea3/data/models/difficulty.dart';
import 'package:gymtea3/data/models/exercise_model.dart';
import 'package:gymtea3/data/models/routine_model.dart';
import 'package:gymtea3/data/models/training_route.dart';
import 'package:gymtea3/data/repositories/exercise_repository.dart';
import 'package:gymtea3/data/services/level_progress_service.dart';

/// Resultado de completar un cráter: le dice a la sesión si hay que
/// mostrar la recompensa del cometa y, después, el viaje al siguiente.
class LevelCompletion {
  final int level;

  /// Índice (0-based) del cometa al que pertenece el cráter.
  final int cometIndex;

  /// `true` si con este cráter se conquistaron por primera vez los 4
  /// cráteres de su cometa. Rejugar un cráter ya conquistado no cuenta.
  final bool cometCompleted;

  /// `true` si además era el último cometa: se terminó todo el viaje.
  final bool journeyCompleted;

  const LevelCompletion({
    required this.level,
    required this.cometIndex,
    required this.cometCompleted,
    required this.journeyCompleted,
  });
}

/// Provider del mapa de cráteres y de las rutinas sorteadas.
class ExerciseProvider extends ChangeNotifier {
  final ExerciseRepository _exerciseRepository;
  final LevelProgressService _levelProgress;

  ExerciseProvider({
    required ExerciseRepository exerciseRepository,
    required LevelProgressService levelProgressService,
  })  : _exerciseRepository = exerciseRepository,
        _levelProgress = levelProgressService;

  Set<int> _completedLevels = {};
  int _highestUnlockedLevel = AppConstants.minProgressionLevel;
  bool _isLoading = false;
  String? _error;
  TrainingStats _stats = const TrainingStats();

  /// Rutina sorteada para el cráter que se está previsualizando.
  RoutineModel? _previewRoutine;

  /// Ruta de entrenamiento elegida por el padre.
  TrainingRoute _route = TrainingRoute.explorador;
  bool _hasSelectedRoute = false;
  bool _routeLoaded = false;

  TrainingRoute get route => _route;

  /// `false` hasta que el padre elige una ruta (primera vez).
  bool get hasSelectedRoute => _hasSelectedRoute;

  /// Planeta [cometIndex] de la ruta actual (ver [cometIndex], no
  /// [roundIndex], que cuenta caras).
  CometTheme cometTheme(int cometIndex) => _route.cometAt(cometIndex);

  /// Lee la ruta guardada (una sola vez por sesión de la app).
  Future<TrainingRoute?> loadSelectedRoute() async {
    final saved = await _levelProgress.getSelectedRoute();
    _routeLoaded = true;
    _hasSelectedRoute = saved != null;
    if (saved != null) {
      _route = saved;
      _levelProgress.route = saved;
    }
    notifyListeners();
    return saved;
  }

  /// Elige (o cambia) la ruta. Cada ruta conserva su propio avance.
  Future<void> selectRoute(TrainingRoute value) async {
    await _levelProgress.saveSelectedRoute(value);
    _route = value;
    _hasSelectedRoute = true;
    _routeLoaded = true;
    _previewRoutine = null;
    await loadMapState();
  }

  // Getters
  Set<int> get completedLevels => _completedLevels;
  int get highestUnlockedLevel => _highestUnlockedLevel;
  /// Total de niveles del catalogo.
  int get totalCraters => AppConstants.totalCraterCount;

  /// Primer nivel de la tanda que se muestra en el cometa.
  ///
  /// El mapa siempre dibuja un solo cometa con sus 4 crateres: al
  /// conquistar los 4, los crateres se renumeran con los siguientes
  /// niveles en vez de aparecer un cometa nuevo.
  int get firstLevelInRound =>
      ((_highestUnlockedLevel - 1) ~/ AppConstants.initialCraterCount) *
          AppConstants.initialCraterCount +
      1;

  /// Índice (0-based) del cometa que se muestra: 0 para los niveles 1-4,
  /// 1 para 5-8, etc. Cambia el aspecto del cometa (ver `CometTheme`).
  int get roundIndex =>
      (firstLevelInRound - 1) ~/ AppConstants.initialCraterCount;

  /// Cantidad total de cometas del viaje.
  int get totalComets =>
      (totalCraters / AppConstants.cratersPerComet).ceil();

  /// Cometa que se está mostrando (0-based). Cada cometa tiene dos caras
  /// de 4 cráteres: [roundIndex] cuenta caras, esto cuenta cometas.
  int get cometIndex => roundIndex ~/ AppConstants.facesPerComet;

  /// Cara del cometa actual (0 = la primera, 1 = "el otro lado").
  int get faceInComet => roundIndex % AppConstants.facesPerComet;

  /// `true` si la cara actual es la última de su cometa: al terminarla se
  /// viaja; si no, el cometa da la vuelta.
  bool get isLastFaceOfComet =>
      faceInComet == AppConstants.facesPerComet - 1;

  /// Índice del cometa al que pertenece un nivel.
  static int cometIndexOf(int level) =>
      (level - 1) ~/ AppConstants.cratersPerComet;

  /// Niveles que se ven ahora sobre el cometa.
  List<int> get levelsInRound => [
        for (var i = 0; i < AppConstants.initialCraterCount; i++)
          if (firstLevelInRound + i <= totalCraters) firstLevelInRound + i,
      ];

  /// `true` si quedan niveles despues de la tanda actual.
  bool get hasNextRound =>
      levelsInRound.isNotEmpty && levelsInRound.last < totalCraters;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Acumulado de entrenamiento (persistido).
  TrainingStats get stats => _stats;

  /// Avance sobre el total de niveles, de 0 a 1.
  double get overallProgress =>
      totalCraters == 0 ? 0 : _completedLevels.length / totalCraters;
  RoutineModel? get previewRoutine => _previewRoutine;

  bool isUnlocked(int level) => level <= _highestUnlockedLevel;
  bool isCompleted(int level) => _completedLevels.contains(level);

  /// Carga el estado del mapa desde el almacenamiento local.
  Future<void> loadMapState() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (!_routeLoaded) await loadSelectedRoute();
      _levelProgress.route = _route;
      _completedLevels = await _levelProgress.getCompletedLevels();
      _highestUnlockedLevel = await _levelProgress.getHighestUnlockedLevel();
      _stats = await _levelProgress.getStats();
      _error = null;
    } catch (e) {
      _error = 'Error al cargar el mapa: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Sortea la rutina de un cráter.
  ///
  /// Los ejercicios se eligen al azar del pool de la dificultad del nivel,
  /// excluyendo los ya sorteados en otros cráteres. Cuando el pool se agota
  /// el registro se reinicia solo y vuelve a empezar.
  ///
  /// Se llama cada vez que se abre el cráter, así que entrar de nuevo
  /// re-randomiza la selección.
  Future<RoutineModel> buildRoutine({
    required String childId,
    required int level,
  }) async {
    final dificultad = Dificultad.forLevel(level);
    // La ruta Comandante suma un ejercicio por cráter.
    final count = dificultad.exerciseCount + _route.extraExercises;

    // Si lo que queda del pool no alcanza para una rutina completa,
    // reiniciamos el registro de esa dificultad antes de sortear.
    final poolIds = (await _exerciseRepository.getPool(
      dificultad,
      route: _route,
      minSize: count,
    ))
        .map((e) => e.id)
        .toSet();
    var used = await _levelProgress.getUsedExerciseIds();
    final remaining = poolIds.difference(used).length;
    if (remaining < count) {
      await _levelProgress.removeUsedExerciseIds(poolIds);
      used = await _levelProgress.getUsedExerciseIds();
    }

    final ejercicios = await _exerciseRepository.pickRandom(
      dificultad: dificultad,
      count: count,
      excludeIds: used,
      route: _route,
    );

    // Liberamos la selección anterior de la preview: si el usuario vuelve a
    // sortear, esos ejercicios no deben quedar quemados.
    final previous = _previewRoutine;
    if (previous != null && previous.nivel == level) {
      await _levelProgress
          .removeUsedExerciseIds(previous.ejercicios.map((e) => e.id));
    }

    await _levelProgress.addUsedExerciseIds(ejercicios.map((e) => e.id));

    final routine = RoutineModel(
      id: 'routine-${DateTime.now().millisecondsSinceEpoch}',
      childId: childId,
      nivel: level,
      dificultad: dificultad,
      ejercicios: ejercicios,
      fecha: DateTime.now(),
      ruta: _route,
    );

    _previewRoutine = routine;
    notifyListeners();
    return routine;
  }

  /// Descarta la rutina previsualizada y libera sus ejercicios.
  Future<void> discardPreview() async {
    final preview = _previewRoutine;
    if (preview == null) return;

    await _levelProgress
        .removeUsedExerciseIds(preview.ejercicios.map((e) => e.id));
    _previewRoutine = null;
    notifyListeners();
  }

  /// Niveles que forman el cometa [cometIndex] (sin pasarse del total).
  List<int> levelsOfComet(int cometIndex) {
    final first = cometIndex * AppConstants.cratersPerComet + 1;
    return [
      for (var i = 0; i < AppConstants.cratersPerComet; i++)
        if (first + i <= totalCraters) first + i,
    ];
  }

  /// Marca un cráter como completado, suma lo entrenado y recalcula el
  /// desbloqueo.
  ///
  /// Devuelve si con este cráter se conquistó el cometa completo (para
  /// mostrar la recompensa) y si se terminó el viaje.
  Future<LevelCompletion> completeLevel(
    int level, {
    int exercisesDone = 0,
    int elapsedSeconds = 0,
  }) async {
    final cometIndex = cometIndexOf(level);
    final cometLevels = levelsOfComet(cometIndex);
    final before = await _levelProgress.getCompletedLevels();
    final wasCometDone = cometLevels.every(before.contains);

    await _levelProgress.markLevelCompleted(level);
    await _levelProgress.addSession(
      exercises: exercisesDone,
      seconds: elapsedSeconds,
    );
    _previewRoutine = null;
    await loadMapState();

    final isCometDone = cometLevels.every(_completedLevels.contains);
    final cometCompleted = !wasCometDone && isCometDone;
    return LevelCompletion(
      level: level,
      cometIndex: cometIndex,
      cometCompleted: cometCompleted,
      journeyCompleted: cometCompleted && cometIndex == totalComets - 1,
    );
  }

  /// Reinicia todo el avance del mapa (uso de pruebas / perfil).
  Future<void> resetProgress() async {
    await _levelProgress.resetAll();
    _previewRoutine = null;
    await loadMapState();
  }

  /// Pool de una dificultad en la ruta actual (para pantallas de consulta).
  Future<List<ExerciseModel>> getPool(Dificultad dificultad) =>
      _exerciseRepository.getPool(dificultad, route: _route);

}
