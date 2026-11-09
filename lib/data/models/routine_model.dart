import 'package:gymtea3/core/constants/app_constants.dart';
import 'package:gymtea3/data/models/difficulty.dart';
import 'package:gymtea3/data/models/exercise_model.dart';

/// Rutina de un cráter: lista plana de ejercicios sorteados.
///
/// Reemplaza al antiguo `SessionModel` de 3 fases. La estructura es
/// siempre la misma: N ejercicios × 2 series × 60s, con descansos
/// incrementales según la dificultad del cráter.
class RoutineModel {
  final String id;
  final String childId;

  /// Nivel / número de cráter.
  final int nivel;

  final Dificultad dificultad;
  final List<ExerciseModel> ejercicios;
  final DateTime fecha;

  RoutineModel({
    required this.id,
    required this.childId,
    required this.nivel,
    required this.dificultad,
    required this.ejercicios,
    required this.fecha,
  });

  int get series => dificultad.series;
  int get restSeconds => dificultad.restSeconds;
  int get exerciseSeconds => AppConstants.exerciseSeconds;

  /// Total de bloques de trabajo (ejercicio × serie).
  int get totalBlocks => ejercicios.length * series;

  /// Duración estimada en segundos, incluyendo descansos.
  int get estimatedSeconds {
    final work = totalBlocks * exerciseSeconds;
    final rests = (totalBlocks - 1) * restSeconds;
    return work + rests;
  }

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    return RoutineModel(
      id: json['id'],
      childId: json['child_id'],
      nivel: json['nivel'],
      dificultad: Dificultad.fromName(json['dificultad']),
      ejercicios: (json['ejercicios'] as List)
          .map((e) => ExerciseModel.fromJson(e))
          .toList(),
      fecha: DateTime.parse(json['fecha']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'child_id': childId,
        'nivel': nivel,
        'dificultad': dificultad.name,
        'ejercicios': ejercicios.map((e) => e.toJson()).toList(),
        'fecha': fecha.toIso8601String(),
      };
}
