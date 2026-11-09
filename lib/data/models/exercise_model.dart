import 'package:gymtea3/data/models/difficulty.dart';

/// Modelo de ejercicio con categoría dinámica y dificultad.
///
/// Ya no se ata a un nivel fijo: cada ejercicio pertenece a un *pool* de
/// dificultad y el cráter sortea los suyos desde ahí.
class ExerciseModel {
  final String id;
  final String nombre;
  final String descripcion;
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

  /// Asset local de la ilustración del ejercicio.
  ///
  /// Convención: `assets/images/ejercicios/<slug>.png`.
  /// Si el archivo todavía no existe, la tarjeta muestra un placeholder con
  /// el nombre del ejercicio — basta dejar caer el PNG con ese nombre para
  /// que aparezca, sin tocar código.
  final String imagenAsset;

  /// URL remota de la imagen (Sprint 4+, tiene prioridad sobre el asset).
  final String? imagenUrl;

  /// Series y repeticiones personalizables por ejercicio.
  /// Si son null, se usan los valores por defecto de la dificultad.
  final int? series;
  final int? repeticiones;

  ExerciseModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.sugerencias,
    this.variaciones,
    required this.categoria,
    this.categoriaNombre,
    required this.dificultad,
    String? imagenAsset,
    this.imagenUrl,
    this.series,
    this.repeticiones,
  }) : imagenAsset = imagenAsset ?? 'assets/images/ejercicios/$id.png';

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      sugerencias: json['sugerencias'],
      variaciones: json['variaciones'],
      categoria: json['categoria'],
      categoriaNombre: json['categoria_nombre'],
      dificultad: Dificultad.fromName(json['dificultad']),
      imagenAsset: json['imagen_asset'],
      imagenUrl: json['imagen_url'],
      series: json['series'],
      repeticiones: json['repeticiones'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'sugerencias': sugerencias,
        'variaciones': variaciones,
        'categoria': categoria,
        'categoria_nombre': categoriaNombre,
        'dificultad': dificultad.name,
        'imagen_asset': imagenAsset,
        'imagen_url': imagenUrl,
        'series': series,
        'repeticiones': repeticiones,
      };

  /// Para cache SQLite
  Map<String, dynamic> toMap() => toJson();

  factory ExerciseModel.fromMap(Map<String, dynamic> map) =>
      ExerciseModel.fromJson(map);
}
