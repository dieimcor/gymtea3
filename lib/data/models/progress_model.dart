/// Modelo de progreso por sesión
class ProgressModel {
  final String id;
  final String childId;
  final String sessionId;
  final int nivelCompletado;
  final List<String> ejerciciosCompletadosIds;
  final int tiempoRealSeg;
  final String? observaciones;
  final DateTime fecha;
  final bool sincronizado;

  ProgressModel({
    required this.id,
    required this.childId,
    required this.sessionId,
    required this.nivelCompletado,
    required this.ejerciciosCompletadosIds,
    required this.tiempoRealSeg,
    this.observaciones,
    required this.fecha,
    this.sincronizado = false,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      id: json['id'],
      childId: json['child_id'],
      sessionId: json['session_id'],
      nivelCompletado: json['nivel_completado'],
      ejerciciosCompletadosIds: List<String>.from(json['ejercicios_completados_ids']),
      tiempoRealSeg: json['tiempo_real_seg'],
      observaciones: json['observaciones'],
      fecha: DateTime.parse(json['fecha']),
      sincronizado: json['sincronizado'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'child_id': childId,
    'session_id': sessionId,
    'nivel_completado': nivelCompletado,
    'ejercicios_completados_ids': ejerciciosCompletadosIds,
    'tiempo_real_seg': tiempoRealSeg,
    'observaciones': observaciones,
    'fecha': fecha.toIso8601String(),
    'sincronizado': sincronizado,
  };

  /// Para cache SQLite
  Map<String, dynamic> toMap() => {
    ...toJson(),
    'ejercicios_completados_ids': ejerciciosCompletadosIds.join(','),
  };
}
