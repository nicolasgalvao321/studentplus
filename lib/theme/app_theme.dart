import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: const Color(0xFF0E3B68), // Azul Académico
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0E3B68),
        secondary: const Color(0xFFFF6B00), // Laranja de destaque
        background: const Color(0xFFF5F7FA), // Cor de fundo
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0E3B68),
        foregroundColor: Colors.white,
      ),
      useMaterial3: true,
    );
  }
}