import 'package:flutter/material.dart';
import 'package:gymtea3/core/theme/app_theme.dart';

/// Fondo de la aplicación con gradiente oscuro y imagen de fondo opcional
class FondoApp extends StatelessWidget {
  final Widget child;

  const FondoApp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundDark,
        image: DecorationImage(
          image: AssetImage("assets/images/background.png"),
          fit: BoxFit.cover,
          opacity: 0.4,
        ),
      ),
      child: Stack(
        children: [
          // Capa de degradado para mejorar lectura
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.backgroundDark.withValues(alpha: 0.3),
                  AppTheme.backgroundDark.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          // El contenido de la pantalla
          SafeArea(child: child),
        ],
      ),
    );
  }
}
