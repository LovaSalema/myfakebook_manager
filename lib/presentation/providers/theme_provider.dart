import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';

/// ThemeProvider for managing app theme with persistence
class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  SharedPreferences? _prefs;

  ThemeProvider() {
    _loadThemeMode();
  }

  // Getters
  ThemeMode get themeMode => _themeMode;

  /// Set theme mode and persist to SharedPreferences
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveThemeMode();
    notifyListeners();
  }

  /// Toggle between light and dark themes
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.system);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  /// Check if dark theme is currently active
  bool get isDarkMode {
    switch (_themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark;
    }
  }

  /// Get the current theme mode as string for display
  String get themeModeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Get the next theme mode for cycling
  ThemeMode get nextThemeMode {
    switch (_themeMode) {
      case ThemeMode.light:
        return ThemeMode.dark;
      case ThemeMode.dark:
        return ThemeMode.system;
      case ThemeMode.system:
        return ThemeMode.light;
    }
  }

  /// Get theme data based on current mode
  ThemeData get themeData {
    if (isDarkMode) {
      return _buildDarkTheme();
    } else {
      return _buildLightTheme();
    }
  }

  /// Load theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedMode = _prefs?.getString(_themeModeKey);

      if (savedMode != null) {
        switch (savedMode) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'system':
            _themeMode = ThemeMode.system;
            break;
          default:
            _themeMode = ThemeMode.system;
        }
        notifyListeners();
      }
    } catch (e) {
      print('Failed to load theme mode: $e');
      // Use system theme as fallback
      _themeMode = ThemeMode.system;
    }
  }

  /// Save theme mode to SharedPreferences
  Future<void> _saveThemeMode() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      String modeString;

      switch (_themeMode) {
        case ThemeMode.light:
          modeString = 'light';
          break;
        case ThemeMode.dark:
          modeString = 'dark';
          break;
        case ThemeMode.system:
          modeString = 'system';
          break;
      }

      await _prefs?.setString(_themeModeKey, modeString);
    } catch (e) {
      print('Failed to save theme mode: $e');
    }
  }

  /// Build light theme
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: Color(AppColors.primary),
        secondary: Color(AppColors.secondary),
        surface: Color(AppColors.surfaceLight),
        background: Color(AppColors.backgroundLight),
        error: Color(AppColors.error),
        onPrimary: Color(AppColors.onPrimary),
        onSecondary: Color(AppColors.onSecondary),
        onSurface: Color(AppColors.onSurfaceLight),
        onBackground: Color(AppColors.onBackgroundLight),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(AppColors.primary),
        foregroundColor: Color(AppColors.onPrimary),
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Color(AppColors.surfaceVariantLight),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(AppColors.primary),
        foregroundColor: Color(AppColors.onPrimary),
      ),
    );
  }

  /// Build dark theme
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: Color(AppColors.primaryLight),
        secondary: Color(AppColors.secondaryLight),
        surface: Color(AppColors.surfaceDark),
        background: Color(AppColors.backgroundDark),
        error: Color(AppColors.error),
        onPrimary: Color(AppColors.onPrimary),
        onSecondary: Color(AppColors.onSecondary),
        onSurface: Color(AppColors.onSurfaceDark),
        onBackground: Color(AppColors.onBackgroundDark),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(AppColors.surfaceDark),
        foregroundColor: Color(AppColors.onSurfaceDark),
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Color(AppColors.surfaceVariantDark),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(AppColors.primaryLight),
        foregroundColor: Color(AppColors.onPrimary),
      ),
    );
  }

  /// Reset to system theme
  Future<void> resetToSystem() async {
    await setThemeMode(ThemeMode.system);
  }

  /// Get theme mode icon
  IconData get themeModeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.auto_mode;
    }
  }

  /// Get theme mode description
  String get themeModeDescription {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light theme for bright environments';
      case ThemeMode.dark:
        return 'Dark theme for low-light environments';
      case ThemeMode.system:
        return 'Follows system theme settings';
    }
  }
}
