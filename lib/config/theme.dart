import 'package:flutter/material.dart';

class AppColors {
  // ── Ogiri minimal palette ──
  static const bg = Color(0xFFFBFBF9);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF191919);
  static const inkMid = Color(0xFF5C5C56);
  static const inkSoft = Color(0xFF9A9A94);
  static const line = Color(0xFFECECE8);

  static const yellow = Color(0xFFFDCB2E);
  static const yellowDeep = Color(0xFFF0B90C);
  static const yellowSoft = Color(0xFFFFF3C4);

  static const red = Color(0xFFE0342B);
  static const win = Color(0xFFE8A400);
  static const atk = Color(0xFFE0342B);
  static const def = Color(0xFF2F6DE0);

  static const dark = Color(0xFF0D1122);
  static const darkPanel = Color(0xFF171D33);

  // ── Legacy aliases (map old Arcane Codex names to new palette) ──
  static const bgDeep = bg;
  static const panel = card;
  static const panelLight = card;
  static const parchment = card;
  static const parchmentDeep = line;
  static const parchmentLight = card;
  static const parchmentMid = line;
  static const inkDark = ink;
  static const inkSoftDark = inkMid;
  static const seal = red;
  static const sealDeep = red;
  static const sealLight = red;
  static const gold = yellow;
  static const goldLight = yellow;
  static const goldDeep = yellowDeep;
  static const goldGlow = yellow;
  static const goldDark = yellowDeep;
  static const sapphire = card;
  static const ruby = red;
  static const amethyst = card;
  static const amethystLight = card;
  static const textPrimary = ink;
  static const textSecondary = inkMid;
  static const backgroundStart = bg;
  static const backgroundEnd = bg;
  static const cardWhite = card;
  static const lose = red;
  static const starlight = inkSoft;
}

class AppFonts {
  // iOS system Japanese gothic — closest match to Zen Kaku Gothic New without bundling
  static const gothic = 'Hiragino Sans';
  static const mono = 'Menlo';

  // legacy aliases
  static const cinzel = gothic;
  static const eb = gothic;
  static const cormorant = gothic;
  static const mincho = gothic;
}

ThemeData gameTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.yellow,
        secondary: AppColors.ink,
        surface: AppColors.card,
        onSurface: AppColors.ink,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: AppFonts.gothic,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppFonts.gothic,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppFonts.gothic,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppFonts.gothic,
          color: AppColors.ink,
        ),
        bodySmall: TextStyle(
          fontFamily: AppFonts.gothic,
          color: AppColors.inkMid,
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
