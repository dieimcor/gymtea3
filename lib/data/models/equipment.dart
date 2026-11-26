/// Qué hace falta para un ejercicio, pensando en niños y en hogares.
///
/// Cada ruta de entrenamiento admite hasta cierto nivel
/// (ver `TrainingRoute.maxEquipo`). El orden importa: cada nivel incluye
/// a los anteriores.
enum Equipo {
  /// Solo el cuerpo, o muebles firmes de la casa (silla, sofá).
  libre,

  /// Objetos livianos de la casa: botella de agua, pelota, cojín, toalla.
  basico,

  /// Equipo de gimnasio (mancuernas, kettlebell, TRX, rueda, barra). Solo
  /// en la ruta más exigente, y siempre con un reemplazo seguro.
  especial;

  /// `true` si este nivel cabe dentro de [max].
  bool fitsIn(Equipo max) => index <= max.index;

  String get label {
    switch (this) {
      case Equipo.libre:
        return 'Sin equipo';
      case Equipo.basico:
        return 'Cosas de la casa';
      case Equipo.especial:
        return 'Equipo especial';
    }
  }

  static Equipo fromName(String? name) => Equipo.values.firstWhere(
        (e) => e.name == name,
        orElse: () => Equipo.libre,
      );
}
