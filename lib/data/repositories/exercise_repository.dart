import 'dart:math';

import 'package:gymtea3/data/models/difficulty.dart';
import 'package:gymtea3/data/models/equipment.dart';
import 'package:gymtea3/data/models/exercise_model.dart';
import 'package:gymtea3/data/models/training_route.dart';

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

  /// Pool de una dificultad.
  ///
  /// Con [route], solo entran los ejercicios cuyo equipo cabe en la ruta.
  /// Si así quedan menos de [minSize], se completa con ejercicios
  /// permitidos de las dificultades vecinas (primero las más fáciles),
  /// para que la rutina siempre salga completa y sin repetir dentro de
  /// ella.
  Future<List<ExerciseModel>> getPool(
    Dificultad dificultad, {
    TrainingRoute? route,
    int minSize = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return poolFor(dificultad, route: route, minSize: minSize);
  }

  /// Versión síncrona de [getPool] (lógica pura, usada también en tests).
  List<ExerciseModel> poolFor(
    Dificultad dificultad, {
    TrainingRoute? route,
    int minSize = 0,
  }) {
    bool allowed(ExerciseModel e) =>
        route == null || e.equipo.fitsIn(route.maxEquipo);

    final pool = _mockExercises
        .where((e) => e.dificultad == dificultad && allowed(e))
        .toList();
    if (pool.length >= minSize) return pool;

    // Vecinas por cercanía; ante empate, la más fácil primero.
    final neighbors = Dificultad.values.where((d) => d != dificultad).toList()
      ..sort((a, b) {
        final da = (a.index - dificultad.index).abs();
        final db = (b.index - dificultad.index).abs();
        return da != db ? da.compareTo(db) : a.index.compareTo(b.index);
      });
    for (final d in neighbors) {
      for (final e in _mockExercises) {
        if (pool.length >= minSize) return pool;
        if (e.dificultad == d && allowed(e)) pool.add(e);
      }
    }
    return pool;
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
    TrainingRoute? route,
  }) async {
    final pool = await getPool(dificultad, route: route, minSize: count);

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
// Ningun ejercicio tiene recurso visual todavia: las graficas, GIFs y
// videos se estan disenando, asi que todos muestran solo el espacio
// reservado (ExerciseMediaSlot). Cuando un recurso este listo se agrega
// al ejercicio con `media:`, por ejemplo:
//   media: ExerciseMedia.gif('assets/images/ejercicios/rd-1.gif'),
// ============================================================

final List<ExerciseModel> _mockExercises = [
  // ============================================================
  // POOL FÁCIL
  // ============================================================
  ExerciseModel(
    id: 'rd-1',
    equipo: Equipo.libre,
    implemento: 'Banco',
    reemplazo: 'Silla firme',
    pasos: ['Siéntate en el banco', 'Párate sin usar las manos', 'Vuelve a sentarte despacito'],
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
    pasos: ['Acuéstate de espalda con las rodillas dobladas', 'Empuja con los pies y sube la cola', 'Bájala despacio'],
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
    equipo: Equipo.basico,
    implemento: 'Balón medicinal',
    reemplazo: 'Pelota o cojín',
    pasos: ['Acuéstate de espalda con el balón en el pecho', 'Empújalo hacia el techo con las dos manos', 'Bájalo despacio'],
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
    equipo: Equipo.basico,
    implemento: 'Elástico',
    reemplazo: 'Toalla: tú tiras del otro extremo',
    pasos: ['Toma el elástico con las dos manos', 'Tíralo hacia tu pecho', 'Suelta despacio'],
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
    pasos: ['Acuéstate boca abajo', 'Estira un brazo hacia adelante', 'Cambia de brazo'],
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
    equipo: Equipo.libre,
    implemento: 'Banco',
    reemplazo: 'Silla firme',
    pasos: ['Siéntate con un pie un poquito adelante', 'Párate empujando con el pie de atrás', 'Siéntate despacio'],
    nombre: 'Pararse y sentarse semi unipodal',
    descripcion:
        'Pararse y sentarse de un banco apoyando uno de los pies de forma semi unipodal.',
    categoria: 'RD',
    categoriaNombre: 'Rodilla Dominante',
    dificultad: Dificultad.facil,
  ),
  ExerciseModel(
    id: 'cd-2',
    pasos: ['Acuéstate de espalda, un pie en el suelo', 'Estira la otra pierna', 'Sube y baja la cola'],
    nombre: 'Puente de glúteo unilateral estático',
    descripcion:
        'Boca arriba, apoyando una sola planta del pie, elevar la cadera empujando con ese pie y llevando la otra pierna al frente.',
    categoria: 'CD',
    categoriaNombre: 'Cadera Dominante',
    dificultad: Dificultad.facil,
  ),
  ExerciseModel(
    id: 'cr-2',
    pasos: ['Acuéstate de espalda, brazos y piernas arriba', 'Estira un brazo y la pierna contraria', 'Vuelve y cambia de lado'],
    nombre: 'Bicho muerto',
    descripcion:
        'Acostado boca arriba, extender brazo y pierna contrarios manteniendo el core activado.',
    categoria: 'CR',
    categoriaNombre: 'Core',
    dificultad: Dificultad.facil,
  ),
  ExerciseModel(
    id: 'marcha-rodillas',
    pasos: ['Párate derechito', 'Sube una rodilla bien alto', 'Cambia de pierna, como marchando'],
    nombre: 'Marcha con rodillas altas',
    descripcion:
        'Elevar las rodillas alternando en el lugar, manteniendo la postura erguida y el core activo.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.facil,
  ),
  ExerciseModel(
    id: 'brazos-extendidos',
    pasos: ['Párate derechito', 'Abre los brazos bien grande', 'Ciérralos al frente'],
    nombre: 'Abrir y cerrar brazos',
    descripcion:
        'De pie, abrir ampliamente los brazos y volver al centro, coordinando con la respiración.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.facil,
  ),
  ExerciseModel(
    id: 'paso-lateral',
    pasos: ['Dobla un poquito las rodillas', 'Da pasos largos hacia un lado', 'Vuelve hacia el otro lado'],
    nombre: 'Pasos laterales',
    descripcion:
        'Desplazarse de lado a lado con pasos amplios, manteniendo las rodillas semiflexionadas.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.facil,
  ),
  ExerciseModel(
    id: 'trote-falso',
    pasos: ['Trota sin moverte de tu lugar', 'Lleva los talones hacia la cola'],
    nombre: 'Trote en el lugar',
    descripcion:
        'Trotar suave sin desplazarse, elevando ligeramente los talones hacia los glúteos.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.facil,
  ),
  ExerciseModel(
    id: 'rotaciones-corporales',
    pasos: ['Párate con los brazos sueltos', 'Gira el cuerpo hacia un lado', 'Gira hacia el otro lado'],
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
    equipo: Equipo.libre,
    implemento: 'TRX o elástico',
    reemplazo: 'Tus manos: afírmalo de las manos',
    pasos: ['Toma el elástico con las manos', 'Baja como si te sentaras', 'Sube con la espalda derecha'],
    nombre: 'Sentadilla con apoyo (TRX o elástico)',
    descripcion:
        'Realizar sentadilla manteniendo el torso erguido, asistido con TRX o banda elástica.',
    categoria: 'RD',
    categoriaNombre: 'Rodilla Dominante',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'cd-3',
    equipo: Equipo.libre,
    implemento: 'Banco o cajón',
    reemplazo: 'Sofá o silla firme',
    pasos: ['Acuéstate con los pies arriba del banco', 'Empuja y sube la cola', 'Bájala despacio'],
    nombre: 'Puente de glúteo con pies elevados',
    descripcion:
        'Puente de glúteo con los pies apoyados sobre un banco o cajón para mayor activación.',
    categoria: 'CD',
    categoriaNombre: 'Cadera Dominante',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'em-2',
    equipo: Equipo.basico,
    implemento: 'Balón medicinal',
    reemplazo: 'Pelota chica',
    pasos: ['Acuéstate de espalda con el balón en una mano', 'Empújalo hacia el techo', 'Cambia de mano'],
    nombre: 'Empuje de balón medicinal a una mano',
    descripcion:
        'Acostado boca arriba, empujar el balón medicinal con una sola mano.',
    categoria: 'EM',
    categoriaNombre: 'Empuje',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'em-3',
    equipo: Equipo.basico,
    implemento: 'Balón medicinal',
    reemplazo: 'Pelota o cojín',
    pasos: ['Párate con el balón en el pecho', 'Empújalo hacia adelante', 'Tráelo de vuelta'],
    nombre: 'Empuje de pie con balón medicinal',
    descripcion:
        'De pie, empujar el balón medicinal hacia adelante a la altura del pecho con ambas manos.',
    categoria: 'EM',
    categoriaNombre: 'Empuje',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'jl-2',
    equipo: Equipo.basico,
    implemento: 'Elástico',
    reemplazo: 'Toalla: tú tiras del otro extremo',
    pasos: ['Toma el elástico con una mano', 'Tíralo hacia tu pecho', 'Cambia de mano'],
    nombre: 'Remo al pecho con elástico a una mano',
    descripcion: 'De pie, realizar un remo al pecho con una sola mano.',
    categoria: 'JL',
    categoriaNombre: 'Jalón',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'jl-3',
    equipo: Equipo.basico,
    implemento: 'Elástico anclado arriba',
    reemplazo: 'Toalla: tú la sostienes en alto',
    pasos: ['Toma el elástico que cuelga de arriba', 'Tíralo hacia abajo con las dos manos', 'Suelta despacio'],
    nombre: 'Jalón con elástico desde arriba',
    descripcion:
        'Con el elástico anclado en alto, jalar hacia abajo con ambas manos controlando el movimiento.',
    categoria: 'JL',
    categoriaNombre: 'Jalón',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'cr-3',
    pasos: ['Apoya las manos y las rodillas', 'Pon el cuerpo derecho como una tabla', 'Aguanta sin moverte'],
    nombre: 'Plancha frontal con apoyo de rodillas',
    descripcion:
        'Mantener posición de plancha frontal apoyado sobre las rodillas, activando el core.',
    categoria: 'CR',
    categoriaNombre: 'Core',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'rd-4',
    pasos: ['Párate con los pies separados', 'Baja como si te sentaras en una silla', 'Sube despacio'],
    nombre: 'Sentadilla libre',
    descripcion:
        'Sentadilla sin asistencia, controlando la profundidad y el equilibrio.',
    categoria: 'RD',
    categoriaNombre: 'Rodilla Dominante',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'cd-4',
    equipo: Equipo.basico,
    implemento: 'Mancuerna liviana',
    reemplazo: 'Botella de agua chica',
    pasos: ['Párate con la pesa en las manos', 'Inclínate hacia adelante con la espalda derecha', 'Vuelve a subir'],
    nombre: 'Peso muerto rumano con mancuerna',
    descripcion:
        'De pie, realizar bisagra de cadera con una mancuerna ligera manteniendo la espalda neutra.',
    categoria: 'CD',
    categoriaNombre: 'Cadera Dominante',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'em-4',
    equipo: Equipo.libre,
    implemento: 'Banco',
    reemplazo: 'Sofá o mesa firme',
    pasos: ['Apoya las manos en el banco', 'Baja el pecho hacia el banco', 'Empuja para volver'],
    nombre: 'Flexiones de brazos inclinadas',
    descripcion:
        'Realizar flexiones con las manos apoyadas en un banco o superficie elevada.',
    categoria: 'EM',
    categoriaNombre: 'Empuje',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'jl-4',
    equipo: Equipo.basico,
    implemento: 'Mancuerna y banco',
    reemplazo: 'Botella de agua chica y una silla',
    pasos: ['Apoya una mano y una rodilla en el banco', 'Sube la pesa hacia tu cintura', 'Bájala despacio'],
    nombre: 'Remo con mancuerna a una mano',
    descripcion:
        'Apoyado en un banco, realizar remo con mancuerna a una mano controlando el core.',
    categoria: 'JL',
    categoriaNombre: 'Jalón',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'cr-4',
    pasos: ['Apoya las manos y las puntas de los pies', 'Pon el cuerpo derecho como una tabla', 'Aguanta sin moverte'],
    nombre: 'Plancha frontal completa',
    descripcion:
        'Mantener posición de plancha frontal completa sobre las puntas de los pies.',
    categoria: 'CR',
    categoriaNombre: 'Core',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'rayuela',
    equipo: Equipo.libre,
    implemento: 'Casillas en el suelo',
    reemplazo: 'Cojines o cinta en el suelo',
    pasos: ['Salta en un pie', 'Luego salta con los dos pies', 'Sigue alternando sin caerte'],
    nombre: 'Rayuela',
    descripcion:
        'Saltar de casilla en casilla alternando uno y dos pies, manteniendo el equilibrio al caer.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'tocar-pies',
    pasos: ['Párate con las piernas separadas', 'Toca tu pie con la mano del otro lado', 'Cambia de lado'],
    nombre: 'Tocar pies cruzado',
    descripcion:
        'De pie, tocar con la mano el pie contrario alternando lados, con la espalda controlada.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'punos-cruzados',
    pasos: ['Pon los puños frente a la cara', 'Lanza un golpe hacia el otro lado', 'Cambia de mano'],
    nombre: 'Puños cruzados',
    descripcion:
        'Lanzar golpes alternados hacia el lado contrario, rotando el tronco con cada repetición.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'pierna-lateral',
    pasos: ['Párate derechito', 'Sube una pierna hacia el lado', 'Bájala y cambia de pierna'],
    nombre: 'Levantamiento de pierna lateral',
    descripcion:
        'De pie, elevar una pierna hacia el lado manteniendo el tronco firme, y alternar.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.medio,
  ),
  ExerciseModel(
    id: 'torsion-abdomen',
    pasos: ['Estira los brazos al frente', 'Gira el cuerpo hacia un lado', 'Gira hacia el otro lado'],
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
    equipo: Equipo.basico,
    implemento: 'Mancuerna',
    reemplazo: 'Peluche grande o botella de agua',
    pasos: ['Abraza la pesa contra tu pecho', 'Baja como si te sentaras', 'Sube despacio'],
    nombre: 'Sentadilla goblet con mancuerna',
    descripcion:
        'Sentadilla sosteniendo una mancuerna frente al pecho con ambas manos.',
    categoria: 'RD',
    categoriaNombre: 'Rodilla Dominante',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'cd-5',
    equipo: Equipo.basico,
    implemento: 'Mancuerna liviana',
    reemplazo: 'Botella de agua chica',
    pasos: ['Párate en un pie con la pesa en la mano', 'Inclínate hacia adelante con la espalda derecha', 'Vuelve a subir'],
    nombre: 'Peso muerto rumano unilateral',
    descripcion:
        'Peso muerto rumano apoyando sobre una sola pierna para mayor exigencia.',
    categoria: 'CD',
    categoriaNombre: 'Cadera Dominante',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'em-5',
    pasos: ['Apoya las manos y las puntas de los pies', 'Baja el pecho al suelo', 'Empuja para subir'],
    nombre: 'Flexiones de brazos en suelo',
    descripcion: 'Flexiones completas en el suelo con control del core.',
    categoria: 'EM',
    categoriaNombre: 'Empuje',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'jl-5',
    equipo: Equipo.especial,
    implemento: 'Barra y elástico',
    reemplazo: 'Remo con toalla: tú tiras del otro extremo',
    pasos: ['Cuélgate de la barra con el elástico', 'Sube el pecho hacia la barra', 'Baja despacio'],
    nombre: 'Dominadas asistidas con elástico',
    descripcion:
        'Realizar dominadas con asistencia de banda elástica controlando la subida y la bajada.',
    categoria: 'JL',
    categoriaNombre: 'Jalón',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'cr-5',
    pasos: ['Acuéstate de lado apoyando el codo y la rodilla', 'Sube la cadera', 'Aguanta sin moverte'],
    nombre: 'Plancha lateral con apoyo de rodilla',
    descripcion: 'Plancha lateral apoyando la rodilla inferior para estabilidad.',
    categoria: 'CR',
    categoriaNombre: 'Core',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'rd-6',
    equipo: Equipo.basico,
    implemento: 'Mancuernas',
    reemplazo: 'Dos botellas de agua chicas',
    pasos: ['Párate con una pesa en cada mano', 'Da un paso largo hacia adelante y baja', 'Vuelve y cambia de pierna'],
    nombre: 'Zancada frontal con mancuernas',
    descripcion:
        'Dar un paso al frente bajando la rodilla trasera, con mancuernas en ambas manos.',
    categoria: 'RD',
    categoriaNombre: 'Rodilla Dominante',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'cd-6',
    equipo: Equipo.especial,
    implemento: 'Banco y carga',
    reemplazo: 'Sin carga, con la espalda en el sofá',
    pasos: ['Apoya la espalda en el banco con la pesa en la cadera', 'Sube la cola', 'Bájala despacio'],
    nombre: 'Hip thrust con carga',
    descripcion:
        'Apoyando la espalda en un banco, elevar la cadera con carga externa.',
    categoria: 'CD',
    categoriaNombre: 'Cadera Dominante',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'em-6',
    equipo: Equipo.basico,
    implemento: 'Mancuernas',
    reemplazo: 'Dos botellas de agua chicas',
    pasos: ['Pon las pesas a la altura de los hombros', 'Súbelas hacia el techo', 'Bájalas despacio'],
    nombre: 'Press de hombros con mancuernas',
    descripcion:
        'Sentado o de pie, empujar las mancuernas desde los hombros hacia arriba.',
    categoria: 'EM',
    categoriaNombre: 'Empuje',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'jl-6',
    equipo: Equipo.especial,
    implemento: 'TRX',
    reemplazo: 'Tómalo de las manos y que se incline hacia atrás',
    pasos: ['Toma el TRX y échate hacia atrás', 'Tira para acercar el pecho', 'Vuelve despacio'],
    nombre: 'Remo invertido en TRX',
    descripcion:
        'Colgarse del TRX inclinado y jalar el cuerpo hacia arriba controlando la espalda.',
    categoria: 'JL',
    categoriaNombre: 'Jalón',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'cr-6',
    pasos: ['Acuéstate de lado apoyando el codo y los pies', 'Sube la cadera', 'Aguanta sin moverte'],
    nombre: 'Plancha lateral completa',
    descripcion: 'Plancha lateral con piernas extendidas y cadera elevada.',
    categoria: 'CR',
    categoriaNombre: 'Core',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'rd-7',
    equipo: Equipo.libre,
    implemento: 'Banco',
    reemplazo: 'Silla firme o sofá',
    pasos: ['Pon un pie atrás sobre el banco', 'Baja doblando la pierna de adelante', 'Sube despacio'],
    nombre: 'Sentadilla búlgara',
    descripcion:
        'Sentadilla con el pie trasero elevado en un banco, mayor exigencia unilateral.',
    categoria: 'RD',
    categoriaNombre: 'Rodilla Dominante',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'cd-7',
    equipo: Equipo.especial,
    implemento: 'Kettlebell',
    reemplazo: 'Mochila con 2 o 3 libros livianos',
    pasos: ['Abre bien las piernas con la pesa al medio', 'Baja con la espalda derecha', 'Sube apretando la cola'],
    nombre: 'Peso muerto sumo con kettlebell',
    descripcion:
        'Peso muerto con piernas separadas y pies hacia afuera, usando kettlebell.',
    categoria: 'CD',
    categoriaNombre: 'Cadera Dominante',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'em-7',
    pasos: ['Junta las manos en el suelo formando un diamante', 'Baja el pecho', 'Empuja para subir'],
    nombre: 'Flexiones diamante',
    descripcion:
        'Flexiones con las manos juntas formando un diamante, mayor activación de tríceps.',
    categoria: 'EM',
    categoriaNombre: 'Empuje',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'cr-7',
    equipo: Equipo.especial,
    implemento: 'Rueda abdominal',
    reemplazo: 'Toalla bajo las manos en piso liso',
    pasos: ['Ponte de rodillas con la rueda al frente', 'Rueda hacia adelante con el cuerpo firme', 'Vuelve despacio'],
    nombre: 'Rollout con rueda abdominal',
    descripcion:
        'Con rueda abdominal, extender el cuerpo desde las rodillas manteniendo el core activo.',
    categoria: 'CR',
    categoriaNombre: 'Core',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'salto-estrella',
    pasos: ['Salta abriendo brazos y piernas', 'Salta cerrándolos', '¡Como una estrella!'],
    nombre: 'Salto estrella',
    descripcion:
        'Saltar abriendo brazos y piernas formando una estrella, y volver al centro.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.dificil,
  ),
  ExerciseModel(
    id: 'sentadilla-explosiva',
    pasos: ['Baja como si te sentaras', 'Sube con un gran salto', 'Cae suave doblando las rodillas'],
    nombre: 'Sentadilla explosiva',
    descripcion:
        'Bajar a sentadilla y subir con un salto, aterrizando con las rodillas amortiguadas.',
    categoria: 'MOV',
    categoriaNombre: 'Movilidad y Juego',
    dificultad: Dificultad.dificil,
  ),
];
