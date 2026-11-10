import 'package:flutter/material.dart';

import 'package:gymtea3/core/constants/app_constants.dart';
import 'package:gymtea3/data/models/difficulty.dart';
import 'package:gymtea3/data/models/exercise_model.dart';
import 'package:gymtea3/data/models/routine_model.dart';
import 'package:gymtea3/data/repositories/exercise_repository.dart';
import 'package:gymtea3/data/services/level_progress_service.dart';

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

  /// Rutina sorteada para el cráter que se está previsualizando.
  RoutineModel? _previewRoutine;

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
  RoutineModel? get previewRoutine => _previewRoutine;

  bool isUnlocked(int level) => level <= _highestUnlockedLevel;
  bool isCompleted(int level) => _completedLevels.contains(level);

  /// Carga el estado del mapa desde el almacenamiento local.
  Future<void> loadMapState() async {
    _isLoading = true;
    notifyListeners();

    try {
      _completedLevels = await _levelProgress.getCompletedLevels();
      _highestUnlockedLevel = await _levelProgress.getHighestUnlockedLevel();
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
    final count = dificultad.exerciseCount;

    // Si lo que queda del pool no alcanza para una rutina completa,
    // reiniciamos el registro de esa dificultad antes de sortear.
    final poolIds =
        (await _exerciseRepository.getPool(dificultad)).map((e) => e.id).toSet();
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

  /// Marca un cráter como completado y recalcula el desbloqueo.
  Future<void> completeLevel(int level) async {
    await _levelProgress.markLevelCompleted(level);
    _previewRoutine = null;
    await loadMapState();
  }

  /// Reinicia todo el avance del mapa (uso de pruebas / perfil).
  Future<void> resetProgress() async {
    await _levelProgress.resetAll();
    _previewRoutine = null;
    await loadMapState();
  }

  /// Pool de una dificultad (para pantallas de consulta).
  Future<List<ExerciseModel>> getPool(Dificultad dificultad) =>
      _exerciseRepository.getPool(dificultad);

}
