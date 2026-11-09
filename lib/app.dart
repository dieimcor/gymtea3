import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymtea3/core/theme/app_theme.dart';

// Providers
import 'package:gymtea3/presentation/providers/auth_provider.dart';
import 'package:gymtea3/presentation/providers/exercise_provider.dart';
import 'package:gymtea3/presentation/providers/progress_provider.dart';

// Services & Repositories
import 'package:gymtea3/data/services/auth_service.dart';
import 'package:gymtea3/data/services/storage_service.dart';
import 'package:gymtea3/data/services/level_progress_service.dart';
import 'package:gymtea3/data/repositories/auth_repository.dart';
import 'package:gymtea3/data/repositories/exercise_repository.dart';
import 'package:gymtea3/data/repositories/progress_repository.dart';

// Screens
import 'package:gymtea3/presentation/screens/splash/splash_screen.dart';
import 'package:gymtea3/presentation/screens/auth/login_screen.dart';
import 'package:gymtea3/presentation/screens/home/crater_map_screen.dart';
import 'package:gymtea3/presentation/screens/exercises/exercise_session_screen.dart';
import 'package:gymtea3/presentation/screens/exercises/rating_screen.dart';
import 'package:gymtea3/presentation/screens/minigames/minigames_screen.dart';

/// NeuroGym — App principal con MultiProvider y rutas nombradas
class NeuroGymApp extends StatelessWidget {
  final StorageService storageService;

  const NeuroGymApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository: AuthRepository(
              authService: AuthService(),
              storageService: storageService,
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ExerciseProvider(
            exerciseRepository: ExerciseRepository(),
            levelProgressService: LevelProgressService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProgressProvider(
            progressRepository: ProgressRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'NeuroGym',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,

        // Ruta inicial
        initialRoute: '/splash',

        // Rutas nombradas
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),

          // El mapa de cráteres es ahora la pantalla principal.
          '/home': (context) => const CraterMapScreen(),

          '/exercises/session': (context) => const ExerciseSessionScreen(),
          RatingScreen.routeName: (context) => const RatingScreen(),
          MinigamesScreen.routeName: (context) => const MinigamesScreen(),
        },
      ),
    );
  }
}
