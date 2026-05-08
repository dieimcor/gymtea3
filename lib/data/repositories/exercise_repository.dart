import 'package:gymtea3/data/models/exercise_model.dart';

/// Repositorio de ejercicios — mock local por ahora
class ExerciseRepository {
  // TODO: Inyectar ApiClient + LocalDataSource cuando estén listos

  /// Obtener ejercicios por nivel de progresión
  Future<List<ExerciseModel>> getExercisesByLevel(int nivel) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockExercises
        .where((e) => e.nivelProgresion == nivel && e.tipoFase == FaseSesion.fortalecimiento)
        .toList();
  }

  /// Obtener ejercicios de activación por nivel
  Future<List<ExerciseModel>> getActivationExercises(int nivel) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockExercises
        .where((e) => e.nivelProgresion == nivel && e.tipoFase == FaseSesion.activacion)
        .toList();
  }

  /// Obtener juego/circuito por nivel
  Future<ExerciseModel?> getGameExercise(int nivel) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockExercises.cast<ExerciseModel?>().firstWhere(
      (e) => e!.nivelProgresion == nivel && e.tipoFase == FaseSesion.juego,
      orElse: () => null,
    );
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
    final levels = _mockExercises
        .where((e) => e.tipoFase == FaseSesion.fortalecimiento)
        .map((e) => e.nivelProgresion)
        .toSet()
        .toList();
    levels.sort();
    return levels;
  }

  /// Obtener todas las categorías disponibles (dinámico, desde los datos)
  Future<List<String>> getAvailableCategories() async {
    return _mockExercises.map((e) => e.categoria).toSet().toList();
  }
}

// ============================================================
// DATOS MOCK — Manual de Fuerza y Juegos (USAC, 2022)
// 7 niveles × 5 categorías = 35 fortalecimiento
// + 5 activación por nivel = 35 activación
// + 1 juego por nivel = 7 juegos
// Total: 77 ejercicios mock
// ============================================================

