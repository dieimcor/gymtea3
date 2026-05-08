import 'dart:async';
import 'package:flutter/material.dart';
import '../models/level_model.dart';
import '../widgets/fondo_app.dart';

class ExerciseSessionScreen extends StatefulWidget {
  final Nivel nivel;
  final int segundosPorEjercicio;
  final int segundosDeDescanso;

  const ExerciseSessionScreen({
    super.key,
    required this.nivel,
    required this.segundosPorEjercicio,
    required this.segundosDeDescanso,
  });

  @override
  State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen> with TickerProviderStateMixin {
  late List<Ejercicio> _rutinaCompleta;
  int _indiceActual = 0;

  late AnimationController _progressController;
  Timer? _flipTimer;
  bool _isMirrored = false;
  bool _estaPausado = false;
  bool _enDescanso = false;

  @override
  void initState() {
    super.initState();
    // LÓGICA DE CARGA DE EJERCICIOS
    // Si tiene 9 ejercicios (Nivel 4), usamos la lista tal cual.
    // Si tiene menos (Niveles 1-3), la duplicamos para hacer 2 rondas.
    if (widget.nivel.listaEjercicios.length >= 9) {
      _rutinaCompleta = [...widget.nivel.listaEjercicios];
    } else {
      _rutinaCompleta = [...widget.nivel.listaEjercicios, ...widget.nivel.listaEjercicios];
    }

    _progressController = AnimationController(vsync: this);
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _manejarFinDeTiempo();
      }
    });

    _iniciarBloqueActual();
  }

  void _iniciarBloqueActual() {
    int duracion = _enDescanso ? widget.segundosDeDescanso : widget.segundosPorEjercicio;

    _progressController.duration = Duration(seconds: duracion);
    _progressController.reset();
    _progressController.forward();

    _isMirrored = false;
    _flipTimer?.cancel();

    if (!_enDescanso) {
      _flipTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
        if (!_estaPausado && mounted) {
          setState(() => _isMirrored = !_isMirrored);
        }
      });
    }
  }

  void _manejarFinDeTiempo() {
    if (_enDescanso) {
      // FIN DEL DESCANSO
      setState(() {
        _enDescanso = false;
        _indiceActual++;
      });
      _iniciarBloqueActual();

    } else {
      // FIN DE UN EJERCICIO

      // Lógica de Descansos Múltiples:
      // ¿Es múltiplo de 3? (Indices 2, 5, etc.) Y no es el último ejercicio.
      // (indice + 1) % 3 == 0  --> Significa que acabamos de terminar el 3ro, el 6to...
      bool tocaDescanso = (_indiceActual + 1) % 3 == 0;
      bool noEsElUltimo = _indiceActual < _rutinaCompleta.length - 1;

      if (tocaDescanso && noEsElUltimo && widget.segundosDeDescanso > 0) {
        // ACTIVAR DESCANSO
        setState(() => _enDescanso = true);
        _iniciarBloqueActual();

      } else if (noEsElUltimo) {
        // SIGUIENTE EJERCICIO (Sin descanso)
        setState(() => _indiceActual++);
        _iniciarBloqueActual();

      } else {
        // FIN DE LA RUTINA
        _finalizarNivel();
      }
    }
  }

  void _retroceder() {
    if (_indiceActual > 0) {
      setState(() {
        _enDescanso = false;
        _indiceActual--;
      });
      _iniciarBloqueActual();
    }
  }

  void _avanzar() {
    if (_enDescanso) {
      _manejarFinDeTiempo();
      return;
    }

    // Revisamos si al avanzar toca forzar un descanso
    bool tocaDescansoProximo = (_indiceActual + 1) % 3 == 0;

    if (tocaDescansoProximo && widget.segundosDeDescanso > 0 && _indiceActual < _rutinaCompleta.length - 1) {
      setState(() => _enDescanso = true);
      _iniciarBloqueActual();
      return;
    }

    if (_indiceActual < _rutinaCompleta.length - 1) {
      setState(() => _indiceActual++);
      _iniciarBloqueActual();
    } else {
      _finalizarNivel();
    }
  }

  void _finalizarNivel() {
    _flipTimer?.cancel();
    _progressController.stop();
    widget.nivel.vecesCompletado++;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(children: [Icon(Icons.emoji_events, color: Colors.orange, size: 50), Text("¡Misión Cumplida!")]),
        content: const Text("Entrenamiento finalizado con éxito."),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text("Volver al Mapa"),
          )
        ],
      ),
    );
  }

  void _alternarPausa() {
    setState(() {
      _estaPausado = !_estaPausado;
      if (_estaPausado) _progressController.stop();
      else _progressController.forward();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _flipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ejercicioActual = _rutinaCompleta[_indiceActual < _rutinaCompleta.length ? _indiceActual : 0];

    return FondoApp(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
          title: Text(
              _enDescanso ? "RECUPERACIÓN" : "Ejercicio ${_indiceActual + 1} / ${_rutinaCompleta.length}",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))],
                  ),
                  child: _enDescanso
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.battery_charging_full_rounded, size: 80, color: Colors.green),
                      const SizedBox(height: 20),
                      Text("¡Recarga Energía!", style: TextStyle(fontSize: 26, color: Colors.grey[700], fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      const Text("Respira profundo...", style: TextStyle(fontSize: 18, color: Colors.black54)),
                    ],
                  )
                      : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: Transform.flip(
                      key: ValueKey(_isMirrored),
                      flipX: _isMirrored,
                      child: Image.asset(ejercicioActual.imagenRuta, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _enDescanso ? "Descanso" : ejercicioActual.nombre,
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Expanded(
                flex: 3,
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    int duracionTotal = _enDescanso ? widget.segundosDeDescanso : widget.segundosPorEjercicio;
                    int restantes = (duracionTotal * (1 - _progressController.value)).ceil();
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100, height: 100,
                          child: CircularProgressIndicator(
                            value: 1 - _progressController.value,
                            strokeWidth: 8,
                            backgroundColor: Colors.white24,
                            color: _enDescanso ? Colors.green : (restantes > 5 ? Colors.blueAccent : Colors.redAccent),
                          ),
                        ),
                        Text("$restantes", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(icon: const Icon(Icons.skip_previous_rounded), iconSize: 50, color: _indiceActual > 0 ? Colors.white : Colors.white24, onPressed: _retroceder),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)]
                    ),
                    child: IconButton(icon: Icon(_estaPausado ? Icons.play_arrow_rounded : Icons.pause_rounded), iconSize: 50, color: const Color(0xFF8BC34A), onPressed: _alternarPausa),
                  ),
                  IconButton(icon: const Icon(Icons.skip_next_rounded), iconSize: 50, color: Colors.white, onPressed: _avanzar),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}