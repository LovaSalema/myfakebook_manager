import 'package:flutter/material.dart';

/// Application-wide constants and design system values
/// Clean, professional design system for music chord grid application
class AppConstants {
  // Spacing system (4px base unit)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 24.0;
  static const double spacingXXL = 32.0;
  static const double spacingXXXL = 48.0;

  // Border radius
  static const double borderRadiusS = 8.0;
  static const double borderRadiusM = 12.0;
  static const double borderRadiusL = 16.0;
  static const double borderRadiusXL = 24.0;

  // Shadow levels
  static const List<BoxShadow> shadowSubtle = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> shadowProminent = [
    BoxShadow(color: Color(0x4D000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Layout constraints
  static const double maxContentWidth = 1200.0;
  static const double sidePanelWidth = 320.0;
  static const double bottomSheetHeight = 400.0;

  // Chord grid specific constants
  static const double measureWidth = 120.0;
  static const double measureHeight = 80.0;
  static const double chordTextSize = 18.0;
  static const double sectionHeaderHeight = 48.0;
  static const int measuresPerRow = 4;

  // App bar and navigation
  static const double appBarHeight = 64.0;
  static const double navigationRailWidth = 72.0;
  static const double bottomNavigationHeight = 80.0;

  // Card dimensions
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 12.0;
  static const double cardPadding = 16.0;

  // Button dimensions
  static const double buttonHeightSmall = 32.0;
  static const double buttonHeightMedium = 40.0;
  static const double buttonHeightLarge = 48.0;
  static const double buttonBorderRadius = 8.0;

  // Input field dimensions
  static const double inputFieldHeight = 48.0;
  static const double inputFieldBorderRadius = 8.0;
  static const double inputFieldPadding = 12.0;

  // Icon sizes
  static const double iconSizeXS = 16.0;
  static const double iconSizeS = 20.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 40.0;

  // Typography scale
  static const double fontSizeXS = 10.0;
  static const double fontSizeS = 12.0;
  static const double fontSizeM = 14.0;
  static const double fontSizeL = 16.0;
  static const double fontSizeXL = 20.0;
  static const double fontSizeXXL = 24.0;
  static const double fontSizeXXXL = 32.0;

  // Image export dimensions
  static const int imageWidth = 1200;
  static const int imageHeight = 1600;

  // Default song values
  static const String defaultKey = 'C';
  static const String defaultTimeSignature = '4/4';
  static const int defaultTempo = 120;

  // Export formats
  static const List<String> exportFormats = ['pdf', 'png', 'jpg'];

  // Regex patterns
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp urlRegex = RegExp(
    r'^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$',
  );

  // App metadata
  static const String appName = 'MyFakeBook';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Professional Music Chord Grid Manager';
  static const String appAuthor = 'MyFakeBook Team';

  // File and export constants
  static const String defaultFileName = 'chord_grid';
  static const String pdfExtension = '.pdf';
  static const String imageExtension = '.png';
  static const String jsonExtension = '.json';
  static const String backupExtension = '.mfb';

  static const double pdfPageWidth = 595.0; // A4 width in points
  static const double pdfPageHeight = 842.0; // A4 height in points
  static const double pdfMargin = 40.0;

  // Database constants
  static const String databaseName = 'myfakebook.db';
  static const int databaseVersion = 1;

  // Validation constants
  static const int maxSongTitleLength = 100;
  static const int maxArtistNameLength = 100;
  static const int maxSectionNameLength = 50;
  static const int maxChordLength = 20;
  static const int maxMeasuresPerSection = 32;

  // Performance constants
  static const int debounceDelay = 300; // milliseconds
  static const int autoSaveDelay = 2000; // milliseconds
  static const int searchDelay = 500; // milliseconds

  // Feature flags
  static const bool enableDarkMode = true;
  static const bool enableExport = true;
  static const bool enableSharing = true;
  static const bool enableBackup = true;
  static const bool enableAnalytics = false;

  // URLs and external links
  static const String privacyPolicyUrl = 'https://example.com/privacy';
  static const String termsOfServiceUrl = 'https://example.com/terms';
  static const String supportEmail = 'support@myfakebook.com';
  static const String websiteUrl = 'https://myfakebook.com';

  // API Keys
  static const String cloudConvertApiKey =
      'VOTRE_CLE_API'; // Replace with actual API key

  // Helper methods
  static double getResponsiveSpacing(double baseSpacing) {
    return baseSpacing;
  }

  static double getChordGridWidth(int measuresCount) {
    return measuresCount * measureWidth + ((measuresCount - 1) * spacingM);
  }

  static bool isTabletSize(double width) {
    return width >= 768.0;
  }

  static bool isDesktopSize(double width) {
    return width >= 1024.0;
  }

  static String getExportFileName(String baseName, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${baseName}_$timestamp$extension';
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  static bool isValidFileName(String fileName) {
    if (fileName.isEmpty) return false;
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    return !invalidChars.hasMatch(fileName);
  }

  // Date and time formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Localization keys
  static const String localeFr = 'fr';
  static const String localeEn = 'en';
  static const String defaultLocale = 'en';

  // Error messages
  static const String errorGeneric = 'An error occurred';
  static const String errorNetwork = 'Network connection failed';
  static const String errorFileNotFound = 'File not found';
  static const String errorPermissionDenied = 'Permission denied';
  static const String errorInvalidChord = 'Invalid chord format';
  static const String errorExportFailed = 'Export failed';
  static const String errorSaveFailed = 'Save failed';

  // Success messages
  static const String successSaved = 'Saved successfully';
  static const String successExported = 'Exported successfully';
  static const String successShared = 'Shared successfully';
  static const String successBackupCreated = 'Backup created successfully';

  // Loading messages
  static const String loadingExport = 'Exporting...';
  static const String loadingSave = 'Saving...';
  static const String loadingBackup = 'Creating backup...';
  static const String loadingShare = 'Sharing...';
}
