/// Modelo de ejercicio con categoría y nivel de progresión
class ExerciseModel {
  final String id;
  final String nombre;
  final String descripcion;
  final String? sugerencias;
  final String? variaciones;
  final CategoriaEjercicio categoria;
  final int nivelProgresion; // 1-7
  final FaseSesion tipoFase;
  final String? imagenUrl;

  ExerciseModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.sugerencias,
    this.variaciones,
    required this.categoria,
    required this.nivelProgresion,
    required this.tipoFase,
    this.imagenUrl,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      sugerencias: json['sugerencias'],
      variaciones: json['variaciones'],
      categoria: CategoriaEjercicio.values.firstWhere(
        (e) => e.name == json['categoria'],
      ),
      nivelProgresion: json['nivel_progresion'],
      tipoFase: FaseSesion.values.firstWhere(
        (e) => e.name == json['tipo_fase'],
      ),
      imagenUrl: json['imagen_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
    'sugerencias': sugerencias,
    'variaciones': variaciones,
    'categoria': categoria.name,
    'nivel_progresion': nivelProgresion,
    'tipo_fase': tipoFase.name,
    'imagen_url': imagenUrl,
  };

  /// Para cache SQLite
  Map<String, dynamic> toMap() => toJson();

  factory ExerciseModel.fromMap(Map<String, dynamic> map) =>
      ExerciseModel.fromJson(map);
}

/// Categorías de ejercicios del Manual
enum CategoriaEjercicio {
  rd, // Rodilla Dominante
  cd, // Cadera Dominante
  em, // Empuje
  jl, // Jalón
  cr, // Core
}

/// Fases de una sesión de ejercicios
enum FaseSesion {
  activacion,       // Activación neuromuscular (2 min)
  fortalecimiento,  // Fortalecimiento (8 min)
  juego,            // Juego/circuito (5 min)
}
