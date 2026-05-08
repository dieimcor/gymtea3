import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/fondo_app.dart';
import 'login_screen.dart';
import 'level_map_screen.dart';
import 'questionnaire_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    // 1. Damos un tiempo mínimo (2 segundos) para que se vea el logo
    // y no sea un parpadeo feo.
    await Future.delayed(const Duration(seconds: 2));

    // 2. Preguntamos a Firebase si hay un usuario actual
    final user = FirebaseAuth.instance.currentUser;

    if (mounted) {
      if (user != null) {
        // --- CASO A: USUARIO LOGUEADO ---
        debugPrint("Usuario detectado: ${user.email}");
        await _decidirDestinoDiario();
      } else {
        // --- CASO B: NO HAY USUARIO ---
        debugPrint("No hay sesión activa. Yendo al Login.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  // Misma lógica que en el Login: ¿Ya jugó hoy?
  Future<void> _decidirDestinoDiario() async {
    final prefs = await SharedPreferences.getInstance();
    final ultimoRegistro = prefs.getString('ultimo_cuestionario');
    final hoy = DateTime.now().toIso8601String().split('T')[0];

    Widget proximaPantalla;

    if (ultimoRegistro == hoy) {
      debugPrint("Ya completó cuestionario hoy. Al Mapa.");
      proximaPantalla = const LevelMapScreen();
    } else {
      debugPrint("Nuevo día. Al Cuestionario.");
      proximaPantalla = const QuestionnaireScreen();
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => proximaPantalla),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FondoApp(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. TU LOGO O MASCOTA
              // Usamos una animación sutil de escala para que se vea vivo
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, double scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.white30, width: 2),
                  ),
                  child: Image.asset(
                    'assets/images/petq.png', // Tu alien
                    height: 150,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 2. TEXTO DE CARGA
              const Text(
                "Cargando motores...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 30),

              // 3. CIRCULITO DE CARGA
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8BC34A)), // Verde Alien
              ),
            ],
          ),
        ),
      ),
    );
  }
}