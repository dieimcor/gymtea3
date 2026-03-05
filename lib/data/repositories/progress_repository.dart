import 'package:gymtea3/data/models/progress_model.dart';

/// Repositorio de progreso — cache local + sync
class ProgressRepository {
  // TODO: Inyectar LocalDataSource para SQLite
  final List<ProgressModel> _localCache = [];

  /// Guardar progreso localmente
  Future<void> saveProgress(ProgressModel progress) async {
    _localCache.add(progress);
    // TODO: Guardar en SQLite
  }

  /// Obtener progreso pendiente de sincronizar
  Future<List<ProgressModel>> getPendingSync() async {
    return _localCache.where((p) => !p.sincronizado).toList();
  }

  /// Marcar como sincronizado
  Future<void> markAsSynced(List<String> ids) async {
    // TODO: Actualizar en SQLite
  }

  /// Obtener todo el progreso de un niño
  Future<List<ProgressModel>> getProgressByChild(String childId) async {
    return _localCache.where((p) => p.childId == childId).toList();
  }

  /// Contar sesiones completadas por nivel
  Future<int> getCompletedSessionsCount(String childId, int nivel) async {
    return _localCache.where(
      (p) => p.childId == childId && p.nivelCompletado == nivel,
    ).length;
  }
}
