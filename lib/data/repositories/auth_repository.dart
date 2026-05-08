import 'dart:convert';
import 'package:gymtea3/data/models/user_model.dart';
import 'package:gymtea3/data/models/child_model.dart';
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

  /// Login con RUT y contraseña — retorna user + child
  Future<Map<String, dynamic>> login(String rut, String password) async {
    final response = await _authService.login(rut, password);
    final token = response['token'] as String;
    final user = UserModel.fromJson(response['user']);
    final child = response['child'] != null
        ? ChildModel.fromJson(response['child'])
        : null;

    // Guardar token de forma segura
    await _storageService.saveToken(token);
    // Guardar datos de usuario
    await _storageService.saveString('user_rut', user.rut);
    await _storageService.saveString('user_nombre', user.nombre);
    // Guardar datos del usuario como JSON para restaurar sesión
    await _storageService.saveString('user_data', jsonEncode(user.toJson()));
    if (child != null) {
      await _storageService.saveString('child_data', jsonEncode(child.toJson()));
    }

    return {
      'user': user,
      'child': child,
    };
  }

  /// Verificar sesión existente
  Future<bool> hasActiveSession() async {
    return await _storageService.hasToken();
  }

  /// Restaurar datos de usuario desde storage
  Future<UserModel?> restoreUser() async {
    final userData = _storageService.getString('user_data');
    if (userData != null) {
      return UserModel.fromJson(jsonDecode(userData));
    }
    return null;
  }

  /// Restaurar datos del niño desde storage
  Future<ChildModel?> restoreChild() async {
    final childData = _storageService.getString('child_data');
    if (childData != null) {
      return ChildModel.fromJson(jsonDecode(childData));
    }
    return null;
  }

  /// Logout — limpiar todo
  Future<void> logout() async {
    await _authService.logout();
    await _storageService.clearAll();
  }
}
