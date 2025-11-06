import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/song.dart';
import '../models/section.dart';
import '../models/measure.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/chord_parser.dart';

/// Service for exporting chord grids to image formats
class ImageExportService {
  /// Export a song to PNG image
  static Future<Uint8List> exportSongToPng(Song song) async {
    return _createChordGridImage(song);
  }

  /// Create chord grid image
  static Uint8List _createChordGridImage(Song song) {
    // Create image with A4 proportions at 300 DPI
    final image = img.Image(
      width: AppConstants.imageWidth,
      height: AppConstants.imageHeight,
    );

    // Fill with white background
    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    // Draw song header
    _drawSongHeader(image, song);

    // Draw chord grid
    _drawChordGrid(image, song);

    // Draw footer
    _drawFooter(image, song);

    // Convert to PNG
    return Uint8List.fromList(img.encodePng(image));
  }

  /// Draw song header
  static void _drawSongHeader(img.Image image, Song song) {
    // Draw title
    _drawText(
      image,
      song.title,
      x: 100,
      y: 100,
      fontSize: 48,
      color: img.ColorRgb8(0, 0, 0),
    );

    // Draw artist
    _drawText(
      image,
      'by ${song.artist}',
      x: 100,
      y: 170,
      fontSize: 28,
      color: img.ColorRgb8(128, 128, 128),
    );

    // Draw song info box
    _drawInfoBox(image, song, 100, 220);
  }

  /// Draw info box with song details
  static void _drawInfoBox(img.Image image, Song song, int x, int y) {
    const boxWidth = 600;
    const boxHeight = 120;

    // Draw box border
    _drawRectangle(
      image,
      x: x,
      y: y,
      width: boxWidth,
      height: boxHeight,
      color: img.ColorRgb8(200, 200, 200),
      fill: false,
    );

    // Draw box title
    _drawText(
      image,
      'Song Information',
      x: x + 20,
      y: y + 25,
      fontSize: 20,
      color: img.ColorRgb8(0, 0, 0),
      bold: true,
    );

    // Draw song details
    final details = [
      'Key: ${song.key}',
      'Time Signature: ${song.timeSignature}',
      'Tempo: ${song.tempo} BPM',
      'Style: ${song.style ?? "Not specified"}',
    ];

    for (int i = 0; i < details.length; i++) {
      _drawText(
        image,
        details[i],
        x: x + 20,
        y: y + 55 + (i * 25),
        fontSize: 16,
        color: img.ColorRgb8(0, 0, 0),
      );
    }
  }

  /// Draw chord grid
  static void _drawChordGrid(img.Image image, Song song) {
    const startX = 100;
    const startY = 400;
    const measureWidth = 120;
    const measureHeight = 80;
    const measuresPerRow = 4;

    int currentX = startX;
    int currentY = startY;
    int measureNumber = 1;

    // Calculate total grid height
    final totalHeight = _calculateGridHeight(
      song,
      measuresPerRow,
      measureHeight,
    );

    // Draw grid container
    _drawRectangle(
      image,
      x: startX - 10,
      y: startY - 10,
      width: (measureWidth * measuresPerRow) + 20,
      height: totalHeight + 20,
      color: img.ColorRgb8(200, 200, 200),
      fill: false,
    );

    // Draw sections and measures
    for (final section in song.sections) {
      for (int repeat = 0; repeat < section.repeatCount; repeat++) {
        // Draw section header
        if (repeat == 0) {
          _drawSectionHeader(
            image,
            section.displayName,
            x: currentX,
            y: currentY,
            width: measureWidth * measuresPerRow,
          );
          currentY += 40;
        }

        // Draw measures for this section
        for (int i = 0; i < section.measures.length; i++) {
          final measure = section.measures[i];

          // Check if we need to move to next row
          if ((i % measuresPerRow) == 0 && i > 0) {
            currentX = startX;
            currentY += measureHeight + 10;
          }

          // Get first chord for display (simplified)
          final chord = measure.chords.isNotEmpty ? measure.chords[0] : '';

          _drawMeasure(
            image,
            measureNumber,
            chord,
            x: currentX,
            y: currentY,
            width: measureWidth,
            height: measureHeight,
          );

          currentX += measureWidth + 10;
          measureNumber++;
        }

        // Reset for next section
        currentX = startX;
        currentY += measureHeight + 20;
      }
    }
  }

