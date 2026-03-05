/// Excepciones personalizadas de NeuroGym

class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException extends AppException {
  UnauthorizedException(super.message);
}

class ForbiddenException extends AppException {
  ForbiddenException(super.message);
}

class NotFoundException extends AppException {
  NotFoundException(super.message);
}

class ValidationException extends AppException {
  final dynamic errors;
  ValidationException(super.message, this.errors);
}

class ServerException extends AppException {
  ServerException(super.message);
}

class NetworkException extends AppException {
  NetworkException([String message = 'Sin conexión a internet.']) : super(message);
}

class CacheException extends AppException {
  CacheException([String message = 'Error al acceder al cache local.']) : super(message);
}
