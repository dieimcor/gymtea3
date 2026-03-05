import 'package:gymtea3/data/models/exercise_model.dart';

/// Modelo de sesión de ejercicios (15 min = 3 fases)
class SessionModel {
  final String id;
  final String childId;
  final int nivel; // 1-7
  final List<ExerciseModel> ejerciciosActivacion;
  final List<ExerciseModel> ejerciciosFortalecimiento; // 5: uno por categoría
  final ExerciseModel? juego;
  final int duracionTotalSeg;
  final DateTime fecha;
  final bool completada;
  final int tiempoRealSeg;
  final String? observacionesPadre;
  final bool sincronizado;

  SessionModel({
    required this.id,
    required this.childId,
    required this.nivel,
    required this.ejerciciosActivacion,
    required this.ejerciciosFortalecimiento,
    this.juego,
    this.duracionTotalSeg = 900, // 15 min por defecto
    required this.fecha,
    this.completada = false,
    this.tiempoRealSeg = 0,
    this.observacionesPadre,
    this.sincronizado = false,
  });

  /// Series y repeticiones por defecto según el Manual
  static const int activacionSeries = 2;
  static const int activacionReps = 15;
  static const int fortalecimientoSeries = 3;
  static const int fortalecimientoReps = 10;

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'],
      childId: json['child_id'],
      nivel: json['nivel'],
      ejerciciosActivacion: (json['ejercicios_activacion'] as List)
          .map((e) => ExerciseModel.fromJson(e))
          .toList(),
      ejerciciosFortalecimiento: (json['ejercicios_fortalecimiento'] as List)
          .map((e) => ExerciseModel.fromJson(e))
          .toList(),
      juego: json['juego'] != null ? ExerciseModel.fromJson(json['juego']) : null,
      duracionTotalSeg: json['duracion_total_seg'] ?? 900,
      fecha: DateTime.parse(json['fecha']),
      completada: json['completada'] ?? false,
      tiempoRealSeg: json['tiempo_real_seg'] ?? 0,
      observacionesPadre: json['observaciones_padre'],
      sincronizado: json['sincronizado'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'child_id': childId,
    'nivel': nivel,
    'ejercicios_activacion': ejerciciosActivacion.map((e) => e.toJson()).toList(),
    'ejercicios_fortalecimiento': ejerciciosFortalecimiento.map((e) => e.toJson()).toList(),
    'juego': juego?.toJson(),
    'duracion_total_seg': duracionTotalSeg,
    'fecha': fecha.toIso8601String(),
    'completada': completada,
    'tiempo_real_seg': tiempoRealSeg,
    'observaciones_padre': observacionesPadre,
    'sincronizado': sincronizado,
  };
}
