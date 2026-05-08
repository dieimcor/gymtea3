import 'package:flutter/material.dart';
import 'package:gymtea3/data/models/user_model.dart';
import 'package:gymtea3/data/models/child_model.dart';
import 'package:gymtea3/data/repositories/auth_repository.dart';

/// Provider de autenticación — gestiona estado de sesión, usuario y niño
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider({required AuthRepository authRepository})
      : _authRepository = authRepository;

  UserModel? _currentUser;
  ChildModel? _currentChild;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  ChildModel? get currentChild => _currentChild;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  /// Nombre del niño para mostrar en UI
  String get childName => _currentChild?.nombre ?? 'Sin asignar';

  /// Nivel actual del niño
  int get childLevel => _currentChild?.nivelProgresionActual ?? 1;

  /// Saludo contextual según hora del día
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  /// Login con RUT y contraseña
  Future<bool> login(String rut, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepository.login(rut, password);
      _currentUser = result['user'] as UserModel;
      _currentChild = result['child'] as ChildModel?;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verificar sesión existente al iniciar la app
  /// Restaura user + child desde storage si hay token válido
  Future<bool> checkSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isAuthenticated = await _authRepository.hasActiveSession();

      if (_isAuthenticated) {
        // Restaurar datos desde storage
        _currentUser = await _authRepository.restoreUser();
        _currentChild = await _authRepository.restoreChild();
      }

      _isLoading = false;
      notifyListeners();
      return _isAuthenticated;
    } catch (e) {
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    _currentChild = null;
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }

  /// Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
