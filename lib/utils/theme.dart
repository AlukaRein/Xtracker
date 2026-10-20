import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Theme state
  static ThemeMode themeMode = ThemeMode.dark;
  static bool systemIsDark = true;

  static bool get isDark {
    if (themeMode == ThemeMode.system) return systemIsDark;
    return themeMode == ThemeMode.dark;
  }

  // ── Dark Palette (Obsidian Deep Luxury) ──────────────────────────────────
  static const darkBg           = Color(0xFF080A0F);
  static const darkSurface      = Color(0xFF0E1118);
  static const darkSurfaceHigh  = Color(0xFF141820);
  static const darkSurfaceGlass = Color(0xFF1A2030);
  static const darkBorder       = Color(0xFF1F2535);
  static const darkBorderGlow   = Color(0xFF2E3A52);

  static const darkPrimary      = Color(0xFFE8B84B);
  static const darkPrimaryLight = Color(0xFFF5D07A);
  static const darkAccent       = Color(0xFF00D4AA);

  static const darkTextPrimary   = Color(0xFFF0F2F8);
  static const darkTextSecondary = Color(0xFF7D8BA8);
  static const darkTextMuted     = Color(0xFF3D4560);

  static const darkSuccess      = Color(0xFF22D3A5);
  static const darkDanger       = Color(0xFFFF5F6D);

  static const darkAcrylicBg        = Color(0xCC0E1118);
  static const darkAcrylicBorder    = Color(0x28FFFFFF);
  static const darkAcrylicHighlight = Color(0x15FFFFFF);

  // ── Light Palette (Clean Modern Luxury) ─────────────────────────────────
  static const lightBg           = Color(0xFFF6F8FC);
  static const lightSurface      = Color(0xFFFFFFFF);
  static const lightSurfaceHigh  = Color(0xFFFFFFFF);
  static const lightSurfaceGlass = Color(0xFFEFF2F7);
  static const lightBorder       = Color(0xFFE2E8F0);
  static const lightBorderGlow   = Color(0xFFCBD5E1);

  static const lightPrimary      = Color(0xFFD97706); // Amber 600
  static const lightPrimaryLight = Color(0xFFF59E0B); // Amber 500
  static const lightAccent       = Color(0xFF0D9488); // Teal 600

  static const lightTextPrimary   = Color(0xFF0F172A); // Slate 900
  static const lightTextSecondary = Color(0xFF475569); // Slate 600
  static const lightTextMuted     = Color(0xFF94A3B8); // Slate 400

  static const lightSuccess      = Color(0xFF10B981); // Emerald 500
  static const lightDanger       = Color(0xFFEF4444); // Red 500

  static const lightAcrylicBg        = Color(0xDDFFFFFF);
  static const lightAcrylicBorder    = Color(0x33CBD5E1);
  static const lightAcrylicHighlight = Color(0x80FFFFFF);

  // ── Dynamic Getters ──────────────────────────────────────────────────────
  static Color get bg => isDark ? darkBg : lightBg;
  static Color get surface => isDark ? darkSurface : lightSurface;
  static Color get surfaceHigh => isDark ? darkSurfaceHigh : lightSurfaceHigh;
  static Color get surfaceGlass => isDark ? darkSurfaceGlass : lightSurfaceGlass;
  static Color get border => isDark ? darkBorder : lightBorder;
  static Color get borderGlow => isDark ? darkBorderGlow : lightBorderGlow;

  static Color get primary => isDark ? darkPrimary : lightPrimary;
  static Color get primaryLight => isDark ? darkPrimaryLight : lightPrimaryLight;
  static Color get accent => isDark ? darkAccent : lightAccent;

  static Color get textPrimary => isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary => isDark ? darkTextSecondary : lightTextSecondary;
  static Color get textMuted => isDark ? darkTextMuted : lightTextMuted;

  static Color get success => isDark ? darkSuccess : lightSuccess;
  static Color get danger => isDark ? darkDanger : lightDanger;

  // Acrylic specific
  static Color get acrylicBg => isDark ? darkAcrylicBg : lightAcrylicBg;
  static Color get acrylicBorder => isDark ? darkAcrylicBorder : lightAcrylicBorder;
  static Color get acrylicHighlight => isDark ? darkAcrylicHighlight : lightAcrylicHighlight;

  // Category chart colors
  static const List<Color> chartColors = [
    Color(0xFFE8B84B), // 0 - Makan
    Color(0xFF00D4AA), // 1 - Transport
    Color(0xFFFF7B54), // 2 - Belanja
    Color(0xFFAD7BFF), // 3 - Hiburan
    Color(0xFF54AEFF), // 4 - Kesehatan
    Color(0xFF3DE0A4), // 5 - Tagihan
    Color(0xFFF06292), // 6 - Pendidikan
    Color(0xFFFFB341), // 7 - Bensin
    Color(0xFF64B5F6), // 8 - Game
    Color(0xFFFF8A65), // 9 - Lainnya
  ];

  static Color getCategoryColor(String category, List<String> allCategories) {
    final idx = allCategories.indexOf(category);
    if (idx < 0) return chartColors[0];
    return chartColors[idx % chartColors.length];
  }

  // Backward compatibility
  static ThemeData get theme => isDark ? darkTheme : lightTheme;

  // ── Dark Theme Data ──────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    primaryColor: darkPrimary,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkAccent,
      surface: darkSurface,
      error: darkDanger,
    ),
    textTheme: GoogleFonts.soraTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: darkTextPrimary,
      displayColor: darkTextPrimary,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: darkSurface,
      foregroundColor: darkTextPrimary,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: darkSurfaceHigh,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: darkPrimary,
      foregroundColor: Colors.black,
      elevation: 12,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceGlass,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkPrimary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: darkTextSecondary),
      hintStyle: const TextStyle(color: darkTextMuted),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: darkPrimary,
      unselectedItemColor: darkTextMuted,
    ),
    dividerTheme: const DividerThemeData(
      color: darkBorder,
      thickness: 1,
    ),
  );

  // ── Light Theme Data ─────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    primaryColor: lightPrimary,
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      secondary: lightAccent,
      surface: lightSurface,
      error: lightDanger,
    ),
    textTheme: GoogleFonts.soraTextTheme(
      ThemeData.light().textTheme,
    ).apply(
      bodyColor: lightTextPrimary,
      displayColor: lightTextPrimary,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: lightSurface,
      foregroundColor: lightTextPrimary,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: lightSurfaceHigh,
      elevation: 0,
      shadowColor: const Color(0x0A0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: lightBorder, width: 1),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: lightPrimary,
      foregroundColor: Colors.white,
      elevation: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurfaceGlass,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lightPrimary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: lightTextSecondary),
      hintStyle: const TextStyle(color: lightTextMuted),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightSurface,
      selectedItemColor: lightPrimary,
      unselectedItemColor: lightTextMuted,
    ),
    dividerTheme: const DividerThemeData(
      color: lightBorder,
      thickness: 1,
    ),
  );
}

class AppIcons {
  static const categoryIcons = {
    'Makan'      : 'assets/icons/food.png',
    'Transport'  : 'assets/icons/transport.png',
    'Belanja'    : 'assets/icons/shopping.png',
    'Hiburan'    : 'assets/icons/entertainment.png',
    'Kesehatan'  : 'assets/icons/health.png',
    'Tagihan'    : 'assets/icons/bill.png',
    'Pendidikan' : 'assets/icons/education.png',
    'Bensin'     : 'assets/icons/fuel.png',
    'Game'       : 'assets/icons/game.png',
    'Lainnya'    : 'assets/icons/other.png',
  };

  static String getIcon(String category) {
    return categoryIcons[category] ?? 'assets/icons/category.png';
  }
}
