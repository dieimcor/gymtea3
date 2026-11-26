/// Constantes globales de la aplicación NeuroGym
class AppConstants {
  AppConstants._();

  // API
  static const String apiBaseUrl = 'http://localhost:3000/api'; // TODO: cambiar en producción
  static const String apiVersion = 'v1';

  // App
  static const String appName = 'NeuroGym';
  static const String appVersion = '1.0.0';

  // ------------------------------------------------------------
  // Rutina de ejercicios — valores FIJOS.
  // La pantalla de configuración de tiempos fue retirada a propósito:
  // el padre ya no elige duraciones, las define la dificultad del cráter.
  // ------------------------------------------------------------

  /// Duración por defecto de una serie (1 minuto). La real depende de la
  /// ruta elegida (`TrainingRoute.seriesSeconds`: 30 / 45 / 60 s).
  static const int exerciseSeconds = 60;

  /// Preparación antes de cada serie ("¡Prepárate!"). Los descansos no la
  /// tienen: arrancan solos.
  static const int prepSeconds = 5;

  /// Series por ejercicio en todas las dificultades.
  static const int seriesPerExercise = 2;

  /// Descanso base entre ejercicios y entre series (nivel fácil).
  /// Las dificultades superiores lo incrementan — ver [Dificultad].
  static const int baseRestSeconds = 20;

  // ------------------------------------------------------------
  // Mapa de cráteres
  // ------------------------------------------------------------

  /// Cráteres pintados en el sprite del cometa, o sea los niveles que se
  /// muestran por tanda. Al conquistarlos, los mismos cráteres se
  /// renumeran con los siguientes.
  static const int initialCraterCount = 4;

  /// Total de cráteres del mapa (1 por nivel de progresión).
  ///
  /// Multiplo de [initialCraterCount]: el cometa muestra 4 cráteres por
  /// tanda, asi que con 8 niveles quedan dos tandas completas.
  static const int totalCraterCount = 16;

  /// Cráteres de cada cometa: dos caras de [initialCraterCount]. Al
  /// terminar la primera cara el cometa "da la vuelta" (ver `CometTurn`);
  /// al terminar la segunda se viaja al siguiente cometa (`CometTravel`).
  static const int cratersPerComet = 8;

  /// Caras de cada cometa.
  static const int facesPerComet = cratersPerComet ~/ initialCraterCount;

  /// Nivel mínimo, siempre desbloqueado.
  static const int minProgressionLevel = 1;

  // Categorías iniciales del Manual de Fuerza y Juegos.
  // Son los valores por defecto; el backend puede agregar más
  // dinámicamente sin necesidad de actualizar la app.
  static const Map<String, String> defaultExerciseCategories = {
    'RD': 'Rodilla Dominante',
    'CD': 'Cadera Dominante',
    'EM': 'Empuje',
    'JL': 'Jalón',
    'CR': 'Core',
    'MOV': 'Movilidad y Juego',
  };

  // Storage keys
  static const String tokenKey = 'jwt_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  /// Ruta de entrenamiento elegida (`TrainingRoute.name`).
  static const String trainingRouteKey = 'training_route';

  /// Niveles completados al menos una vez. Se guarda por ruta: la clave
  /// real lleva el sufijo `_<ruta>`.
  static const String completedLevelsKey = 'completed_levels';

  /// Ids de ejercicios ya sorteados en la ronda actual (por ruta, con
  /// sufijo `_<ruta>`).
  static const String usedExerciseIdsKey = 'used_exercise_ids';

  // Acumulados de entrenamiento (sobreviven al reinicio de la app).
  static const String totalExercisesKey = 'total_exercises';
  static const String totalSecondsKey = 'total_seconds';
  static const String totalSessionsKey = 'total_sessions';
}