  /// Calculate grid height based on song sections
  static int _calculateGridHeight(
    Song song,
    int measuresPerRow,
    int measureHeight,
  ) {
    int totalHeight = 0;
    int totalMeasures = 0;

    for (final section in song.sections) {
      totalMeasures += section.measures.length * section.repeatCount;
      totalHeight += 40; // Section header height
    }

    final rows = (totalMeasures / measuresPerRow).ceil();
    totalHeight += rows * measureHeight + (rows - 1) * 10;

    return totalHeight;
  }

  /// Draw section header
  static void _drawSectionHeader(
    img.Image image,
    String sectionName, {
    required int x,
    required int y,
    required int width,
  }) {
    // Draw background
    _drawRectangle(
      image,
      x: x,
      y: y,
      width: width,
      height: 30,
      color: img.ColorRgb8(240, 240, 240),
      fill: true,
    );

    // Draw border
    _drawRectangle(
      image,
      x: x,
      y: y,
      width: width,
      height: 30,
      color: img.ColorRgb8(180, 180, 180),
      fill: false,
    );

    // Draw text
    _drawText(
      image,
      sectionName,
      x: x + 10,
      y: y + 8,
      fontSize: 16,
      color: img.ColorRgb8(0, 0, 0),
      bold: true,
    );
  }

  /// Draw a single measure
  static void _drawMeasure(
    img.Image image,
    int number,
    String chord, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    // Draw measure background
    _drawRectangle(
      image,
      x: x,
      y: y,
      width: width,
      height: height,
      color: chord.isEmpty
          ? img.ColorRgb8(255, 255, 255)
          : img.ColorRgb8(250, 250, 250),
      fill: true,
    );

    // Draw measure border
    _drawRectangle(
      image,
      x: x,
      y: y,
      width: width,
      height: height,
      color: img.ColorRgb8(150, 150, 150),
      fill: false,
    );

    // Draw measure number
    _drawText(
      image,
      number.toString(),
      x: x + 5,
      y: y + 5,
      fontSize: 12,
      color: img.ColorRgb8(100, 100, 100),
    );

    // Draw chord
    if (chord.isNotEmpty) {
      _drawText(
        image,
        ChordParser.getDisplayName(chord),
        x: x + (width ~/ 2),
        y: y + (height ~/ 2),
        fontSize: 16,
        color: img.ColorRgb8(0, 0, 0),
        bold: true,
        center: true,
      );
    }
  }

  /// Draw footer
  static void _drawFooter(img.Image image, Song song) {
    final footerY = AppConstants.imageHeight - 100;

    // Draw footer box
    _drawRectangle(
      image,
      x: 100,
      y: footerY,
      width: AppConstants.imageWidth - 200,
      height: 60,
      color: img.ColorRgb8(240, 240, 240),
      fill: true,
    );

    _drawRectangle(
      image,
      x: 100,
      y: footerY,
      width: AppConstants.imageWidth - 200,
      height: 60,
      color: img.ColorRgb8(180, 180, 180),
      fill: false,
    );

    // Draw footer text
    _drawText(
      image,
      'Key: ${song.key} | Time: ${song.timeSignature} | Tempo: ${song.tempo} BPM',
      x: 120,
      y: footerY + 20,
      fontSize: 14,
      color: img.ColorRgb8(0, 0, 0),
    );

    _drawText(
      image,
      '${AppConstants.appName} - ${DateTime.now().year}',
      x: AppConstants.imageWidth - 300,
      y: footerY + 20,
      fontSize: 14,
      color: img.ColorRgb8(100, 100, 100),
    );
  }

