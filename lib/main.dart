import 'package:flutter/material.dart';
import 'package:gymtea3/data/services/storage_service.dart';
import 'app.dart';

void main() async {
  // Asegurar que el motor de Flutter esté listo antes de código async
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar servicio de almacenamiento (SharedPreferences + SecureStorage)
  final storageService = StorageService();
  await storageService.init();

  // Arrancar la app con el servicio de storage inyectado
  runApp(NeuroGymApp(storageService: storageService));
}