import 'package:flutter/material.dart';
import '../data/datos_prueba.dart';
import '../models/level_model.dart';
import '../widgets/fondo_app.dart';
import 'exercise_session_screen.dart';

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {

  @override
  Widget build(BuildContext context) {
    // --- LÓGICA DE FILTRADO (NIVEL OCULTO) ---
    // Creamos una lista dinámica. El Nivel 4 (índice 3) solo se agrega
    // si el Nivel 3 (índice 2) ya se completó 2 veces.
    List<Nivel> nivelesVisibles = nivelesDePrueba.where((nivel) {
      int index = nivelesDePrueba.indexOf(nivel);

      // Si es el Nivel 4 (índice 3 en la lista original)
      if (index == 3) {
        // Solo mostrar si el Nivel 3 (índice 2) está completado
        return nivelesDePrueba[2].vecesCompletado >= 2;
      }

      // Los niveles 1, 2 y 3 siempre se muestran (aunque estén bloqueados)
      return true;
    }).toList();

    return FondoApp(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
              "Selecciona tu Nivel",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            // LISTA DE NIVELES (Usamos la lista filtrada 'nivelesVisibles')
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: nivelesVisibles.length,
                itemBuilder: (context, index) {
                  return _construirTarjetaNivel(nivelesVisibles[index]);
                },
              ),
            ),

            // BOTÓN DE REINICIO
            Padding(
              padding: const EdgeInsets.only(bottom: 30, top: 10),
              child: TextButton.icon(
                onPressed: _confirmarReinicio,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                label: const Text("Reiniciar Progreso", style: TextStyle(color: Colors.white70, fontSize: 16)),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTarjetaNivel(Nivel nivel) {
    bool desbloqueado = nivel.estaDesbloqueado;

    // Si es el nivel desafío (Nivel 4), le damos un borde dorado especial
    bool esDesafio = nivel.nombre.contains("Desafío");

    return GestureDetector(
      onTap: () {
        if (desbloqueado) {
          _mostrarConfiguracion(nivel);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("¡Nivel bloqueado! Completa el anterior."), backgroundColor: Colors.redAccent)
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: desbloqueado ? const Color.fromARGB(230, 255, 255, 255) : Colors.black45,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color: esDesafio ? Colors.amber : (desbloqueado ? Colors.blueAccent : Colors.grey),
                width: esDesafio ? 3 : 2
            ),
            boxShadow: [
              if (esDesafio && desbloqueado)
                BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0,0))
            ]
        ),
        child: Row(
          children: [
            Icon(
                esDesafio ? Icons.military_tech : (desbloqueado ? Icons.fitness_center : Icons.lock),
                color: esDesafio ? Colors.amber : (desbloqueado ? Colors.blueAccent : Colors.white54),
                size: 30
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nivel.nombre, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: desbloqueado ? Colors.black87 : Colors.white60)),
                  if (desbloqueado)
                    Text(
                        "Completado: ${nivel.vecesCompletado}/2 veces",
                        style: TextStyle(fontSize: 12, color: Colors.grey[700])
                    ),
                ],
              ),
            ),
            if (desbloqueado) const Icon(Icons.play_circle_fill, color: Colors.green, size: 35),
          ],
        ),
      ),
    );
  }

  // --- POPUP DE CONFIGURACIÓN ---
  void _mostrarConfiguracion(Nivel nivel) {
    int tiempoEjercicio = 20;
    int tiempoDescanso = 10;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStatePopup) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF1F8E9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Configuración", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF33691E), fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Tiempo por Ejercicio:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _botonOpcion(10, tiempoEjercicio, (v) => setStatePopup(() => tiempoEjercicio = v)),
                      _botonOpcion(20, tiempoEjercicio, (v) => setStatePopup(() => tiempoEjercicio = v)),
                      _botonOpcion(30, tiempoEjercicio, (v) => setStatePopup(() => tiempoEjercicio = v)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Tiempo de Descanso:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _botonOpcion(0, tiempoDescanso, (v) => setStatePopup(() => tiempoDescanso = v), label: "No"),
                      _botonOpcion(10, tiempoDescanso, (v) => setStatePopup(() => tiempoDescanso = v)),
                      _botonOpcion(20, tiempoDescanso, (v) => setStatePopup(() => tiempoDescanso = v)),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8BC34A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExerciseSessionScreen(
                          nivel: nivel,
                          segundosPorEjercicio: tiempoEjercicio,
                          segundosDeDescanso: tiempoDescanso,
                        ),
                      ),
                    ).then((_) {
                      setState(() {
                        _verificarDesbloqueo(nivel);
                      });
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("COMENZAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _botonOpcion(int valor, int valorSeleccionado, Function(int) onSelected, {String? label}) {
    bool isSelected = valor == valorSeleccionado;
    return GestureDetector(
      onTap: () => onSelected(valor),
      child: Container(
        width: 60, height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8BC34A) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? const Color(0xFF33691E) : Colors.grey),
            boxShadow: [if(isSelected) const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
        ),
        child: Text(
          label ?? "${valor}s",
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _verificarDesbloqueo(Nivel nivelActual) {
    if (nivelActual.vecesCompletado >= 2) {
      int indiceActual = nivelesDePrueba.indexOf(nivelActual);
      int indiceSiguiente = indiceActual + 1;

      if (indiceSiguiente < nivelesDePrueba.length) {
        Nivel siguienteNivel = nivelesDePrueba[indiceSiguiente];

        // Lógica especial para mostrar mensaje cuando APARECE el nivel oculto
        bool estabaOculto = false;
        if (indiceSiguiente == 3 && !siguienteNivel.estaDesbloqueado) {
          estabaOculto = true;
        }

        if (!siguienteNivel.estaDesbloqueado) {
          siguienteNivel.estaDesbloqueado = true;

          String mensaje = estabaOculto
              ? "¡INCREÍBLE! Has descubierto el Nivel Secreto: ${siguienteNivel.nombre}"
              : "¡Felicidades! Desbloqueaste: ${siguienteNivel.nombre}";

          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(estabaOculto ? Icons.star : Icons.lock_open, color: Colors.amber),
                    const SizedBox(width: 10),
                    Expanded(child: Text(mensaje)),
                  ],
                ),
                backgroundColor: estabaOculto ? Colors.purple : Colors.green,
                duration: const Duration(seconds: 5),
              )
          );
        }
      }
    }
  }

  void _confirmarReinicio() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBE6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF8BC34A), width: 3)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/petq.png', height: 120),
            const SizedBox(height: 15),
            const Text("¿Estás seguro?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF33691E))),
            const SizedBox(height: 10),
            const Text("Esto borrará todo tu avance y el Nivel Desafío volverá a ocultarse.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontSize: 16))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              _ejecutarReinicio();
            },
            child: const Text("Sí, Reiniciar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _ejecutarReinicio() {
    setState(() {
      for (int i = 0; i < nivelesDePrueba.length; i++) {
        nivelesDePrueba[i].vecesCompletado = 0;
        nivelesDePrueba[i].estaDesbloqueado = (i == 0);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Progreso reiniciado correctamente"), backgroundColor: Colors.orange),
    );
  }
}