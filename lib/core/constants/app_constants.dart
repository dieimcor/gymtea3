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
  static const int strengtheningeries = 3;
  static const int strengtheningReps = 10;

  // Progresión
  static const int maxProgressionLevel = 7;
  static const int minProgressionLevel = 1;
  static const int evaluationExerciseCount = 5;
  static const int minEvaluationScore = 5;
  static const int maxEvaluationScore = 20;

  // Clasificación control motor
  static const int lowControlMax = 10;
  static const int moderateControlMax = 15;
  // 16-20 = Alto control

  // Categorías de ejercicios
  static const List<String> exerciseCategories = [
    'RD', // Rodilla Dominante
    'CD', // Cadera Dominante
    'EM', // Empuje
    'JL', // Jalón
    'CR', // Core
  ];

  // Storage keys
  static const String tokenKey = 'jwt_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
}
