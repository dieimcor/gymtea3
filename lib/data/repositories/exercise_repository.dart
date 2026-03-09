import 'package:gymtea3/data/models/exercise_model.dart';

/// Repositorio de ejercicios — mock local por ahora
class ExerciseRepository {
  // TODO: Inyectar ApiClient + LocalDataSource cuando estén listos

  /// Obtener ejercicios por nivel de progresión
  Future<List<ExerciseModel>> getExercisesByLevel(int nivel) async {
    // Mock: retornar ejercicios de fortalecimiento del nivel indicado
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockExercises
        .where((e) => e.nivelProgresion == nivel && e.tipoFase == FaseSesion.fortalecimiento)
        .toList();
  }

  /// Obtener ejercicios por categoría (String) y nivel
  Future<ExerciseModel?> getExercise(String categoria, int nivel) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockExercises.cast<ExerciseModel?>().firstWhere(
      (e) => e!.categoria == categoria && e.nivelProgresion == nivel,
      orElse: () => null,
    );
  }

  /// Obtener todos los niveles disponibles (dinámico, desde los datos)
  Future<List<int>> getAvailableLevels() async {
    final levels = _mockExercises.map((e) => e.nivelProgresion).toSet().toList();
    levels.sort();
    return levels;
  }

  /// Obtener todas las categorías disponibles (dinámico, desde los datos)
  Future<List<String>> getAvailableCategories() async {
    return _mockExercises.map((e) => e.categoria).toSet().toList();
  }
}

/// Datos mock del Manual de Fuerza y Juegos — niveles 1-2 como ejemplo
final List<ExerciseModel> _mockExercises = [
  // === NIVEL 1 ===
  ExerciseModel(
    id: 'rd-1', nombre: 'Pararse y sentarse de un banco',
    descripcion: 'El participante se para y sienta de un banco usando ambas piernas, controlando el movimiento.',
    sugerencias: 'Usar implementos como mancuernas o bandas elásticas para mayor intensidad.',
    categoria: 'RD', categoriaNombre: 'Rodilla Dominante',
    nivelProgresion: 1, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'cd-1', nombre: 'Puente de glúteo dinámico',
    descripcion: 'Recostado en cubito dorsal (supino), con piernas flexionales apoyando plantas de los pies, elevar la cadera empujando con los pies.',
    sugerencias: 'Usar implementos como cajones para variar el rango de ejecución.',
    categoria: 'CD', categoriaNombre: 'Cadera Dominante',
    nivelProgresion: 1, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'em-1', nombre: 'Empuje balón medicinal acostado/supino',
    descripcion: 'Acostado en posición supina, empujar el balón medicinal hacia arriba con ambas manos.',
    sugerencias: 'Controlar la cadencia del movimiento durante la ejecución.',
    categoria: 'EM', categoriaNombre: 'Empuje',
    nivelProgresion: 1, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'jl-1', nombre: 'Remo al pecho con elástico a dos manos',
    descripcion: 'De pie, realizar un remo al pecho utilizando una banda elástica con ambas manos.',
    sugerencias: 'Variar la resistencia del elástico según la progresión del niño.',
    categoria: 'JL', categoriaNombre: 'Jalón',
    nivelProgresion: 1, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'cr-1', nombre: 'Extensiones de tronco a un brazo',
    descripcion: 'Acostado boca abajo, extender un brazo hacia adelante manteniendo el core activado.',
    sugerencias: 'Controlar la cadencia del movimiento durante la ejecución.',
    categoria: 'CR', categoriaNombre: 'Core',
    nivelProgresion: 1, tipoFase: FaseSesion.fortalecimiento,
  ),

  // === NIVEL 2 ===
  ExerciseModel(
    id: 'rd-2', nombre: 'Pararse y sentarse semi unipodal',
    descripcion: 'Pararse y sentarse de un banco apoyando uno de los pies de forma semi unipodal.',
    categoria: 'RD', categoriaNombre: 'Rodilla Dominante',
    nivelProgresion: 2, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'cd-2', nombre: 'Puente de glúteo unilateral estático',
    descripcion: 'Recostado en cubito dorsal, apoyando una de las plantas de los pies, elevar la cadera empujando con el pie, llevando el otro por delante.',
    categoria: 'CD', categoriaNombre: 'Cadera Dominante',
    nivelProgresion: 2, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'em-2', nombre: 'Empuje balón medicinal acostado/supino unilateral',
    descripcion: 'Acostado en posición supina, empujar el balón medicinal con una mano.',
    categoria: 'EM', categoriaNombre: 'Empuje',
    nivelProgresion: 2, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'jl-2', nombre: 'Remo al pecho con elástico a una mano',
    descripcion: 'De pie, realizar un remo al pecho con una sola mano.',
    categoria: 'JL', categoriaNombre: 'Jalón',
    nivelProgresion: 2, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'cr-2', nombre: 'Bicho muerto',
    descripcion: 'Acostado boca arriba, extender brazo y pierna contrarios manteniendo el core activado.',
    categoria: 'CR', categoriaNombre: 'Core',
    nivelProgresion: 2, tipoFase: FaseSesion.fortalecimiento,
  ),

  // === NIVEL 3-7+: se completarán desde el seeder del backend ===
];
