import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0C1228);
  static const bgDeep = Color(0xFF06091A);
  static const panel = Color(0xFF141B3A);
  static const panelLight = Color(0xFF1D2750);

  static const parchment = Color(0xFFEDE0C0);
  static const parchmentDeep = Color(0xFFCFB98C);
  static const parchmentLight = Color(0xFFF8EED0);
  static const parchmentMid = Color(0xFFE6CF95);

  static const ink = Color(0xFFE8DCB8);
  static const inkDark = Color(0xFF1C1A2C);
  static const inkSoft = Color(0xFF9AA4C6);
  static const inkSoftDark = Color(0xFF5A4F3C);

  static const seal = Color(0xFF8A3A3A);
  static const sealDeep = Color(0xFF5A2424);
  static const sealLight = Color(0xFFA04848);

  static const gold = Color(0xFFB89752);
  static const goldLight = Color(0xFFD4B97A);
  static const goldDeep = Color(0xFF7E6228);
  static const goldGlow = Color(0xFFE2B864);

  static const line = Color(0xFF2E3760);
  static const win = Color(0xFFB89752);
  static const lose = Color(0xFF5D5470);
  static const starlight = Color(0xFF7A87B0);

  // legacy aliases for backwards compat in unmodified call sites
  static const goldDark = goldDeep;
  static const sapphire = panelLight;
  static const ruby = seal;
  static const amethyst = panel;
  static const amethystLight = panelLight;
  static const textPrimary = ink;
  static const textSecondary = inkSoft;
  static const backgroundStart = bg;
  static const backgroundEnd = bgDeep;
  static const cardWhite = parchmentLight;
}

class AppFonts {
  static const cinzel = 'Cinzel';
  static const eb = 'EB Garamond';
  static const cormorant = 'Cormorant Garamond';
  static const mincho = 'Hiragino Mincho ProN';
}

ThemeData gameTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.seal,
        surface: AppColors.panel,
        onSurface: AppColors.ink,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: AppFonts.mincho,
          fontWeight: FontWeight.w800,
          letterSpacing: 6,
          color: AppColors.goldLight,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppFonts.mincho,
          fontWeight: FontWeight.w700,
          letterSpacing: 4,
          color: AppColors.goldLight,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppFonts.mincho,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
          color: AppColors.goldLight,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppFonts.mincho,
          color: AppColors.ink,
        ),
        bodySmall: TextStyle(
          fontFamily: AppFonts.mincho,
          color: AppColors.inkSoft,
        ),
      ),
    );

class GameConstants {
  static const int maxCpuStages = 3;
  static const int maxOnlineBattles = 3;
  static const int timeoutSeconds = 60;
}

class AppScale {
  static const double _baseWidth = 393.0;
  static double of(BuildContext context) {
    return (MediaQuery.of(context).size.width / _baseWidth).clamp(0.75, 1.2);
  }
}
