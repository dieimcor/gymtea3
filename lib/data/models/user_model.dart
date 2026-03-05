/// Modelo de usuario (Padre)
class UserModel {
  final String id;
  final String rut;
  final String nombre;
  final String email;
  final String rol; // PADRE, PSICOPEDAGOGO, TO, ADMIN
  final String? childId;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.rut,
    required this.nombre,
    required this.email,
    required this.rol,
    this.childId,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      rut: json['rut'],
      nombre: json['nombre'],
      email: json['email'],
      rol: json['rol'],
      childId: json['child_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'rut': rut,
    'nombre': nombre,
    'email': email,
    'rol': rol,
    'child_id': childId,
    'created_at': createdAt.toIso8601String(),
  };
}