  /// Draw text on image (simplified implementation)
  static void _drawText(
    img.Image image,
    String text, {
    required int x,
    required int y,
    required int fontSize,
    required img.Color color,
    bool bold = false,
    bool center = false,
  }) {
    if (center) {
      // Simple centering calculation
      final textWidth = text.length * (fontSize ~/ 2);
      x = x - (textWidth ~/ 2);
    }

    // Simple text rendering using rectangles
    int currentX = x;
    final lineHeight = fontSize + 2;

    for (final char in text.codeUnits) {
      if (char == 32) {
        // Space
        currentX += fontSize ~/ 2;
        continue;
      }

      // Draw a simple character representation
      _drawCharacter(image, char, currentX, y, fontSize, color, bold);
      currentX += fontSize;

      if (currentX > image.width - fontSize) {
        break;
      }
    }
  }

  /// Draw a single character (placeholder implementation)
  static void _drawCharacter(
    img.Image image,
    int charCode,
    int x,
    int y,
    int fontSize,
    img.Color color,
    bool bold,
  ) {
    // This is a very simplified character drawing
    // In a real app, you'd use a proper font rendering library

    final thickness = bold ? 3 : 2;

    for (int i = 0; i < fontSize; i++) {
      for (int j = 0; j < fontSize; j++) {
        if (i < thickness ||
            j < thickness ||
            i >= fontSize - thickness ||
            j >= fontSize - thickness) {
          final pixelX = x + i;
          final pixelY = y + j;
          if (pixelX < image.width && pixelY < image.height) {
            image.setPixel(pixelX, pixelY, color);
          }
        }
      }
    }
  }

  /// Draw a rectangle
  static void _drawRectangle(
    img.Image image, {
    required int x,
    required int y,
    required int width,
    required int height,
    required img.Color color,
    required bool fill,
  }) {
    for (int i = 0; i < width; i++) {
      for (int j = 0; j < height; j++) {
        final pixelX = x + i;
        final pixelY = y + j;

        if (pixelX < image.width && pixelY < image.height) {
          if (fill || i == 0 || j == 0 || i == width - 1 || j == height - 1) {
            image.setPixel(pixelX, pixelY, color);
          }
        }
      }
    }
  }

  /// Export song as image file by capturing the widget screenshot
  static Future<File?> exportSongAsImage(
    Song song, {
    int quality = 90,
    bool includeMetadata = true,
    bool showMusicSymbols = true,
  }) async {
    try {
      // This method is now deprecated since we'll capture the widget directly
      // Keeping it for compatibility but it will return null
      print(
        'Warning: Using deprecated export method. Use captureWidgetScreenshot instead.',
      );
      return null;
    } catch (e) {
      print('Error exporting song as image: $e');
      return null;
    }
  }

  /// Capture a widget screenshot and save it as an image file
  static Future<File?> captureWidgetScreenshot(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(imageBytes);
      print('Screenshot saved to: $filePath');
      return file;
    } catch (e) {
      print('Error saving screenshot: $e');
      return null;
    }
  }

  /// Share image file using share_plus
  static Future<void> shareImageFile(File imageFile) async {
    try {
      await Share.shareXFiles([
        XFile(imageFile.path),
      ], text: 'Chord Sheet Export');
    } catch (e) {
      print('Error sharing image: $e');
    }
  }

  /// Get image file size
  static String getImageFileSize(Uint8List imageBytes) {
    return AppConstants.formatFileSize(imageBytes.length);
  }

  /// Validate export settings
  static List<String> validateExportSettings(Map<String, dynamic> settings) {
    final errors = <String>[];

    final fileName = settings['fileName'] as String?;
    if (fileName == null || fileName.isEmpty) {
      errors.add('File name is required');
    } else if (!AppConstants.isValidFileName(fileName)) {
      errors.add('Invalid file name');
    }

    final quality = settings['quality'] as int?;
    if (quality != null && (quality < 1 || quality > 100)) {
      errors.add('Quality must be between 1 and 100');
    }

    return errors;
  }
}
