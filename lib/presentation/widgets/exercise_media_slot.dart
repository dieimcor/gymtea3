import 'package:flutter/material.dart';

import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/data/models/exercise_media.dart';
import 'package:gymtea3/data/models/exercise_model.dart';

/// Espacio reservado para el recurso visual de un ejercicio.
///
/// Las gráficas, GIFs y videos definitivos se están diseñando, así que hoy
/// todos los ejercicios muestran solo este espacio (marco + ícono + nombre).
/// El tamaño y la proporción quedan fijos: cuando el recurso esté listo se
/// asigna en `ExerciseModel.media` y aparece aquí mismo, sin mover el
/// layout de ninguna pantalla.
///
/// - `imagen` / `gif`: se dibujan con `Image` (los GIF se animan solos).
/// - `video`: queda el espacio con un ícono de reproducción hasta sumar un
///   reproductor (p. ej. el paquete `video_player`).
class ExerciseMediaSlot extends StatelessWidget {
  final ExerciseModel exercise;

  /// Ancho del espacio. El alto sale de [aspectRatio].
  final double width;

  /// Proporción ancho / alto del recurso. 4:3 por defecto, apta para
  /// ilustraciones y video.
  final double aspectRatio;

  final BorderRadius? borderRadius;

  /// `false` en miniaturas (p. ej. el pop-up del cráter): oculta el texto.
  final bool showLabel;

  const ExerciseMediaSlot({
    super.key,
    required this.exercise,
    this.width = 220,
    this.aspectRatio = 4 / 3,
    this.borderRadius,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(18);
    final height = width / aspectRatio;

    return Semantics(
      image: true,
      label: 'Recurso del ejercicio ${exercise.nombre}',
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: radius,
          border: Border.all(
            color: AppTheme.goldAccent.withValues(alpha: 0.28),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildContent(height),
      ),
    );
  }

  Widget _buildContent(double height) {
    final media = exercise.media;
    if (media == null) return _placeholder(height, Icons.image_outlined);

    switch (media.tipo) {
      case ExerciseMediaType.imagen:
      case ExerciseMediaType.gif:
        Widget fallback(BuildContext _, Object __, StackTrace? ___) =>
            _placeholder(height, Icons.image_outlined);
        return media.esRemoto
            ? Image.network(media.ruta, fit: BoxFit.cover, errorBuilder: fallback)
            : Image.asset(media.ruta, fit: BoxFit.cover, errorBuilder: fallback);
      case ExerciseMediaType.video:
        // Sin reproductor todavía: se respeta el espacio del video.
        return _placeholder(height, Icons.play_circle_outline_rounded);
    }
  }

  Widget _placeholder(double height, IconData icon) {
    final compact = !showLabel || height < 90;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: (height * 0.3).clamp(18.0, 56.0),
            color: AppTheme.goldAccent.withValues(alpha: 0.55),
          ),
          if (!compact) ...[
            const SizedBox(height: 6),
            Text(
              exercise.nombre,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
