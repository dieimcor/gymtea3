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
import 'package:gymtea3/data/repositories/auth_repository.dart';
import 'package:gymtea3/data/repositories/exercise_repository.dart';
import 'package:gymtea3/data/repositories/progress_repository.dart';

// Screens
import 'package:gymtea3/screens/splash_screen.dart';

/// NeuroGym — App principal
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
        home: const SplashScreen(),
        // TODO: Agregar rutas nombradas en Sprint 1
        // routes: {
        //   '/login': (context) => const LoginScreen(),
        //   '/home': (context) => const HomeScreen(),
        //   '/exercises': (context) => const LevelMapScreen(),
        //   '/profile': (context) => const ProfileScreen(),
        //   '/minigames': (context) => const MinigamesScreen(),
        // },
      ),
    );
  }
}
