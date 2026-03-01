import 'package:flutter/material.dart';

class FondoApp extends StatelessWidget {
  final Widget child;

  const FondoApp({super.key, required this.child}); // Corregido: super.key

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0B0F2F), // Azul espacial profundo (constante)
        image: DecorationImage(
          image: AssetImage("assets/images/background.png"), // Asegúrate que la imagen exista
          fit: BoxFit.cover,
          opacity: 0.6, // Manejo de opacidad directo en la imagen
        ),
      ),
      child: Stack(
        children: [
          // Capa de degradado sutil para mejorar lectura
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black45, // Corregido: uso de constante en vez de withOpacity
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