final List<ExerciseModel> _mockExercises = [
  // ============================================================
  // FORTALECIMIENTO — 5 categorías × 7 niveles = 35 ejercicios
  // ============================================================

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

  // === NIVEL 3 ===
  ExerciseModel(
    id: 'rd-3', nombre: 'Sentadilla con apoyo (TRX / elástico)',
    descripcion: 'Realizar sentadilla manteniendo el torso erguido, asistido con TRX o banda elástica.',
    categoria: 'RD', categoriaNombre: 'Rodilla Dominante',
    nivelProgresion: 3, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'cd-3', nombre: 'Puente de glúteo con elevación de pies',
    descripcion: 'Puente de glúteo con los pies elevados sobre un banco o cajón para mayor activación.',
    categoria: 'CD', categoriaNombre: 'Cadera Dominante',
    nivelProgresion: 3, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'em-3', nombre: 'Empuje de pie con balón medicinal',
    descripcion: 'De pie, empujar el balón medicinal hacia adelante a la altura del pecho con ambas manos.',
    categoria: 'EM', categoriaNombre: 'Empuje',
    nivelProgresion: 3, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'jl-3', nombre: 'Jalón con elástico desde arriba',
    descripcion: 'Con el elástico anclado en alto, jalar hacia abajo con ambas manos controlando el movimiento.',
    categoria: 'JL', categoriaNombre: 'Jalón',
    nivelProgresion: 3, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'cr-3', nombre: 'Plancha frontal con apoyo de rodillas',
    descripcion: 'Mantener posición de plancha frontal apoyado sobre las rodillas activando el core.',
    categoria: 'CR', categoriaNombre: 'Core',
    nivelProgresion: 3, tipoFase: FaseSesion.fortalecimiento,
  ),

  // === NIVEL 4 ===
  ExerciseModel(
    id: 'rd-4', nombre: 'Sentadilla libre',
    descripcion: 'Sentadilla sin asistencia controlando la profundidad y el equilibrio.',
    categoria: 'RD', categoriaNombre: 'Rodilla Dominante',
    nivelProgresion: 4, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'cd-4', nombre: 'Peso muerto rumano con mancuerna',
    descripcion: 'De pie, realizar bisagra de cadera con una mancuerna ligera manteniendo espalda neutra.',
    categoria: 'CD', categoriaNombre: 'Cadera Dominante',
    nivelProgresion: 4, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'em-4', nombre: 'Flexiones de brazos inclinadas',
    descripcion: 'Realizar flexiones con las manos en un banco o superficie elevada.',
    categoria: 'EM', categoriaNombre: 'Empuje',
    nivelProgresion: 4, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'jl-4', nombre: 'Remo con mancuerna a una mano',
    descripcion: 'Apoyado en un banco, realizar remo con mancuerna a una mano controlando el core.',
    categoria: 'JL', categoriaNombre: 'Jalón',
    nivelProgresion: 4, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'cr-4', nombre: 'Plancha frontal completa',
    descripcion: 'Mantener posición de plancha frontal completa sobre las puntas de los pies.',
    categoria: 'CR', categoriaNombre: 'Core',
    nivelProgresion: 4, tipoFase: FaseSesion.fortalecimiento,
  ),

  // === NIVEL 5 ===
  ExerciseModel(
    id: 'rd-5', nombre: 'Sentadilla goblet con mancuerna',
    descripcion: 'Sentadilla sosteniendo una mancuerna frente al pecho con ambas manos.',
    categoria: 'RD', categoriaNombre: 'Rodilla Dominante',
    nivelProgresion: 5, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'cd-5', nombre: 'Peso muerto rumano unilateral',
    descripcion: 'Peso muerto rumano apoyando sobre una sola pierna para mayor exigencia.',
    categoria: 'CD', categoriaNombre: 'Cadera Dominante',
    nivelProgresion: 5, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'em-5', nombre: 'Flexiones de brazos en suelo',
    descripcion: 'Flexiones completas en el suelo con control del core.',
    categoria: 'EM', categoriaNombre: 'Empuje',
    nivelProgresion: 5, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'jl-5', nombre: 'Dominadas asistidas con elástico',
    descripcion: 'Realizar dominadas con asistencia de banda elástica controlando la subida y bajada.',
    categoria: 'JL', categoriaNombre: 'Jalón',
    nivelProgresion: 5, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'cr-5', nombre: 'Plancha lateral con apoyo de rodilla',
    descripcion: 'Plancha lateral apoyando la rodilla inferior para estabilidad.',
    categoria: 'CR', categoriaNombre: 'Core',
    nivelProgresion: 5, tipoFase: FaseSesion.fortalecimiento,
  ),

  // === NIVEL 6 ===
  ExerciseModel(
    id: 'rd-6', nombre: 'Zancada frontal con mancuernas',
    descripcion: 'Dar un paso al frente bajando la rodilla trasera, con mancuernas en ambas manos.',
    categoria: 'RD', categoriaNombre: 'Rodilla Dominante',
    nivelProgresion: 6, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'cd-6', nombre: 'Hip thrust con barra o mancuerna',
    descripcion: 'Apoyando la espalda en un banco, elevar cadera con carga externa.',
    categoria: 'CD', categoriaNombre: 'Cadera Dominante',
    nivelProgresion: 6, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'em-6', nombre: 'Press de hombros con mancuernas',
    descripcion: 'Sentado o de pie, empujar mancuernas desde los hombros hacia arriba.',
    categoria: 'EM', categoriaNombre: 'Empuje',
    nivelProgresion: 6, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'jl-6', nombre: 'Remo invertido en TRX',
    descripcion: 'Colgarse del TRX inclinado y jalar el cuerpo hacia arriba controlando la espalda.',
    categoria: 'JL', categoriaNombre: 'Jalón',
    nivelProgresion: 6, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'cr-6', nombre: 'Plancha lateral completa',
    descripcion: 'Plancha lateral con piernas extendidas y cadera elevada.',
    categoria: 'CR', categoriaNombre: 'Core',
    nivelProgresion: 6, tipoFase: FaseSesion.fortalecimiento,
  ),

  // === NIVEL 7 ===
  ExerciseModel(
    id: 'rd-7', nombre: 'Sentadilla búlgara',
    descripcion: 'Sentadilla con pie trasero elevado en banco, mayor exigencia unilateral.',
    categoria: 'RD', categoriaNombre: 'Rodilla Dominante',
    nivelProgresion: 7, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'cd-7', nombre: 'Peso muerto sumo con kettlebell',
    descripcion: 'Peso muerto con piernas separadas y pies hacia afuera, usando kettlebell.',
    categoria: 'CD', categoriaNombre: 'Cadera Dominante',
    nivelProgresion: 7, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'em-7', nombre: 'Flexiones diamante',
    descripcion: 'Flexiones con manos juntas formando un diamante, mayor activación de tríceps.',
    categoria: 'EM', categoriaNombre: 'Empuje',
    nivelProgresion: 7, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'jl-7', nombre: 'Dominadas sin asistencia',
    descripcion: 'Dominadas completas sin asistencia, controlando todo el rango de movimiento.',
    categoria: 'JL', categoriaNombre: 'Jalón',
    nivelProgresion: 7, tipoFase: FaseSesion.fortalecimiento,
  ),
  ExerciseModel(
    id: 'cr-7', nombre: 'Ab wheel rollout de rodillas',
    descripcion: 'Con rueda abdominal, extender el cuerpo desde las rodillas manteniendo el core activo.',
    categoria: 'CR', categoriaNombre: 'Core',
    nivelProgresion: 7, tipoFase: FaseSesion.fortalecimiento,
  ),

  // ============================================================
  // ACTIVACIÓN NEUROMUSCULAR — 5 ejercicios por nivel (fase 1)
  // Duración: 2 min, 2×15 reps
  // ============================================================

  // Activación — usada en todos los niveles (genérica, misma para todos)
  ..._buildActivationExercises(1),
  ..._buildActivationExercises(2),
  ..._buildActivationExercises(3),
  ..._buildActivationExercises(4),
  ..._buildActivationExercises(5),
  ..._buildActivationExercises(6),
  ..._buildActivationExercises(7),

  // ============================================================
  // JUEGOS / CIRCUITOS — 1 por nivel (fase 3)
  // Duración: 5 min
  // ============================================================
  ExerciseModel(
    id: 'juego-1', nombre: 'Circuito de animales',
    descripcion: 'Imitar movimientos de animales: caminar como oso, saltar como rana, arrastrarse como serpiente. Completar circuito en rondas de 1 minuto.',
    categoria: 'JUEGO', categoriaNombre: 'Juego Motor',
    nivelProgresion: 1, tipoFase: FaseSesion.juego,
  ),
  ExerciseModel(
    id: 'juego-2', nombre: 'Carrera de obstáculos baja',
    descripcion: 'Pasar por debajo y por encima de obstáculos bajos (conos, cuerdas) lo más rápido posible.',
    categoria: 'JUEGO', categoriaNombre: 'Juego Motor',
    nivelProgresion: 2, tipoFase: FaseSesion.juego,
  ),
  ExerciseModel(
    id: 'juego-3', nombre: 'Lanzamiento al blanco',
    descripcion: 'Lanzar pelotas suaves o balones medicinales ligeros a un blanco en la pared a diferentes alturas.',
    categoria: 'JUEGO', categoriaNombre: 'Juego Motor',
    nivelProgresion: 3, tipoFase: FaseSesion.juego,
  ),
  ExerciseModel(
    id: 'juego-4', nombre: 'Relevo de fuerza',
    descripcion: 'Circuito de relevos con estaciones: arrastrar corebag, saltar conos, empujar balón.',
    categoria: 'JUEGO', categoriaNombre: 'Juego Motor',
    nivelProgresion: 4, tipoFase: FaseSesion.juego,
  ),
  ExerciseModel(
    id: 'juego-5', nombre: 'Juego del espejo',
    descripcion: 'Un participante realiza movimientos de fuerza y el otro los imita como espejo.',
    categoria: 'JUEGO', categoriaNombre: 'Juego Motor',
    nivelProgresion: 5, tipoFase: FaseSesion.juego,
  ),
  ExerciseModel(
    id: 'juego-6', nombre: 'Circuito cronometrado',
    descripcion: 'Completar un circuito de 5 estaciones de fuerza lo más rápido posible, intentando mejorar el tiempo.',
    categoria: 'JUEGO', categoriaNombre: 'Juego Motor',
    nivelProgresion: 6, tipoFase: FaseSesion.juego,
  ),
  ExerciseModel(
    id: 'juego-7', nombre: 'Desafío de equilibrio y fuerza',
    descripcion: 'Mantener posiciones de fuerza sobre superficies inestables mientras completa desafíos coordinativos.',
    categoria: 'JUEGO', categoriaNombre: 'Juego Motor',
    nivelProgresion: 7, tipoFase: FaseSesion.juego,
  ),
];

