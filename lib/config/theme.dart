import 'package:flutter/material.dart';

class AppColors {
  static const gold = Color(0xFFC9A84C);
  static const goldLight = Color(0xFFE8D48B);
  static const goldDark = Color(0xFFB8943F);
  static const sapphire = Color(0xFF2B4C8C);
  static const ruby = Color(0xFFC0392B);
  static const amethyst = Color(0xFF6C3D91);
  static const amethystLight = Color(0xFF8B5CB5);
  static const textPrimary = Color(0xFF1A1A3E);
  static const textSecondary = Color(0xFF5D5A72);
  static const backgroundStart = Color(0xFFF5F0EB);
  static const backgroundEnd = Color(0xFFE8E0F0);
  static const cardWhite = Color(0xFFFFFEF9);
}

ThemeData gameTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundStart,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.sapphire,
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: AppColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
