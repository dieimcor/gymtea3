import 'package:flutter/material.dart';

/// Tema centralizado de NeuroGym
class AppTheme {
  AppTheme._();

  // Colores principales
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color accentTeal = Color(0xFF00897B);
  static const Color backgroundDark = Color(0xFF0D1B2A);
  static const Color surfaceDark = Color(0xFF1B2838);
  static const Color textLight = Color(0xFFE0E0E0);
  static const Color goldAccent = Color(0xFFFFD54F);

  // Colores de niveles de progresión
  static const Color levelLow = Color(0xFFE53935);      // Bajo control
  static const Color levelModerate = Color(0xFFFDD835);  // Moderado
  static const Color levelHigh = Color(0xFF43A047);      // Alto control

  // Colores de categorías de ejercicios
  static const Color categoryRD = Color(0xFF1565C0);  // Rodilla Dominante
  static const Color categoryCD = Color(0xFF2E7D32);  // Cadera Dominante
  static const Color categoryEM = Color(0xFFE65100);  // Empuje
  static const Color categoryJL = Color(0xFF6A1B9A);  // Jalón
  static const Color categoryCR = Color(0xFFC62828);  // Core

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryGreen,
        secondary: accentTeal,
        surface: surfaceDark,
        // ignore: deprecated_member_use
        background: backgroundDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        labelStyle: const TextStyle(color: textLight),
      ),
    );
  }
}
