import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gymtea3/core/constants/app_constants.dart';
import 'package:gymtea3/core/errors/exceptions.dart';
import 'package:gymtea3/data/services/storage_service.dart';

/// Cliente HTTP centralizado con soporte JWT
class ApiClient {
  final http.Client _client;
  final StorageService _storage;
  final String _baseUrl;

  ApiClient({
    http.Client? client,
    required StorageService storage,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _storage = storage,
        _baseUrl = baseUrl ?? '${AppConstants.apiBaseUrl}/${AppConstants.apiVersion}';

  /// Headers por defecto con JWT si existe
  Future<Map<String, String>> _headers() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET request
  Future<dynamic> get(String endpoint) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  /// POST request
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// PUT request
  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// Manejo centralizado de respuestas HTTP
  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return jsonDecode(response.body);
      case 401:
        throw UnauthorizedException('Sesión expirada. Inicie sesión nuevamente.');
      case 403:
        throw ForbiddenException('No tiene permisos para esta acción.');
      case 404:
        throw NotFoundException('Recurso no encontrado.');
      case 422:
        throw ValidationException('Datos inválidos.', jsonDecode(response.body));
      default:
        throw ServerException('Error del servidor: ${response.statusCode}');
    }
  }

  void dispose() {
    _client.close();
  }
}
