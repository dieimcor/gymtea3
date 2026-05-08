import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/presentation/providers/auth_provider.dart';

/// Splash Screen — verifica sesión y redirige
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animación de pulso para el logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    // Esperar mínimo 2 segundos para que se vea el splash
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final hasSession = await authProvider.checkSession();

    if (!mounted) return;

    if (hasSession) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundDark,
              AppTheme.surfaceDark,
              AppTheme.backgroundDark,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo con animación de pulso
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryGreen.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Image.asset(
                    'assets/images/petq.png',
                    height: 140,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback si no existe la imagen
                      return Icon(
                        Icons.fitness_center_rounded,
                        size: 100,
                        color: AppTheme.primaryGreen,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Nombre de la app
              const Text(
                'NeuroGym',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 8),

              // Subtítulo
              Text(
                'Fuerza y Juegos',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textLight.withValues(alpha: 0.7),
                  letterSpacing: 4,
                  fontWeight: FontWeight.w300,
                ),
              ),

              const SizedBox(height: 60),

              // Indicador de carga
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryGreen,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Preparando sesión...',
                style: TextStyle(
                  color: AppTheme.textLight.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
