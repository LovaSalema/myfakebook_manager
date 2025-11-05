import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Application theme configuration
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: Color(AppColors.primary),
        primaryContainer: Color(AppColors.primaryDark),
        secondary: Color(AppColors.secondary),
        secondaryContainer: Color(AppColors.secondaryDark),
        background: Color(AppColors.background),
        surface: Color(AppColors.surface),
        onSurface: Color(AppColors.onSurface),
        onBackground: Color(AppColors.onBackground),
        error: Color(AppColors.error),
      ),
      scaffoldBackgroundColor: Color(AppColors.background),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(AppColors.primary),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(AppColors.borderMedium)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(AppColors.borderLight)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(AppColors.primary)),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(AppColors.primary),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Color(AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(AppColors.secondary),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: Color(AppColors.borderLight),
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: Color(AppColors.primaryLight),
        primaryContainer: Color(AppColors.primary),
        secondary: Color(AppColors.secondaryLight),
        secondaryContainer: Color(AppColors.secondary),
        background: Color(AppColors.backgroundDark),
        surface: Color(AppColors.surfaceDark),
        onSurface: Color(AppColors.onSurfaceDark),
        onBackground: Color(AppColors.onBackgroundDark),
      ),
      scaffoldBackgroundColor: Color(AppColors.backgroundDark),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(AppColors.surfaceDark),
        foregroundColor: Color(AppColors.onSurfaceDark),
        elevation: 2,
        centerTitle: true,
      ),
    );
  }
}
