import 'package:flutter/material.dart';
import 'package:gymtea3/data/models/exercise_model.dart';
import 'package:gymtea3/data/models/session_model.dart';
import 'package:gymtea3/data/repositories/exercise_repository.dart';

/// Provider de ejercicios — gestiona estado de ejercicios y niveles
class ExerciseProvider extends ChangeNotifier {
  final ExerciseRepository _exerciseRepository;

  ExerciseProvider({required ExerciseRepository exerciseRepository})
      : _exerciseRepository = exerciseRepository;

  List<ExerciseModel> _exercises = [];
  int _currentLevel = 1;
  bool _isLoading = false;
  String? _error;
  List<int> _availableLevels = [];
  List<String> _availableCategories = [];

  // Getters
  List<ExerciseModel> get exercises => _exercises;
  int get currentLevel => _currentLevel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<int> get availableLevels => _availableLevels;
  List<String> get availableCategories => _availableCategories;

  /// Cargar ejercicios de un nivel específico
  Future<void> loadExercisesForLevel(int level) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _exercises = await _exerciseRepository.getExercisesByLevel(level);
      _currentLevel = level;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar ejercicios: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar categorías y niveles disponibles (dinámico desde backend)
  Future<void> loadAvailableFilters() async {
    try {
      _availableLevels = await _exerciseRepository.getAvailableLevels();
      _availableCategories = await _exerciseRepository.getAvailableCategories();
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar filtros: $e';
      notifyListeners();
    }
  }

  /// Obtener ejercicios agrupados por categoría (String key)
  Map<String, ExerciseModel> get exercisesByCategory {
    final map = <String, ExerciseModel>{};
    for (final exercise in _exercises) {
      map[exercise.categoria] = exercise;
    }
    return map;
  }

  /// Obtener niveles disponibles
  Future<List<int>> getAvailableLevels() async {
    return await _exerciseRepository.getAvailableLevels();
  }

  /// Armar una SessionModel completa para un nivel dado
  /// Reune: 5 activación + 5 fortalecimiento (1 por categoría) + 1 juego
  Future<SessionModel> buildSession({
    required String childId,
    required int level,
  }) async {
    final activation = await _exerciseRepository.getActivationExercises(level);
    final strengthening = await _exerciseRepository.getExercisesByLevel(level);
    final game = await _exerciseRepository.getGameExercise(level);

    return SessionModel(
      id: 'session-${DateTime.now().millisecondsSinceEpoch}',
      childId: childId,
      nivel: level,
      ejerciciosActivacion: activation,
      ejerciciosFortalecimiento: strengthening,
      juego: game,
      fecha: DateTime.now(),
    );
  }
}
