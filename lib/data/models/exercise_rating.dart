/// "¿Cómo le fue?" — valoración que el padre hace del niño al terminar
/// cada ejercicio (después de su última serie).
///
/// Se guarda por ejercicio en [ProgressModel.calificaciones] para armar
/// el resumen del niño cuando exista.
enum ExerciseRating {
  leCosto(1, 'Le costó'),
  bien(2, '¡Bien!'),
  excelente(3, '¡Excelente!');

  /// Valor que se persiste (1 a 3 estrellas).
  final int stars;
  final String label;

  const ExerciseRating(this.stars, this.label);

  static const int maxStars = 3;

  static ExerciseRating? fromStars(int? stars) {
    for (final r in ExerciseRating.values) {
      if (r.stars == stars) return r;
    }
    return null;
  }
}
