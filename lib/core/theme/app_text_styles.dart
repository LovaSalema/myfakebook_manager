import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Professional typography system for music chord grid application
/// Modern, clean fonts optimized for musical readability
class AppTextStyles {
  // Headline styles - Inter font family
  static TextStyle get headline1 {
    return GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: Color(AppColors.onBackgroundLight),
    );
  }

  static TextStyle get headline2 {
    return GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: Color(AppColors.onBackgroundLight),
    );
  }

  static TextStyle get headline3 {
    return GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: Color(AppColors.onBackgroundLight),
    );
  }

  // Body text styles - Inter font family
  static TextStyle get body1 {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: Color(AppColors.onBackgroundLight),
    );
  }

  static TextStyle get body2 {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: Color(AppColors.onBackgroundLight),
    );
  }

  static TextStyle get body3 {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: Color(AppColors.onBackgroundLight),
    );
  }

  // Button text styles
  static TextStyle get buttonLarge {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      color: Color(AppColors.onPrimary),
    );
  }

  static TextStyle get buttonMedium {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.5,
      color: Color(AppColors.onPrimary),
    );
  }

  static TextStyle get buttonSmall {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.5,
      color: Color(AppColors.onPrimary),
    );
  }

  // Caption and label styles
  static TextStyle get caption {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: Color(AppColors.textSecondary),
    );
  }

  static TextStyle get label {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: Color(AppColors.textSecondary),
    );
  }

  static TextStyle get overline {
    return GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      height: 1.5,
      letterSpacing: 1.5,
      color: Color(AppColors.textSecondary),
    );
  }

  // Music-specific text styles
  static TextStyle get chordText {
    return GoogleFonts.jetBrainsMono(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: Color(AppColors.onBackgroundLight),
    );
  }

  static TextStyle get chordTextSmall {
    return GoogleFonts.jetBrainsMono(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.2,
      color: Color(AppColors.onBackgroundLight),
    );
  }

  static TextStyle get sectionTitle {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: Color(AppColors.primary),
    );
  }

  static TextStyle get measureLabel {
    return GoogleFonts.jetBrainsMono(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.2,
      color: Color(AppColors.textSecondary),
    );
  }

  static TextStyle get musicalSymbol {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.2,
      color: Color(AppColors.onBackgroundLight),
    );
  }

  // Dark theme variants
  static TextStyle get headline1Dark {
    return GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: Color(AppColors.onBackgroundDark),
    );
  }

  static TextStyle get body1Dark {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: Color(AppColors.onBackgroundDark),
    );
  }

  static TextStyle get chordTextDark {
    return GoogleFonts.jetBrainsMono(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: Color(AppColors.onBackgroundDark),
    );
  }

  // Semantic text styles
  static TextStyle get successText {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: Color(AppColors.success),
    );
  }

  static TextStyle get warningText {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: Color(AppColors.warning),
    );
  }

  static TextStyle get errorText {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: Color(AppColors.error),
    );
  }

  static TextStyle get infoText {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: Color(AppColors.info),
    );
  }

  // Legacy styles for backward compatibility
  static TextStyle get headlineSmall => headline3;
  static TextStyle get titleLarge => headline2;
  static TextStyle get titleMedium => headline3;
  static TextStyle get bodyMedium => body1;
  static TextStyle get labelMedium => label;
  static TextStyle get labelSmall => caption;
  static TextStyle get sectionHeader => sectionTitle;
  static TextStyle get measureNumber => measureLabel;

  // Theme-aware text styles
  static TextStyle headline1Theme(BuildContext context) {
    return headline1.copyWith(color: Theme.of(context).colorScheme.onSurface);
  }

  static TextStyle headline2Theme(BuildContext context) {
    return headline2.copyWith(color: Theme.of(context).colorScheme.onSurface);
  }

  static TextStyle headline3Theme(BuildContext context) {
    return headline3.copyWith(color: Theme.of(context).colorScheme.onSurface);
  }

  static TextStyle body1Theme(BuildContext context) {
    return body1.copyWith(color: Theme.of(context).colorScheme.onSurface);
  }

  static TextStyle body2Theme(BuildContext context) {
    return body2.copyWith(color: Theme.of(context).colorScheme.onSurface);
  }

  static TextStyle body3Theme(BuildContext context) {
    return body3.copyWith(color: Theme.of(context).colorScheme.onSurface);
  }

  static TextStyle chordTextTheme(BuildContext context) {
    return chordText.copyWith(color: Theme.of(context).colorScheme.onSurface);
  }

  static TextStyle chordTextSmallTheme(BuildContext context) {
    return chordTextSmall.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle musicalSymbolTheme(BuildContext context) {
    return musicalSymbol.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}
