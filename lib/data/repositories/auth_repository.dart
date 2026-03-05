import 'package:gymtea3/data/models/user_model.dart';
import 'package:gymtea3/data/services/auth_service.dart';
import 'package:gymtea3/data/services/storage_service.dart';

/// Repositorio de autenticación — gestiona login/logout y persistencia del token
class AuthRepository {
  final AuthService _authService;
  final StorageService _storageService;

  AuthRepository({
    required AuthService authService,
    required StorageService storageService,
  })  : _authService = authService,
        _storageService = storageService;

  /// Login con RUT y contraseña
  Future<UserModel> login(String rut, String password) async {
    final response = await _authService.login(rut, password);
    final token = response['token'] as String;
    final user = UserModel.fromJson(response['user']);

    // Guardar token de forma segura
    await _storageService.saveToken(token);
    // Guardar datos de usuario
    await _storageService.saveString('user_rut', user.rut);
    await _storageService.saveString('user_nombre', user.nombre);

    return user;
  }

  /// Verificar sesión existente
  Future<bool> hasActiveSession() async {
    return await _storageService.hasToken();
  }

  /// Logout — limpiar todo
  Future<void> logout() async {
    await _authService.logout();
    await _storageService.clearAll();
  }
}
