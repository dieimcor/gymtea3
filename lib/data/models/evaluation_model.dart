import 'package:gymtea3/data/models/child_model.dart';

/// Modelo de evaluación funcional (Rúbrica del Manual de Fuerza y Juegos)
class EvaluationModel {
  final String id;
  final String childId;
  final String evaluatorId;
  final int sentadillaArranque;   // 1-4
  final int bisagraCadera;        // 1-4
  final int lanzamientoBalon;     // 1-4
  final int arrasreCorebag;       // 1-4
  final int superman;             // 1-4
  final int puntajeTotal;         // 5-20
  final ControlMotor clasificacion;
  final int nivelInicialCalculado; // 1-7 (automático)
  final int nivelAsignado;         // 1-7 (ajustable por psicopedagogo)
  final String? observaciones;
  final DateTime fecha;

  EvaluationModel({
    required this.id,
    required this.childId,
    required this.evaluatorId,
    required this.sentadillaArranque,
    required this.bisagraCadera,
    required this.lanzamientoBalon,
    required this.arrasreCorebag,
    required this.superman,
    required this.puntajeTotal,
    required this.clasificacion,
    required this.nivelInicialCalculado,
    required this.nivelAsignado,
    this.observaciones,
    required this.fecha,
  });

  /// Calcula el puntaje total desde los 5 ejercicios
  static int calcularPuntajeTotal({
    required int sentadilla,
    required int bisagra,
    required int lanzamiento,
    required int arrastre,
    required int superman,
  }) {
    return sentadilla + bisagra + lanzamiento + arrastre + superman;
  }

  /// Clasifica el control motor según el puntaje total
  static ControlMotor clasificarControlMotor(int puntajeTotal) {
    if (puntajeTotal <= 10) return ControlMotor.bajo;
    if (puntajeTotal <= 15) return ControlMotor.moderado;
    return ControlMotor.alto;
  }

  /// Calcula el nivel de progresión inicial (1-7)
  /// Promedio de puntaje se redondea al entero más cercano
  /// Si es alto control (16-20), se suma +1 al promedio
  static int calcularNivelProgresion(int puntajeTotal) {
    double promedio = puntajeTotal / 5;
    int nivel = promedio.round();

    // Bonus +1 para alto control motor
    if (puntajeTotal >= 16) {
      nivel = (promedio + 1).round();
    }

    // Clamp entre 1 y 7
    return nivel.clamp(1, 7);
  }

  factory EvaluationModel.fromJson(Map<String, dynamic> json) {
    return EvaluationModel(
      id: json['id'],
      childId: json['child_id'],
      evaluatorId: json['evaluator_id'],
      sentadillaArranque: json['sentadilla_arranque'],
      bisagraCadera: json['bisagra_cadera'],
      lanzamientoBalon: json['lanzamiento_balon'],
      arrasreCorebag: json['arrastre_corebag'],
      superman: json['superman'],
      puntajeTotal: json['puntaje_total'],
      clasificacion: ControlMotor.values.firstWhere(
        (e) => e.name == json['clasificacion'],
      ),
      nivelInicialCalculado: json['nivel_inicial_calculado'],
      nivelAsignado: json['nivel_asignado'],
      observaciones: json['observaciones'],
      fecha: DateTime.parse(json['fecha']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'child_id': childId,
    'evaluator_id': evaluatorId,
    'sentadilla_arranque': sentadillaArranque,
    'bisagra_cadera': bisagraCadera,
    'lanzamiento_balon': lanzamientoBalon,
    'arrastre_corebag': arrasreCorebag,
    'superman': superman,
    'puntaje_total': puntajeTotal,
    'clasificacion': clasificacion.name,
    'nivel_inicial_calculado': nivelInicialCalculado,
    'nivel_asignado': nivelAsignado,
    'observaciones': observaciones,
    'fecha': fecha.toIso8601String(),
  };
}
