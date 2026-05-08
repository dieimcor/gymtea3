import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/fondo_app.dart';
import 'questionnaire_screen.dart'; // Al registrarse, es usuario nuevo -> va directo al cuestionario

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _cargando = false; // Para mostrar un circulito mientras carga

  // --- LÓGICA DE REGISTRO ---
  Future<void> _registrarse() async {
    // 1. Validaciones básicas
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _mostrarError("Por favor completa todos los campos.");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _mostrarError("Las contraseñas no coinciden.");
      return;
    }

    if (_passwordController.text.length < 6) {
      _mostrarError("La contraseña debe tener al menos 6 caracteres.");
      return;
    }

    setState(() => _cargando = true);

    try {
      // 2. Crear usuario en Firebase
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3. ¡Éxito!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Cuenta creada con éxito! Bienvenido."), backgroundColor: Colors.green),
        );

        // Como es cuenta nueva, NO ha hecho el cuestionario. Vamos directo ahí.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const QuestionnaireScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = "Ocurrió un error.";
      if (e.code == 'email-already-in-use') mensaje = "Este correo ya está registrado.";
      if (e.code == 'invalid-email') mensaje = "El correo no es válido.";
      if (e.code == 'weak-password') mensaje = "La contraseña es muy débil.";

      _mostrarError(mensaje);
    } catch (e) {
      _mostrarError("Error: $e");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    const colorVerdeBorde = Color(0xFF8BC34A);
    const colorVerdeTexto = Color(0xFF2E6B1F);

    return FondoApp(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context), // Volver al Login
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              color: const Color(0xFFF1F8E9),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Crear Cuenta",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorVerdeTexto),
                    ),
                    const SizedBox(height: 20),

                    _campoTexto("Correo electrónico", _emailController, false),
                    const SizedBox(height: 15),
                    _campoTexto("Contraseña", _passwordController, true),
                    const SizedBox(height: 15),
                    _campoTexto("Confirmar Contraseña", _confirmPasswordController, true),

                    const SizedBox(height: 30),

                    if (_cargando)
                      const CircularProgressIndicator(color: colorVerdeBorde)
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _registrarse,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorVerdeBorde,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          child: const Text("Registrarse", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _campoTexto(String label, TextEditingController controller, bool esPassword) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 5),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E6B1F))),
        ),
        TextField(
          controller: controller,
          obscureText: esPassword,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.7),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF8BC34A))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF8BC34A))),
          ),
        ),
      ],
    );
  }
}