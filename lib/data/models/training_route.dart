import 'package:flutter/material.dart';

import 'package:gymtea3/core/theme/comet_theme.dart';
import 'package:gymtea3/data/models/equipment.dart';

/// Ruta de entrenamiento que el padre elige al empezar (y puede cambiar
/// desde Perfil). Cada ruta tiene sus propios planetas y guarda su propio
/// avance.
///
/// Lo que cambia entre rutas:
/// - la duración de cada serie ([seriesSeconds]);
/// - qué equipo se puede pedir ([maxEquipo]), pensando en niños: lo que
///   no está a mano se reemplaza por juguetes o cosas de la casa;
/// - la ruta más exigente suma un ejercicio por cráter
///   ([extraExercises]).
///
/// La cantidad de ejercicios sigue creciendo con los cráteres
/// (3 → 4 → 5 según `Dificultad`) y los descansos son los mismos.
enum TrainingRoute {
  explorador(
    label: 'Explorador',
    nivel: 1,
    seriesSeconds: 30,
    extraExercises: 0,
    maxEquipo: Equipo.libre,
    color: Color(0xFF43A047),
    icon: Icons.explore_rounded,
    tagline: 'Para empezar con calma',
    equipoTexto: 'Solo el cuerpo y una silla',
    comets: [CometTheme.limon, CometTheme.menta],
  ),
  astronauta(
    label: 'Astronauta',
    nivel: 2,
    seriesSeconds: 45,
    extraExercises: 0,
    maxEquipo: Equipo.basico,
    color: Color(0xFFE09B2D),
    icon: Icons.rocket_launch_rounded,
    tagline: 'Un desafío a la medida',
    equipoTexto: 'Cosas de la casa: botella, pelota, toalla',
    comets: [CometTheme.lavanda, CometTheme.frutilla],
  ),
  comandante(
    label: 'Comandante',
    nivel: 3,
    seriesSeconds: 60,
    extraExercises: 1,
    maxEquipo: Equipo.especial,
    color: Color(0xFFE2553C),
    icon: Icons.military_tech_rounded,
    tagline: 'Para los más valientes',
    equipoTexto: 'Equipo especial, con reemplazos seguros',
    comets: [CometTheme.oceano, CometTheme.volcan],
  );

  final String label;

  /// 1 a 3, para las barras de nivel de la tarjeta.
  final int nivel;

  /// Duración de cada serie en esta ruta.
  final int seriesSeconds;

  /// Ejercicios extra por cráter, sobre los de la dificultad del cráter.
  final int extraExercises;

  /// Equipo más exigente que puede pedir esta ruta.
  final Equipo maxEquipo;

  final Color color;
  final IconData icon;
  final String tagline;
  final String equipoTexto;

  /// Planetas propios de la ruta, en orden de viaje.
  final List<CometTheme> comets;

  const TrainingRoute({
    required this.label,
    required this.nivel,
    required this.seriesSeconds,
    required this.extraExercises,
    required this.maxEquipo,
    required this.color,
    required this.icon,
    required this.tagline,
    required this.equipoTexto,
    required this.comets,
  });

  static const int maxNivel = 3;

  /// Cometa [index] (0-based) de esta ruta; si hay más vueltas que
  /// planetas, se repiten en ciclo.
  CometTheme cometAt(int index) => comets[index.abs() % comets.length];

  static TrainingRoute? fromName(String? name) {
    for (final r in TrainingRoute.values) {
      if (r.name == name) return r;
    }
    return null;
  }
}
