import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Paleta moderna (cor base dinâmica)
    colorSchemeSeed: const Color(0xFF4C6FFF),

    scaffoldBackgroundColor: const Color(0xFFF3F4F8),

    fontFamily: "Inter",

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1C1E),
      ),
      iconTheme: IconThemeData(color: Color(0xFF1A1C1E)),
    ),

    // Estilo de card ultramoderno (Glass)
    cardTheme: CardThemeData(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),

      color: const Color.fromRGBO(255, 255, 255, 0.75),

      shadowColor: const Color.fromRGBO(0, 0, 0, 0.07),
      surfaceTintColor: Colors.transparent,
    ),

    // Botões com design de 2025
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF4C6FFF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),

      hintStyle: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 15,
      ),
    ),
  );
}
