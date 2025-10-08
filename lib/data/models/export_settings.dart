/// Represents export configuration settings
class ExportSettings {
  final String format;
  final int quality;
  final String pageSize;
  final String orientation;
  final bool includeMetadata;
  final bool showMusicSymbols;
  final double fontSize;

  const ExportSettings({
    required this.format,
    required this.quality,
    required this.pageSize,
    required this.orientation,
    required this.includeMetadata,
    required this.showMusicSymbols,
    required this.fontSize,
  });

  /// Creates default export settings
  factory ExportSettings.defaultSettings() {
    return ExportSettings(
      format: 'PDF',
      quality: 90,
      pageSize: 'A4',
      orientation: 'PORTRAIT',
      includeMetadata: true,
      showMusicSymbols: true,
      fontSize: 12.0,
    );
  }

  /// Creates export settings for images
  factory ExportSettings.forImages() {
    return ExportSettings(
      format: 'PNG',
      quality: 95,
      pageSize: 'A4',
      orientation: 'PORTRAIT',
      includeMetadata: true,
      showMusicSymbols: true,
      fontSize: 14.0,
    );
  }

  /// Creates export settings for PDF
  factory ExportSettings.forPDF() {
    return ExportSettings(
      format: 'PDF',
      quality: 90,
      pageSize: 'A4',
      orientation: 'PORTRAIT',
      includeMetadata: true,
      showMusicSymbols: true,
      fontSize: 12.0,
    );
  }

  /// Converts ExportSettings to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'format': format,
      'quality': quality,
      'pageSize': pageSize,
      'orientation': orientation,
      'includeMetadata': includeMetadata,
      'showMusicSymbols': showMusicSymbols,
      'fontSize': fontSize,
    };
  }

  /// Creates ExportSettings from Map
  factory ExportSettings.fromMap(Map<String, dynamic> map) {
    return ExportSettings(
      format: map['format'] ?? 'PDF',
      quality: map['quality'] ?? 90,
      pageSize: map['pageSize'] ?? 'A4',
      orientation: map['orientation'] ?? 'PORTRAIT',
      includeMetadata: map['includeMetadata'] ?? true,
      showMusicSymbols: map['showMusicSymbols'] ?? true,
      fontSize: map['fontSize'] ?? 12.0,
    );
  }

  /// Creates a copy of the ExportSettings with updated fields
  ExportSettings copyWith({
    String? format,
    int? quality,
    String? pageSize,
    String? orientation,
    bool? includeMetadata,
    bool? showMusicSymbols,
    double? fontSize,
  }) {
    return ExportSettings(
      format: format ?? this.format,
      quality: quality ?? this.quality,
      pageSize: pageSize ?? this.pageSize,
      orientation: orientation ?? this.orientation,
      includeMetadata: includeMetadata ?? this.includeMetadata,
      showMusicSymbols: showMusicSymbols ?? this.showMusicSymbols,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  /// Validates export settings
  bool validate() {
    if (!_isValidFormat(format)) return false;
    if (quality < 1 || quality > 100) return false;
    if (!_isValidPageSize(pageSize)) return false;
    if (!_isValidOrientation(orientation)) return false;
    if (fontSize < 8.0 || fontSize > 24.0) return false;
    return true;
  }

  /// Checks if format is valid
  bool _isValidFormat(String format) {
    final validFormats = ['PNG', 'JPG', 'PDF'];
    return validFormats.contains(format);
  }

  /// Checks if page size is valid
  bool _isValidPageSize(String pageSize) {
    final validSizes = ['A4', 'LETTER', 'A3', 'LEGAL'];
    return validSizes.contains(pageSize);
  }

  /// Checks if orientation is valid
  bool _isValidOrientation(String orientation) {
    final validOrientations = ['PORTRAIT', 'LANDSCAPE'];
    return validOrientations.contains(orientation);
  }

  /// Gets the file extension for the current format
  String get fileExtension {
    switch (format) {
      case 'PNG':
        return '.png';
      case 'JPG':
        return '.jpg';
      case 'PDF':
        return '.pdf';
      default:
        return '.pdf';
    }
  }

  /// Gets the MIME type for the current format
  String get mimeType {
    switch (format) {
      case 'PNG':
        return 'image/png';
      case 'JPG':
        return 'image/jpeg';
      case 'PDF':
        return 'application/pdf';
      default:
        return 'application/pdf';
    }
  }

  /// Gets the page dimensions in points
  Map<String, double> get pageDimensions {
    switch (pageSize) {
      case 'A4':
        return orientation == 'PORTRAIT'
            ? {'width': 595.0, 'height': 842.0}
            : {'width': 842.0, 'height': 595.0};
      case 'LETTER':
        return orientation == 'PORTRAIT'
            ? {'width': 612.0, 'height': 792.0}
            : {'width': 792.0, 'height': 612.0};
      case 'A3':
        return orientation == 'PORTRAIT'
            ? {'width': 842.0, 'height': 1191.0}
            : {'width': 1191.0, 'height': 842.0};
      case 'LEGAL':
        return orientation == 'PORTRAIT'
            ? {'width': 612.0, 'height': 1008.0}
            : {'width': 1008.0, 'height': 612.0};
      default:
        return {'width': 595.0, 'height': 842.0};
    }
  }

  /// Gets the quality as a double (0.0 to 1.0)
  double get qualityRatio {
    return quality / 100.0;
  }

  /// Checks if this is for image export
  bool get isImageExport {
    return format == 'PNG' || format == 'JPG';
  }

  /// Checks if this is for PDF export
  bool get isPDFExport {
    return format == 'PDF';
  }

  /// Gets the recommended font size for chord text
  double get chordFontSize {
    return fontSize * 1.2;
  }

  /// Gets the recommended font size for section headers
  double get sectionFontSize {
    return fontSize * 1.5;
  }

  @override
  String toString() {
    return 'ExportSettings(format: $format, quality: $quality, pageSize: $pageSize, orientation: $orientation, fontSize: $fontSize)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExportSettings &&
        other.format == format &&
        other.quality == quality &&
        other.pageSize == pageSize &&
        other.orientation == orientation &&
        other.includeMetadata == includeMetadata &&
        other.showMusicSymbols == showMusicSymbols &&
        other.fontSize == fontSize;
  }

  @override
  int get hashCode {
    return Object.hash(
      format,
      quality,
      pageSize,
      orientation,
      includeMetadata,
      showMusicSymbols,
      fontSize,
    );
  }
}
