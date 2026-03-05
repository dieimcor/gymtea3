/// Modelo del niño con perfil motor
class ChildModel {
  final String id;
  final String nombre;
  final int edad;
  final String parentId;
  final String? enrolledBy;
  final CondicionNeurodivergente condicion;
  final ControlMotor controlMotor;
  final int nivelProgresionActual;
  final int nivelProgresionInicial;
  final DateTime createdAt;

  ChildModel({
    required this.id,
    required this.nombre,
    required this.edad,
    required this.parentId,
    this.enrolledBy,
    required this.condicion,
    required this.controlMotor,
    required this.nivelProgresionActual,
    required this.nivelProgresionInicial,
    required this.createdAt,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['id'],
      nombre: json['nombre'],
      edad: json['edad'],
      parentId: json['parent_id'],
      enrolledBy: json['enrolled_by'],
      condicion: CondicionNeurodivergente.values.firstWhere(
        (e) => e.name == json['condicion'],
        orElse: () => CondicionNeurodivergente.otro,
      ),
      controlMotor: ControlMotor.values.firstWhere(
        (e) => e.name == json['control_motor'],
        orElse: () => ControlMotor.bajo,
      ),
      nivelProgresionActual: json['nivel_progresion_actual'] ?? 1,
      nivelProgresionInicial: json['nivel_progresion_inicial'] ?? 1,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'edad': edad,
    'parent_id': parentId,
    'enrolled_by': enrolledBy,
    'condicion': condicion.name,
    'control_motor': controlMotor.name,
    'nivel_progresion_actual': nivelProgresionActual,
    'nivel_progresion_inicial': nivelProgresionInicial,
    'created_at': createdAt.toIso8601String(),
  };
}

enum CondicionNeurodivergente {
  tea,    // Trastorno del Espectro Autista
  tdah,   // Trastorno por Déficit de Atención e Hiperactividad
  tel,    // Trastorno Específico del Lenguaje
  mixto,  // Condición mixta
  otro,
}

enum ControlMotor {
  bajo,     // 5-10 puntos
  moderado, // 11-15 puntos
  alto,     // 16-20 puntos
}
