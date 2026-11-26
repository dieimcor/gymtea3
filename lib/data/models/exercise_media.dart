/// Tipo de recurso visual de un ejercicio.
enum ExerciseMediaType { imagen, gif, video }

/// Recurso que se muestra en el espacio reservado de un ejercicio
/// (ver `ExerciseMediaSlot`).
///
/// Las gráficas, GIFs y videos definitivos se están diseñando. Mientras un
/// ejercicio no tenga `media`, la app muestra solo el espacio reservado;
/// cuando el recurso esté listo basta asignarlo en el catálogo, sin tocar
/// ninguna pantalla.
class ExerciseMedia {
  final ExerciseMediaType tipo;

  /// Ruta del asset local (`assets/images/ejercicios/...`) o URL `http(s)`.
  final String ruta;

  const ExerciseMedia(this.tipo, this.ruta);

  const ExerciseMedia.imagen(this.ruta) : tipo = ExerciseMediaType.imagen;
  const ExerciseMedia.gif(this.ruta) : tipo = ExerciseMediaType.gif;
  const ExerciseMedia.video(this.ruta) : tipo = ExerciseMediaType.video;

  bool get esRemoto => ruta.startsWith('http://') || ruta.startsWith('https://');

  static ExerciseMedia? fromJson(Object? json) {
    if (json is! Map) return null;
    final ruta = json['ruta'];
    if (ruta is! String || ruta.isEmpty) return null;
    final tipo = ExerciseMediaType.values.firstWhere(
      (t) => t.name == json['tipo'],
      orElse: () => ExerciseMediaType.imagen,
    );
    return ExerciseMedia(tipo, ruta);
  }

  Map<String, dynamic> toJson() => {'tipo': tipo.name, 'ruta': ruta};

  @override
  bool operator ==(Object other) =>
      other is ExerciseMedia && other.tipo == tipo && other.ruta == ruta;

  @override
  int get hashCode => Object.hash(tipo, ruta);
}