/// Genera 5 ejercicios de activación neuromuscular para un nivel dado
List<ExerciseModel> _buildActivationExercises(int nivel) {
  return [
    ExerciseModel(
      id: 'act-$nivel-1', nombre: 'Marcha en el lugar con rodillas altas',
      descripcion: 'Elevar rodillas alternando, manteniendo postura erguida y activando core.',
      categoria: 'ACT', categoriaNombre: 'Activación',
      nivelProgresion: nivel, tipoFase: FaseSesion.activacion,
      series: 2, repeticiones: 15,
    ),
    ExerciseModel(
      id: 'act-$nivel-2', nombre: 'Círculos de brazos',
      descripcion: 'Realizar círculos amplios con ambos brazos hacia adelante y hacia atrás.',
      categoria: 'ACT', categoriaNombre: 'Activación',
      nivelProgresion: nivel, tipoFase: FaseSesion.activacion,
      series: 2, repeticiones: 15,
    ),
    ExerciseModel(
      id: 'act-$nivel-3', nombre: 'Sentadilla sin peso con brazos al frente',
      descripcion: 'Sentadilla ligera con brazos extendidos al frente para activar cadena posterior.',
      categoria: 'ACT', categoriaNombre: 'Activación',
      nivelProgresion: nivel, tipoFase: FaseSesion.activacion,
      series: 2, repeticiones: 15,
    ),
    ExerciseModel(
      id: 'act-$nivel-4', nombre: 'Rotación de tronco',
      descripcion: 'De pie, rotar el tronco de lado a lado con brazos extendidos, activando oblicuos.',
      categoria: 'ACT', categoriaNombre: 'Activación',
      nivelProgresion: nivel, tipoFase: FaseSesion.activacion,
      series: 2, repeticiones: 15,
    ),
    ExerciseModel(
      id: 'act-$nivel-5', nombre: 'Skipping suave',
      descripcion: 'Trotar suave en el lugar elevando ligeramente los talones hacia los glúteos.',
      categoria: 'ACT', categoriaNombre: 'Activación',
      nivelProgresion: nivel, tipoFase: FaseSesion.activacion,
      series: 2, repeticiones: 15,
    ),
  ];
}
