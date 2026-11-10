import 'dart:math';

import 'package:gymtea3/data/models/difficulty.dart';
import 'package:gymtea3/data/models/exercise_model.dart';

/// Repositorio de ejercicios — mock local por ahora.
///
/// Expone pools por dificultad y el sorteo aleatorio sin repetición
/// que usa el mapa de cráteres.
class ExerciseRepository {
  // TODO: Inyectar ApiClient + LocalDataSource cuando estén listos

  final Random _random;

  ExerciseRepository({Random? random}) : _random = random ?? Random();

  /// Todos los ejercicios del catálogo.
  Future<List<ExerciseModel>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_mockExercises);
  }

  /// Pool completo de una dificultad.
  Future<List<ExerciseModel>> getPool(Dificultad dificultad) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockExercises.where((e) => e.dificultad == dificultad).toList();
  }

  /// Sortea [count] ejercicios de la dificultad dada evitando los de
  /// [excludeIds].
  ///
  /// Si el pool restante no alcanza, completa con los ya usados —
  /// de ese modo la rutina siempre sale completa aunque el catálogo
  /// se haya agotado. El reinicio del registro lo decide el llamador
  /// (ver `ExerciseProvider.buildRoutine`).
  Future<List<ExerciseModel>> pickRandom({
    required Dificultad dificultad,
    required int count,
    Set<String> excludeIds = const {},
  }) async {
    final pool = await getPool(dificultad);

    final fresh = pool.where((e) => !excludeIds.contains(e.id)).toList()
      ..shuffle(_random);

    if (fresh.length >= count) {
      return fresh.take(count).toList();
    }

    // Pool agotado: completamos con los restantes, también al azar.
    final reused = pool.where((e) => excludeIds.contains(e.id)).toList()
      ..shuffle(_random);

    return [...fresh, ...reused.take(count - fresh.length)];
  }

  /// Tamaño del pool de una dificultad (para saber si conviene reiniciar
  /// el registro de ejercicios usados).
  Future<int> poolSize(Dificultad dificultad) async {
    return _mockExercises.where((e) => e.dificultad == dificultad).length;
  }

  /// Obtener un ejercicio por id.
  Future<ExerciseModel?> getById(String id) async {
    for (final e in _mockExercises) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Todas las categorías disponibles (dinámico, desde los datos)
  Future<List<String>> getAvailableCategories() async {
    return _mockExercises.map((e) => e.categoria).toSet().toList();
  }
}

// ============================================================
// DATOS MOCK — Manual de Fuerza y Juegos (USAC, 2022)
// + movimientos de movilidad y juego.
//
// Cada ejercicio pertenece a un pool de dificultad:
//   fácil   → niveles 1-2 (3 ejercicios por rutina)
//   medio   → niveles 3-5 (4 ejercicios por rutina)
//   difícil → niveles 6-8 (5 ejercicios por rutina)
//
// Ningun ejercicio tiene ilustracion todavia: todos muestran el
// placeholder con su nombre. `imagenAsset` apunta por defecto a
// assets/images/ejercicios/<id>.png, asi que para agregar el arte basta
// dejar ahi el PNG con el id del ejercicio, sin tocar este archivo.
// ============================================================

