/// Modelo de ejercicio con categoría dinámica y nivel de progresión escalable
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

  /// Nivel de progresión sin límite fijo (escalable).
  /// El manual base define 1-7, pero puede crecer según el desarrollo del niño.
  final int nivelProgresion;

  final FaseSesion tipoFase;
  final String? imagenUrl;

  /// Series y repeticiones personalizables por ejercicio.
  /// Si son null, se usan los valores por defecto de AppConstants.
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
    required this.nivelProgresion,
    required this.tipoFase,
    this.imagenUrl,
    this.series,
    this.repeticiones,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      sugerencias: json['sugerencias'],
      variaciones: json['variaciones'],
      categoria: json['categoria'],
      categoriaNombre: json['categoria_nombre'],
      nivelProgresion: json['nivel_progresion'],
      tipoFase: FaseSesion.values.firstWhere(
        (e) => e.name == json['tipo_fase'],
        orElse: () => FaseSesion.fortalecimiento,
      ),
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
    'nivel_progresion': nivelProgresion,
    'tipo_fase': tipoFase.name,
    'imagen_url': imagenUrl,
    'series': series,
    'repeticiones': repeticiones,
  };

  /// Para cache SQLite
  Map<String, dynamic> toMap() => toJson();

  factory ExerciseModel.fromMap(Map<String, dynamic> map) =>
      ExerciseModel.fromJson(map);
}

/// Fases de una sesión de ejercicios
/// (se mantiene como enum porque son fijas por diseño de sesión)
enum FaseSesion {
  activacion,       // Activación neuromuscular (2 min)
  fortalecimiento,  // Fortalecimiento (8 min)
  juego,            // Juego/circuito (5 min)
}
