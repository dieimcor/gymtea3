// Define qué es un Ejercicio individual
class Ejercicio {
  final String nombre;
  final String imagenRuta; // Ruta de la imagen explicativa (ej: 'assets/brazos_arriba.png')
  final int duracionSegundos; // Por defecto serán 10s

  Ejercicio({
    required this.nombre,
    required this.imagenRuta,
    this.duracionSegundos = 10, // Valor por defecto
  });
}

// Define qué es un Nivel
class Nivel {
  final int id;
  final String nombre;
  bool estaDesbloqueado;
  int vecesCompletado; // Necesitamos que llegue a 2 para desbloquear el siguiente
  final List<Ejercicio> listaEjercicios;

  Nivel({
    required this.id,
    required this.nombre,
    this.estaDesbloqueado = false, // Por defecto bloqueado
    this.vecesCompletado = 0,
    required this.listaEjercicios,
  });

  // Una pequeña función para saber si el nivel ya se "dominó" (se jugó 2 veces)
  bool estaDominado() {
    return vecesCompletado >= 2;
  }
}