/// Modelo de progreso por rutina completada
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

  /// "¿Cómo le fue?" por ejercicio: id del ejercicio → 1 a 3 estrellas
  /// (ver [ExerciseRating]). Los ejercicios que el padre no valoró no
  /// aparecen en el mapa.
  final Map<String, int> calificaciones;

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
    this.calificaciones = const {},
  });

  /// `true` si el padre valoró al menos un ejercicio.
  bool get tieneCalificacion => calificaciones.isNotEmpty;

  /// Promedio de estrellas de la rutina (null si no hay valoraciones).
  double? get promedioCalificacion {
    if (calificaciones.isEmpty) return null;
    final total = calificaciones.values.fold<int>(0, (a, b) => a + b);
    return total / calificaciones.length;
  }

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      id: json['id'],
      childId: json['child_id'],
      sessionId: json['session_id'],
      nivelCompletado: json['nivel_completado'],
      ejerciciosCompletadosIds: _parseIds(json['ejercicios_completados_ids']),
      tiempoRealSeg: json['tiempo_real_seg'],
      observaciones: json['observaciones'],
      fecha: DateTime.parse(json['fecha']),
      sincronizado: _parseBool(json['sincronizado']),
      calificaciones: _parseCalificaciones(json['calificaciones']),
    );
  }

  /// Acepta la lista de [toJson] o el texto "a,b,c" de [toMap].
  static List<String> _parseIds(Object? raw) {
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String && raw.isNotEmpty) return raw.split(',');
    return const [];
  }

  /// SQLite guarda los bool como 0/1.
  static bool _parseBool(Object? raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    return false;
  }

  /// Acepta el mapa de [toJson] o el texto "id:3,id2:1" de [toMap].
  static Map<String, int> _parseCalificaciones(Object? raw) {
    if (raw is Map) {
      final result = <String, int>{};
      raw.forEach((k, v) {
        final stars = v is num ? v.toInt() : int.tryParse('$v');
        if (stars != null) result[k.toString()] = stars;
      });
      return result;
    }
    if (raw is String && raw.isNotEmpty) {
      final result = <String, int>{};
      for (final pair in raw.split(',')) {
        // El id puede traer ':'; las estrellas van siempre al final.
        final sep = pair.lastIndexOf(':');
        if (sep <= 0) continue;
        final stars = int.tryParse(pair.substring(sep + 1));
        if (stars != null) result[pair.substring(0, sep)] = stars;
      }
      return result;
    }
    return const {};
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
        'calificaciones': calificaciones,
      };

  /// Para cache SQLite
  Map<String, dynamic> toMap() => {
        ...toJson(),
        'ejercicios_completados_ids': ejerciciosCompletadosIds.join(','),
        'calificaciones':
            calificaciones.entries.map((e) => '${e.key}:${e.value}').join(','),
      };
}
