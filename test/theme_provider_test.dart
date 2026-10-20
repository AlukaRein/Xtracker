import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/providers/theme_provider.dart';
import 'package:expense_tracker/utils/theme.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeProvider & AppTheme Tests', () {
    test('Default mode is dark and loads initial palette correctly', () async {
      final provider = ThemeProvider();
      await provider.loadTheme();

      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDarkMode, isTrue);
      expect(AppTheme.isDark, isTrue);
      expect(AppTheme.bg, AppTheme.darkBg);
      expect(AppTheme.surface, AppTheme.darkSurface);
      expect(AppTheme.primary, AppTheme.darkPrimary);
      expect(AppTheme.acrylicBg, AppTheme.darkAcrylicBg);
    });

    test('Switching to light mode updates AppTheme getters and persists', () async {
      final provider = ThemeProvider();
      await provider.setThemeMode(ThemeMode.light);

      expect(provider.themeMode, ThemeMode.light);
      expect(provider.isDarkMode, isFalse);
      expect(AppTheme.isDark, isFalse);
      expect(AppTheme.bg, AppTheme.lightBg);
      expect(AppTheme.surface, AppTheme.lightSurface);
      expect(AppTheme.primary, AppTheme.lightPrimary);
      expect(AppTheme.acrylicBg, AppTheme.lightAcrylicBg);

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_theme_mode'), 'light');

      // Verify new provider instance loads persisted light theme
      final newProvider = ThemeProvider();
      await newProvider.loadTheme();
      expect(newProvider.themeMode, ThemeMode.light);
      expect(AppTheme.isDark, isFalse);
    });

    test('Toggle theme switches between dark and light', () async {
      final provider = ThemeProvider();
      await provider.setThemeMode(ThemeMode.dark);
      expect(provider.isDarkMode, isTrue);

      await provider.toggleTheme();
      expect(provider.isDarkMode, isFalse);
      expect(AppTheme.isDark, isFalse);

      await provider.toggleTheme();
      expect(provider.isDarkMode, isTrue);
      expect(AppTheme.isDark, isTrue);
    });

    test('System mode responds to system brightness changes', () async {
      final provider = ThemeProvider();
      await provider.setThemeMode(ThemeMode.system);

      provider.updateSystemBrightness(Brightness.light);
      expect(provider.isDarkMode, isFalse);
      expect(AppTheme.isDark, isFalse);
      expect(AppTheme.bg, AppTheme.lightBg);

      provider.updateSystemBrightness(Brightness.dark);
      expect(provider.isDarkMode, isTrue);
      expect(AppTheme.isDark, isTrue);
      expect(AppTheme.bg, AppTheme.darkBg);
    });

    testWidgets('ThemeData objects pump cleanly for both dark and light modes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: const Scaffold(),
        ),
      );
      expect(find.byType(Scaffold), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(),
        ),
      );
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
