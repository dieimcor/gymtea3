import 'package:gymtea3/data/models/user_model.dart';

/// Servicio de autenticación (mock por ahora, preparado para backend)
class AuthService {
  // TODO: Inyectar ApiClient cuando el backend esté listo
  // final ApiClient _apiClient;

  /// Login mock — en producción usará POST /auth/login
  Future<Map<String, dynamic>> login(String rut, String password) async {
    // Simular delay de red
    await Future.delayed(const Duration(seconds: 1));

    // Mock: cualquier RUT válido con password "1234" funciona
    if (password == '1234') {
      return {
        'token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
        'user': UserModel(
          id: 'mock-user-001',
          rut: rut,
          nombre: 'Padre Demo',
          email: 'demo@neurogym.cl',
          rol: 'PADRE',
          childId: 'mock-child-001',
          createdAt: DateTime.now(),
        ).toJson(),
      };
    }

    throw Exception('RUT o contraseña incorrectos');
  }

  /// Verificar si el token actual es válido
  Future<bool> verifyToken(String token) async {
    // Mock: siempre válido
    await Future.delayed(const Duration(milliseconds: 500));
    return token.isNotEmpty;
  }

  /// Logout
  Future<void> logout() async {
    // Mock: no-op
    // En producción: POST /auth/logout para invalidar token
  }
}
