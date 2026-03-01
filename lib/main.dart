import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Necesario para inicializar Firebase
import 'screens/splash_screen.dart'; // Importamos la nueva pantalla de carga

void main() async {
  // Aseguramos que el motor de Flutter esté listo antes de llamar a código nativo
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializamos Firebase (conecta la app con la consola de Google)
  await Firebase.initializeApp();

  // Arrancamos la aplicación visual
  runApp(const MiAplicacionTea());
}

class MiAplicacionTea extends StatelessWidget {
  const MiAplicacionTea({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Misión Espacial TEA',
      debugShowCheckedModeBanner: false, // Quitamos la etiqueta "DEBUG" de la esquina
      theme: ThemeData(
        useMaterial3: true,
        // Configuración de colores basada en tu diseño del Alien
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8BC34A), // Verde Alien Principal
          primary: const Color(0xFF8BC34A),
          secondary: const Color(0xFF689F38), // Verde más oscuro para contrastes
          surface: const Color(0xFFF1F8E9),   // Color Crema (Fondo de tarjetas)
        ),
        // Definimos el color de texto por defecto para que combine
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF33691E)),
        ),
      ),
      // --- PUNTO DE ENTRADA ---
      // Ahora iniciamos en el SplashScreen para verificar la sesión automáticamente
      home: const SplashScreen(),
    );
  }
}