final List<ExerciseModel> _mockExercises = [
  // ============================================================
  // POOL FÁCIL
  // ============================================================
  ExerciseModel(
    id: 'rd-1',
    nombre: 'Pararse y sentarse de un banco',
    descripcion:
        'El participante se para y sienta de un banco usando ambas piernas, controlando el movimiento.',
    sugerencias:
        'Usar implementos como mancuernas o bandas elásticas para mayor intensidad.',
    categoria: 'RD',
    categoriaNombre: 'Rodilla Dominante',
    dificultad: Dificultad.facil,
  ),
  ExerciseModel(
    id: 'cd-1',
    nombre: 'Puente de glúteo dinámico',
    descripcion:
        'Recostado boca arriba, con piernas flexionadas apoyando las plantas de los pies, elevar la cadera empujando con los pies.',
    sugerencias: 'Usar cajones para variar el rango de ejecución.',
    categoria: 'CD',
    categoriaNombre: 'Cadera Dominante',
    dificultad: Dificultad.facil,
  ),
  ExerciseModel(
    id: 'em-1',
    nombre: 'Empuje de balón medicinal acostado',
    descripcion:
        'Acostado boca arriba, empujar el balón medicinal hacia arriba con ambas manos.',
    sugerencias: 'Controlar la cadencia del movimiento durante la ejecución.',
    categoria: 'EM',
    categoriaNombre: 'Empuje',
    dificultad: Dificultad.facil,
  ),
  ExerciseModel(
    id: 'jl-1',
    nombre: 'Remo al pecho con elástico a dos manos',
    descripcion:
        'De pie, realizar un remo al pecho utilizando una banda elástica con ambas manos.',
    sugerencias: 'Variar la resistencia del elástico según la progresión.',
    categoria: 'JL',
    categoriaNombre: 'Jalón',
    dificultad: Dificultad.facil,
  ),
  ExerciseModel(
    id: 'cr-1',
    nombre: 'Extensiones de tronco a un brazo',
    descripcion:
        'Acostado boca abajo, extender un brazo hacia adelante manteniendo el core activado.',
    sugerencias: 'Controlar la cadencia del movimiento durante la ejecución.',
    categoria: 'CR',
    categoriaNombre: 'Core',
    dificultad: Dificultad.facil,
  ),
  ExerciseModel(
    id: 'rd-2',
    nombre: 'Pararse y sentarse semi unipodal',
    descripcion:
        'Pararse y sentarse de un banco apoyando uno de los pies de forma semi unipodal.',
    categoria: 'RD',
    categoriaNombre: 'Rodilla Dominante',
    dificultad: Dificultad.facil,
  ),
  ExerciseModel(
    id: 'cd-2',
    nombre: 'Puente de glúteo unilateral estático',
    descripcion:
        'Boca arriba, apoyando una sola planta del pie, elevar la cadera empujando con ese pie y llevando la otra pierna al frente.',
    categoria: 'CD',
    categoriaNombre: 'Cadera Dominante',
    dificultad: Dificultad.facil,
  ),
  ExerciseModel(
    id: 'cr-2',
    nombre: 'Bicho muerto',
    descripcion:
        'Acostado boca arriba, extender brazo y pierna contrarios manteniendo el core activado.',
    categoria: 'CR',
    categoriaNombre: 'Core',
    dificultad: Dificultad.facil,
  ),
  ExerciseModel(
    id: 'marcha-rodillas',
    nombre: 'Marcha con rodillas altas',
    descripcion:
        'Elevar las rodillas alternando en el lugar, manteniendo la postura erguida y el core activo.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.facil,
  ),
  ExerciseModel(
    id: 'brazos-extendidos',
    nombre: 'Abrir y cerrar brazos',
    descripcion:
        'De pie, abrir ampliamente los brazos y volver al centro, coordinando con la respiración.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.facil,
  ),
  ExerciseModel(
    id: 'paso-lateral',
    nombre: 'Pasos laterales',
    descripcion:
        'Desplazarse de lado a lado con pasos amplios, manteniendo las rodillas semiflexionadas.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.facil,
  ),
  ExerciseModel(
    id: 'trote-falso',
    nombre: 'Trote en el lugar',
    descripcion:
        'Trotar suave sin desplazarse, elevando ligeramente los talones hacia los glúteos.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.facil,
  ),
  ExerciseModel(
    id: 'rotaciones-corporales',
    nombre: 'Rotaciones corporales',
    descripcion:
        'De pie, rotar el tronco de lado a lado con los brazos sueltos, activando los oblicuos.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.facil,
  ),

  // ============================================================
  // POOL MEDIO
  // ============================================================
  ExerciseModel(
    id: 'rd-3',
    nombre: 'Sentadilla con apoyo (TRX o elástico)',
    descripcion:
        'Realizar sentadilla manteniendo el torso erguido, asistido con TRX o banda elástica.',
    categoria: 'RD',
    categoriaNombre: 'Rodilla Dominante',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'cd-3',
    nombre: 'Puente de glúteo con pies elevados',
    descripcion:
        'Puente de glúteo con los pies apoyados sobre un banco o cajón para mayor activación.',
    categoria: 'CD',
    categoriaNombre: 'Cadera Dominante',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'em-2',
    nombre: 'Empuje de balón medicinal a una mano',
    descripcion:
        'Acostado boca arriba, empujar el balón medicinal con una sola mano.',
    categoria: 'EM',
    categoriaNombre: 'Empuje',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'em-3',
    nombre: 'Empuje de pie con balón medicinal',
    descripcion:
        'De pie, empujar el balón medicinal hacia adelante a la altura del pecho con ambas manos.',
    categoria: 'EM',
    categoriaNombre: 'Empuje',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'jl-2',
    nombre: 'Remo al pecho con elástico a una mano',
    descripcion: 'De pie, realizar un remo al pecho con una sola mano.',
    categoria: 'JL',
    categoriaNombre: 'Jalón',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'jl-3',
    nombre: 'Jalón con elástico desde arriba',
    descripcion:
        'Con el elástico anclado en alto, jalar hacia abajo con ambas manos controlando el movimiento.',
    categoria: 'JL',
    categoriaNombre: 'Jalón',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'cr-3',
    nombre: 'Plancha frontal con apoyo de rodillas',
    descripcion:
        'Mantener posición de plancha frontal apoyado sobre las rodillas, activando el core.',
    categoria: 'CR',
    categoriaNombre: 'Core',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'rd-4',
    nombre: 'Sentadilla libre',
    descripcion:
        'Sentadilla sin asistencia, controlando la profundidad y el equilibrio.',
    categoria: 'RD',
    categoriaNombre: 'Rodilla Dominante',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'cd-4',
    nombre: 'Peso muerto rumano con mancuerna',
    descripcion:
        'De pie, realizar bisagra de cadera con una mancuerna ligera manteniendo la espalda neutra.',
    categoria: 'CD',
    categoriaNombre: 'Cadera Dominante',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'em-4',
    nombre: 'Flexiones de brazos inclinadas',
    descripcion:
        'Realizar flexiones con las manos apoyadas en un banco o superficie elevada.',
    categoria: 'EM',
    categoriaNombre: 'Empuje',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'jl-4',
    nombre: 'Remo con mancuerna a una mano',
    descripcion:
        'Apoyado en un banco, realizar remo con mancuerna a una mano controlando el core.',
    categoria: 'JL',
    categoriaNombre: 'Jalón',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'cr-4',
    nombre: 'Plancha frontal completa',
    descripcion:
        'Mantener posición de plancha frontal completa sobre las puntas de los pies.',
    categoria: 'CR',
    categoriaNombre: 'Core',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'rayuela',
    nombre: 'Rayuela',
    descripcion:
        'Saltar de casilla en casilla alternando uno y dos pies, manteniendo el equilibrio al caer.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'tocar-pies',
    nombre: 'Tocar pies cruzado',
    descripcion:
        'De pie, tocar con la mano el pie contrario alternando lados, con la espalda controlada.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'punos-cruzados',
    nombre: 'Puños cruzados',
    descripcion:
        'Lanzar golpes alternados hacia el lado contrario, rotando el tronco con cada repetición.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'pierna-lateral',
    nombre: 'Levantamiento de pierna lateral',
    descripcion:
        'De pie, elevar una pierna hacia el lado manteniendo el tronco firme, y alternar.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'torsion-abdomen',
    nombre: 'Torsión de abdomen',
    descripcion:
        'Sentado o de pie, rotar el tronco de lado a lado con los brazos al frente.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.medio,
  ),

  // ============================================================
  // POOL DIFÍCIL
  // ============================================================
  ExerciseModel(
    id: 'rd-5',
    nombre: 'Sentadilla goblet con mancuerna',
    descripcion:
        'Sentadilla sosteniendo una mancuerna frente al pecho con ambas manos.',
    categoria: 'RD',
    categoriaNombre: 'Rodilla Dominante',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'cd-5',
    nombre: 'Peso muerto rumano unilateral',
    descripcion:
        'Peso muerto rumano apoyando sobre una sola pierna para mayor exigencia.',
    categoria: 'CD',
    categoriaNombre: 'Cadera Dominante',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'em-5',
    nombre: 'Flexiones de brazos en suelo',
    descripcion: 'Flexiones completas en el suelo con control del core.',
    categoria: 'EM',
    categoriaNombre: 'Empuje',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'jl-5',
    nombre: 'Dominadas asistidas con elástico',
    descripcion:
        'Realizar dominadas con asistencia de banda elástica controlando la subida y la bajada.',
    categoria: 'JL',
    categoriaNombre: 'Jalón',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'cr-5',
    nombre: 'Plancha lateral con apoyo de rodilla',
    descripcion: 'Plancha lateral apoyando la rodilla inferior para estabilidad.',
    categoria: 'CR',
    categoriaNombre: 'Core',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'rd-6',
    nombre: 'Zancada frontal con mancuernas',
    descripcion:
        'Dar un paso al frente bajando la rodilla trasera, con mancuernas en ambas manos.',
    categoria: 'RD',
    categoriaNombre: 'Rodilla Dominante',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'cd-6',
    nombre: 'Hip thrust con carga',
    descripcion:
        'Apoyando la espalda en un banco, elevar la cadera con carga externa.',
    categoria: 'CD',
    categoriaNombre: 'Cadera Dominante',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'em-6',
    nombre: 'Press de hombros con mancuernas',
    descripcion:
        'Sentado o de pie, empujar las mancuernas desde los hombros hacia arriba.',
    categoria: 'EM',
    categoriaNombre: 'Empuje',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'jl-6',
    nombre: 'Remo invertido en TRX',
    descripcion:
        'Colgarse del TRX inclinado y jalar el cuerpo hacia arriba controlando la espalda.',
    categoria: 'JL',
    categoriaNombre: 'Jalón',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'cr-6',
    nombre: 'Plancha lateral completa',
    descripcion: 'Plancha lateral con piernas extendidas y cadera elevada.',
    categoria: 'CR',
    categoriaNombre: 'Core',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'rd-7',
    nombre: 'Sentadilla búlgara',
    descripcion:
        'Sentadilla con el pie trasero elevado en un banco, mayor exigencia unilateral.',
    categoria: 'RD',
    categoriaNombre: 'Rodilla Dominante',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'cd-7',
    nombre: 'Peso muerto sumo con kettlebell',
    descripcion:
        'Peso muerto con piernas separadas y pies hacia afuera, usando kettlebell.',
    categoria: 'CD',
    categoriaNombre: 'Cadera Dominante',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'em-7',
    nombre: 'Flexiones diamante',
    descripcion:
        'Flexiones con las manos juntas formando un diamante, mayor activación de tríceps.',
    categoria: 'EM',
    categoriaNombre: 'Empuje',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'cr-7',
    nombre: 'Rollout con rueda abdominal',
    descripcion:
        'Con rueda abdominal, extender el cuerpo desde las rodillas manteniendo el core activo.',
    categoria: 'CR',
    categoriaNombre: 'Core',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'salto-estrella',
    nombre: 'Salto estrella',
    descripcion:
        'Saltar abriendo brazos y piernas formando una estrella, y volver al centro.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'sentadilla-explosiva',
    nombre: 'Sentadilla explosiva',
    descripcion:
        'Bajar a sentadilla y subir con un salto, aterrizando con las rodillas amortiguadas.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.dificil,
  ),
];
