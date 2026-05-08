import '../models/level_model.dart';

// Definimos la lista de niveles
List<Nivel> nivelesDePrueba = [
  Nivel(
    id: 1, // <--- AGREGADO
    nombre: "Nivel 1: Iniciación",
    listaEjercicios: [
      Ejercicio(nombre: "Saltos de Tijera", duracionSegundos: 3, imagenRuta: "assets/images/ej1.png"),
      Ejercicio(nombre: "Sentadillas", duracionSegundos: 3, imagenRuta: "assets/images/ej2.png"),
      Ejercicio(nombre: "Estiramiento", duracionSegundos: 3, imagenRuta: "assets/images/ej3.png"),
    ],
    vecesCompletado: 0,
    estaDesbloqueado: true,
  ),
  Nivel(
    id: 2, // <--- AGREGADO
    nombre: "Nivel 2: Intermedio",
    listaEjercicios: [
      Ejercicio(nombre: "Flexiones", duracionSegundos: 3, imagenRuta: "assets/images/ej4.png"),
      Ejercicio(nombre: "Abdominales", duracionSegundos: 3, imagenRuta: "assets/images/ej5.png"),
      Ejercicio(nombre: "Trote en el sitio", duracionSegundos: 3, imagenRuta: "assets/images/ej6.png"),
    ],
    vecesCompletado: 0,
    estaDesbloqueado: false,
  ),
  Nivel(
    id: 3, // <--- AGREGADO
    nombre: "Nivel 3: Avanzado",
    listaEjercicios: [
      Ejercicio(nombre: "Burpees", duracionSegundos: 3, imagenRuta: "assets/images/ej7.png"),
      Ejercicio(nombre: "Plancha", duracionSegundos: 3, imagenRuta: "assets/images/ej8.png"),
      Ejercicio(nombre: "Zancadas", duracionSegundos: 3, imagenRuta: "assets/images/ej9.png"),
    ],
    vecesCompletado: 0,
    estaDesbloqueado: false,
  ),
  Nivel(
    id: 4, // <--- AGREGADO
    nombre: "Nivel 4: Desafío Final",
    listaEjercicios: [
      // 9 Ejercicios para el desafío
      Ejercicio(nombre: "Saltos de Tijera", duracionSegundos: 3, imagenRuta: "assets/images/ej1.png"),
      Ejercicio(nombre: "Sentadillas", duracionSegundos: 3, imagenRuta: "assets/images/ej2.png"),
      Ejercicio(nombre: "Flexiones", duracionSegundos: 3, imagenRuta: "assets/images/ej3.png"),
      Ejercicio(nombre: "Abdominales", duracionSegundos: 3, imagenRuta: "assets/images/ej4.png"),
      Ejercicio(nombre: "Burpees", duracionSegundos: 3, imagenRuta: "assets/images/ej5.png"),
      Ejercicio(nombre: "Plancha", duracionSegundos: 3, imagenRuta: "assets/images/ej6.png"),
      Ejercicio(nombre: "Trote", duracionSegundos: 3, imagenRuta: "assets/images/ej7.png"),
      Ejercicio(nombre: "Zancadas", duracionSegundos: 3, imagenRuta: "assets/images/ej8.png"),
      Ejercicio(nombre: "Estiramiento Final", duracionSegundos: 3, imagenRuta: "assets/images/ej9.png"),
    ],
    vecesCompletado: 0,
    estaDesbloqueado: false,
  ),
];