import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';

class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const _themePrefKey = 'user_theme_mode';

  ThemeMode _themeMode = ThemeMode.dark;
  Brightness _systemBrightness = Brightness.dark;

  ThemeProvider() {
    WidgetsBinding.instance.addObserver(this);
    _systemBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    AppTheme.systemIsDark = (_systemBrightness == Brightness.dark);
    AppTheme.themeMode = _themeMode;
  }

  ThemeMode get themeMode => _themeMode;
  Brightness get systemBrightness => _systemBrightness;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return _systemBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void updateSystemBrightness(Brightness brightness) {
    _systemBrightness = brightness;
    AppTheme.systemIsDark = (_systemBrightness == Brightness.dark);
    if (_themeMode == ThemeMode.system) {
      notifyListeners();
    }
  }

  @override
  void didChangePlatformBrightness() {
    _systemBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    AppTheme.systemIsDark = (_systemBrightness == Brightness.dark);
    if (_themeMode == ThemeMode.system) {
      notifyListeners();
    }
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themePrefKey);
    if (savedMode == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedMode == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.dark;
    }
    AppTheme.themeMode = _themeMode;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    AppTheme.themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    String modeString = 'dark';
    if (mode == ThemeMode.light) {
      modeString = 'light';
    } else if (mode == ThemeMode.system) {
      modeString = 'system';
    }
    await prefs.setString(_themePrefKey, modeString);
  }

  Future<void> toggleTheme() async {
    if (isDarkMode) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
