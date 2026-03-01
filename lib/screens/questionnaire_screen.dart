import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/fondo_app.dart';
import 'level_map_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int _indicePregunta = 0;

  // --- LISTA DE PREGUNTAS Y OPCIONES ---
  final List<Map<String, dynamic>> _cuestionario = [
    // 0. INTRODUCCIÓN (Solo mensaje de bienvenida)
    {
      "tipo": "intro",
      "texto": "¡Hola Cadete! 👋\n\nResponde estas breves preguntas antes de iniciar tu entrenamiento de hoy.",
      "opciones": ["¡Entendido, vamos!"]
    },
    // 1. NEURODIVERGENCIA (Esta se guardaría en perfil permanente en el futuro)
    {
      "tipo": "pregunta",
      "texto": "¿Qué tipo de neurodivergencia tienes diagnosticada?",
      "opciones": ["TEA (Autismo)", "TDAH", "Ambos (TEA + TDAH)", "Otra / En estudio"]
    },
    // 2. COORDINACIÓN
    {
      "tipo": "pregunta",
      "texto": "¿Cuál es tu nivel de desarrollo de la coordinación?",
      "opciones": [
        "Coordinación motriz baja",
        "Coordinación motriz media",
        "Coordinación motriz alta",
        "Coordinación motriz completa"
      ]
    },
    // 3. NEURONAL
    {
      "tipo": "pregunta",
      "texto": "¿Cuál es tu nivel de desarrollo neuronal?",
      "opciones": [
        "Coordinación neuronal baja",
        "Coordinación neuronal media",
        "Coordinación neuronal alta",
        "Coordinación neuronal completa"
      ]
    },
    // 4. MUSCULAR
    {
      "tipo": "pregunta",
      "texto": "¿Cuál es tu nivel de desarrollo muscular?",
      "opciones": [
        "Desarrollo muscular bajo",
        "Desarrollo muscular medio",
        "Desarrollo muscular alto",
        "Desarrollo muscular completo"
      ]
    },
    // 5. TERAPIA
    {
      "tipo": "pregunta",
      "texto": "¿Realizas algún tipo de terapia actualmente?",
      "opciones": [
        "Terapia Ocupacional",
        "Fonoaudiología",
        "Kinesiología",
        "Ninguna",
        "Otra"
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    final pasoActual = _cuestionario[_indicePregunta];
    final String textoDialogo = pasoActual['texto'];
    final List<String> opciones = pasoActual['opciones'];

    return FondoApp(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),

              // 1. ZONA SUPERIOR: MASCOTA Y GLOBO
              Expanded(
                flex: 9, // Ocupa un poco más de la mitad superior
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // A. LA MASCOTA (petq.png)
                    Positioned(
                      bottom: 0,
                      right: -10, // Un poco a la derecha
                      child: Image.asset(
                        'assets/images/petq.png', // <--- TU NUEVA IMAGEN
                        height: 260, // Tamaño ajustado para que no tape todo
                        fit: BoxFit.contain,
                      ),
                    ),

                    // B. EL GLOBO DE DIÁLOGO
                    Positioned(
                      top: 20,
                      left: 20,
                      right: 120, // Dejamos espacio a la derecha para la cabeza del alien
                      bottom: 100, // No bajar tanto para no tapar al alien
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBE6), // Un crema suave (estilo papel)
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(0), // Punta del globo hacia el alien
                          ),
                          border: Border.all(color: const Color(0xFF8BC34A), width: 3), // Borde verde alien
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(4, 4))
                          ],
                        ),
                        child: Center(
                          child: SingleChildScrollView(
                            child: Text(
                              textoDialogo,
                              style: const TextStyle(
                                fontSize: 19,
                                color: Color(0xFF33691E), // Verde oscuro para texto
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. ZONA INFERIOR: RESPUESTAS
              Expanded(
                flex: 7,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: const BoxDecoration(
                      color: Colors.white, // Fondo limpio para las opciones
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -5))
                      ]
                  ),
                  child: Column(
                    children: [
                      // Indicador de progreso (puntitos)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_cuestionario.length, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _indicePregunta == index
                                  ? const Color(0xFF8BC34A) // Verde activo
                                  : Colors.grey[300], // Gris inactivo
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 20),

                      // Lista de Botones
                      Expanded(
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: opciones.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return ElevatedButton(
                              onPressed: () => _siguientePaso(opciones[index]),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F8E9), // Fondo verde muy clarito
                                foregroundColor: const Color(0xFF33691E), // Texto verde oscuro
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: const BorderSide(color: Color(0xFF8BC34A), width: 1.5),
                                ),
                              ),
                              child: Text(
                                opciones[index],
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _siguientePaso(String respuesta) async {
    // Aquí puedes guardar la respuesta si quieres (ej: en una lista temporal)
    // print("Respuesta guardada: $respuesta");

    if (_indicePregunta < _cuestionario.length - 1) {
      setState(() {
        _indicePregunta++;
      });
    } else {
      // FINALIZAR: Guardar fecha para no repetir hoy
      final prefs = await SharedPreferences.getInstance();
      final hoy = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString('ultimo_cuestionario', hoy);

      // Ir al Mapa
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LevelMapScreen()),
        );
      }
    }
  }
}