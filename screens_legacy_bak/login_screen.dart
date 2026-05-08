import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/fondo_app.dart';
import 'questionnaire_screen.dart';
import 'level_map_screen.dart';
import 'register_screen.dart'; // <--- IMPORTANTE: Importamos la pantalla de registro

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _cargando = false;

  // --- LÓGICA DE LOGIN CON CORREO ---
  Future<void> _iniciarSesionCorreo() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ingresa tu correo y contraseña"), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Si entra, decidimos a dónde ir
      if (mounted) _decidirProximaPantalla();

    } on FirebaseAuthException catch (e) {
      String errorMsg = "Error al ingresar";
      if (e.code == 'user-not-found') errorMsg = "Usuario no encontrado. ¿Te registraste?";
      if (e.code == 'wrong-password') errorMsg = "Contraseña incorrecta.";
      if (e.code == 'invalid-email') errorMsg = "Correo inválido.";

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // --- LÓGICA DE LOGIN CON GOOGLE (Sin cambios) ---
  Future<void> _iniciarSesionGoogle() async {
    try {
      setState(() => _cargando = true);
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _cargando = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) await _decidirProximaPantalla();

    } catch (e) {
      debugPrint("Error Google: $e");
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // --- LÓGICA DE DIRECCIONAMIENTO ---
  Future<void> _decidirProximaPantalla() async {
    final prefs = await SharedPreferences.getInstance();
    final ultimoRegistro = prefs.getString('ultimo_cuestionario');
    final hoy = DateTime.now().toIso8601String().split('T')[0];

    Widget proximaPantalla = (ultimoRegistro == hoy)
        ? const LevelMapScreen()
        : const QuestionnaireScreen();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => proximaPantalla),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorVerdeOscuroTexto = Color(0xFF2E6B1F);
    const colorVerdeBorde = Color(0xFF8BC34A);
    const colorFondoTarjeta = Color(0xFFF1F8E9);
    const colorAzulLink = Color(0xFF1E88E5);

    return FondoApp(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              color: colorFondoTarjeta,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Iniciar Sesión",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorVerdeOscuroTexto),
                    ),
                    const SizedBox(height: 30),

                    _construirCampoTexto("Correo electrónico", _emailController, colorVerdeBorde, colorVerdeOscuroTexto),
                    const SizedBox(height: 20),
                    _construirCampoTexto("Contraseña", _passwordController, colorVerdeBorde, colorVerdeOscuroTexto, esPassword: true),

                    const SizedBox(height: 30),

                    // BOTÓN INICIAR SESIÓN (CORREO)
                    if (_cargando)
                      const CircularProgressIndicator(color: colorVerdeBorde)
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _iniciarSesionCorreo, // <--- Ahora llama a la función real
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorVerdeBorde,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            elevation: 2,
                          ),
                          child: const Text("Iniciar sesión", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // ENLACE A REGISTRO
                    Column(
                      children: [
                        const Text("¿No tienes una cuenta?", style: TextStyle(color: Colors.black54, fontSize: 16)),
                        const SizedBox(height: 5),
                        GestureDetector(
                          onTap: () {
                            // NAVEGACIÓN A LA PANTALLA DE REGISTRO
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            "Registrarse",
                            style: TextStyle(color: colorAzulLink, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // BOTÓN GOOGLE
                    if (!_cargando)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _iniciarSesionGoogle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorVerdeBorde,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Iniciar sesión con Google", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirCampoTexto(String label, TextEditingController controller, Color colorBorde, Color colorTexto, {bool esPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5.0, bottom: 5),
          child: Text(label, style: TextStyle(color: colorTexto, fontWeight: FontWeight.w600, fontSize: 16)),
        ),
        TextField(
          controller: controller,
          obscureText: esPassword,
          style: TextStyle(color: colorTexto),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorBorde, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorBorde, width: 2.5)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}