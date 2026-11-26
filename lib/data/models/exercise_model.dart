import 'package:gymtea3/data/models/difficulty.dart';
import 'package:gymtea3/data/models/equipment.dart';
import 'package:gymtea3/data/models/exercise_media.dart';

/// Modelo de ejercicio con categoría dinámica y dificultad.
///
/// Ya no se ata a un nivel fijo: cada ejercicio pertenece a un *pool* de
/// dificultad y el cráter sortea los suyos desde ahí.
class ExerciseModel {
  final String id;
  final String nombre;
  final String descripcion;

  /// Explicación simplificada en 2-3 pasos cortos, para que el padre la
  /// lea en voz alta mientras el niño se prepara. Si está vacía se usa
  /// [descripcion] (ver [pasosSimples]).
  final List<String> pasos;
  final String? sugerencias;
  final String? variaciones;

  /// Categoría dinámica (String en vez de enum para escalabilidad).
  /// Ejemplos base del manual: 'RD', 'CD', 'EM', 'JL', 'CR'.
  /// Nuevas categorías se agregan desde el backend sin tocar la app.
  final String categoria;

  /// Nombre legible de la categoría (viene del backend).
  /// Ej: 'Rodilla Dominante', 'Equilibrio', 'Flexibilidad'
  final String? categoriaNombre;

  /// Pool de dificultad al que pertenece el ejercicio.
  final Dificultad dificultad;

  /// Qué hace falta para hacerlo (decide en qué rutas aparece).
  final Equipo equipo;

  /// Implemento original del manual (p. ej. "Mancuerna liviana").
  final String? implemento;

  /// Reemplazo seguro con juguetes o cosas de la casa (p. ej. "Botella
  /// de agua chica"). Se muestra en "Así se hace" y en el pop-up.
  final String? reemplazo;

  /// Recurso visual del ejercicio (ilustración, GIF o video).
  ///
  /// `null` mientras el arte definitivo se diseña: la app muestra solo el
  /// espacio reservado (`ExerciseMediaSlot`). Cuando el recurso esté listo
  /// se asigna aquí y aparece en ese mismo espacio.
  final ExerciseMedia? media;

  /// Series y repeticiones personalizables por ejercicio.
  /// Si son null, se usan los valores por defecto de la dificultad.
  final int? series;
  final int? repeticiones;

  ExerciseModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.pasos = const [],
    this.sugerencias,
    this.variaciones,
    required this.categoria,
    this.categoriaNombre,
    required this.dificultad,
    this.equipo = Equipo.libre,
    this.implemento,
    this.reemplazo,
    this.media,
    this.series,
    this.repeticiones,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      pasos: (json['pasos'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      sugerencias: json['sugerencias'],
      variaciones: json['variaciones'],
      categoria: json['categoria'],
      categoriaNombre: json['categoria_nombre'],
      dificultad: Dificultad.fromName(json['dificultad']),
      equipo: Equipo.fromName(json['equipo']),
      implemento: json['implemento'],
      reemplazo: json['reemplazo'],
      media: ExerciseMedia.fromJson(json['media']) ?? _legacyMedia(json),
      series: json['series'],
      repeticiones: json['repeticiones'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'pasos': pasos,
        'sugerencias': sugerencias,
        'variaciones': variaciones,
        'categoria': categoria,
        'categoria_nombre': categoriaNombre,
        'dificultad': dificultad.name,
        'equipo': equipo.name,
        'implemento': implemento,
        'reemplazo': reemplazo,
        'media': media?.toJson(),
        'series': series,
        'repeticiones': repeticiones,
      };

  /// Qué usar en casa: el reemplazo o, si no hay, el implemento original.
  String? get queUsar => reemplazo ?? implemento;

  /// Pasos para mostrar: los simplificados o, si no hay, la descripción.
  List<String> get pasosSimples => pasos.isNotEmpty ? pasos : [descripcion];

  /// Compatibilidad con el formato anterior (`imagen_url` / `imagen_asset`).
  static ExerciseMedia? _legacyMedia(Map<String, dynamic> json) {
    final ruta = json['imagen_url'] ?? json['imagen_asset'];
    if (ruta is! String || ruta.isEmpty) return null;
    return ruta.toLowerCase().endsWith('.gif')
        ? ExerciseMedia.gif(ruta)
        : ExerciseMedia.imagen(ruta);
  }

  /// Para cache SQLite
  Map<String, dynamic> toMap() => toJson();

  factory ExerciseModel.fromMap(Map<String, dynamic> map) =>
      ExerciseModel.fromJson(map);
}
