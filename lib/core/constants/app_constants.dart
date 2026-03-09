/// Constantes globales de la aplicación NeuroGym
class AppConstants {
  AppConstants._();

  // API
  static const String apiBaseUrl = 'http://localhost:3000/api'; // TODO: cambiar en producción
  static const String apiVersion = 'v1';

  // App
  static const String appName = 'NeuroGym';
  static const String appVersion = '1.0.0';

  // Sesión de ejercicios (valores por defecto)
  static const int defaultSessionDurationMin = 15;
  static const int activationDurationMin = 2;
  static const int strengtheningDurationMin = 8;
  static const int gameDurationMin = 5;

  // Series y repeticiones por defecto
  static const int activationSeries = 2;
  static const int activationReps = 15;
  static const int strengtheningSeries = 3;
  static const int strengtheningReps = 10;

  // Evaluación funcional
  static const int evaluationExerciseCount = 5;
  static const int minEvaluationScore = 5;
  static const int maxEvaluationScore = 20;

  // Clasificación control motor (umbrales)
  static const int lowControlMax = 10;
  static const int moderateControlMax = 15;
  // 16-20 = Alto control

  // Nivel de progresión — SIN LÍMITE FIJO.
  // El nivel mínimo inicial siempre es 1.
  // El máximo lo define el catálogo del backend (puede crecer).
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
  };

  // Storage keys
  static const String tokenKey = 'jwt_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
}
