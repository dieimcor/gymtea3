import 'package:flutter/material.dart';
import 'package:gymtea3/data/models/exercise_model.dart';
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

  // Getters
  List<ExerciseModel> get exercises => _exercises;
  int get currentLevel => _currentLevel;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  /// Obtener ejercicios agrupados por categoría
  Map<CategoriaEjercicio, ExerciseModel> get exercisesByCategory {
    final map = <CategoriaEjercicio, ExerciseModel>{};
    for (final exercise in _exercises) {
      map[exercise.categoria] = exercise;
    }
    return map;
  }

  /// Obtener niveles disponibles
  Future<List<int>> getAvailableLevels() async {
    return await _exerciseRepository.getAvailableLevels();
  }
}
