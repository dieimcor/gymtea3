import 'package:flutter/material.dart';

import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/presentation/widgets/bouncy_tap.dart';

/// Minijuegos — disponibles para todos los perfiles, sin sync con backend.
class MinigamesScreen extends StatelessWidget {
  static const routeName = '/minigames';

  const MinigamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Minijuegos'),
        leading: BouncyTap(
          child: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // El ícono aparece con un rebote juguetón.
              _entrance(
                durationMs: 900,
                curve: Curves.elasticOut,
                scaleFrom: 0.2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.accentTeal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sports_esports_rounded,
                    size: 64,
                    color: AppTheme.accentTeal,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _entrance(
                delayMs: 250,
                child: const Text(
                  'Minijuegos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _entrance(
                delayMs: 400,
                child: Text(
                  'Juegos educativos de higiene, orden,\nautonomía y alimentación.\n\nPróximamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppTheme.textLight.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Entrada suave (fundido + subida + escala); el retraso se simula con
  /// [Interval] para no usar timers.
  static Widget _entrance({
    required Widget child,
    int delayMs = 0,
    int durationMs = 600,
    Curve curve = Curves.easeOutCubic,
    double scaleFrom = 0.92,
  }) {
    final total = delayMs + durationMs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delayMs / total, 1, curve: curve),
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 16),
          child: Transform.scale(
            scale: scaleFrom + (1 - scaleFrom) * v,
            child: child,
          ),
        ),
      ),
      child: child,
    );
  }
}
