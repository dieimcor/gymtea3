import 'package:flutter/material.dart';
import 'package:gymtea3/data/models/progress_model.dart';
import 'package:gymtea3/data/repositories/progress_repository.dart';

/// Provider de progreso — gestiona historial y sync
class ProgressProvider extends ChangeNotifier {
  final ProgressRepository _progressRepository;

  ProgressProvider({required ProgressRepository progressRepository})
      : _progressRepository = progressRepository;

  List<ProgressModel> _progressHistory = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;

  // Getters
  List<ProgressModel> get progressHistory => _progressHistory;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  int get pendingSyncCount => _progressHistory.where((p) => !p.sincronizado).length;

  /// Total de sesiones completadas
  int get totalSessions => _progressHistory.length;

  /// Tiempo total de entrenamiento en minutos
  int get totalMinutes =>
      _progressHistory.fold(0, (sum, p) => sum + p.tiempoRealSeg) ~/ 60;

  /// Sesiones completadas hoy
  int get todaySessions {
    final now = DateTime.now();
    return _progressHistory.where((p) =>
      p.fecha.year == now.year &&
      p.fecha.month == now.month &&
      p.fecha.day == now.day
    ).length;
  }

  /// Registrar progreso de una sesión completada
  Future<void> recordProgress(ProgressModel progress) async {
    try {
      await _progressRepository.saveProgress(progress);
      _progressHistory.add(progress);
      notifyListeners();
    } catch (e) {
      _error = 'Error al guardar progreso: $e';
      notifyListeners();
    }
  }

  /// Registrar progreso de sesión (convenience method desde la pantalla de sesión)
  Future<void> recordSessionProgress({
    required String childId,
    required String sessionId,
    required int level,
    required List<String> completedExerciseIds,
    required int elapsedSeconds,
  }) async {
    final progress = ProgressModel(
      id: 'prog-${DateTime.now().millisecondsSinceEpoch}',
      childId: childId,
      sessionId: sessionId,
      nivelCompletado: level,
      ejerciciosCompletadosIds: completedExerciseIds,
      tiempoRealSeg: elapsedSeconds,
      fecha: DateTime.now(),
      sincronizado: false,
    );
    await recordProgress(progress);
  }

  /// Cargar historial de progreso
  Future<void> loadProgress(String childId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _progressHistory = await _progressRepository.getProgressByChild(childId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar progreso: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sincronizar progreso pendiente con el backend
  Future<void> syncPendingProgress() async {
    _isSyncing = true;
    notifyListeners();

    try {
      final pending = await _progressRepository.getPendingSync();
      if (pending.isNotEmpty) {
        // TODO: Enviar al backend en Sprint 4
        final ids = pending.map((p) => p.id).toList();
        await _progressRepository.markAsSynced(ids);
      }
      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al sincronizar: $e';
      _isSyncing = false;
      notifyListeners();
    }
  }
}
