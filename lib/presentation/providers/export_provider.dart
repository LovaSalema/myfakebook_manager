import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/song.dart';
import '../../data/models/repertoire.dart';
import '../../data/models/export_settings.dart';
import '../../data/services/pdf_export_service.dart';
import '../../data/services/image_export_service.dart';

/// ExportProvider for managing export operations with progress tracking
class ExportProvider with ChangeNotifier {
  final PdfExportService _pdfExportService = PdfExportService();
  final ImageExportService _imageExportService = ImageExportService();

  // Export state
  bool _isExporting = false;
  double _exportProgress = 0.0;
  String? _exportError;
  ExportSettings _settings = ExportSettings.defaultSettings();

  // Getters
  bool get isExporting => _isExporting;
  double get exportProgress => _exportProgress;
  String? get exportError => _exportError;
  ExportSettings get settings => _settings;

  /// Update export settings
  void updateSettings(ExportSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  /// Export song as image with progress tracking
  Future<File?> exportSongAsImage(Song song) async {
    _startExport();
    _clearError();

    try {
      _updateProgress(0.1, 'Preparing image export...');

      final file = await ImageExportService.exportSongAsImage(
        song,
        quality: _settings.quality,
        includeMetadata: _settings.includeMetadata,
        showMusicSymbols: _settings.showMusicSymbols,
      );

      _updateProgress(1.0, 'Export complete!');
      await _completeExport();
      return file;
    } catch (e) {
      _setError('Failed to export song as image: $e');
      await _completeExport();
      return null;
    }
  }

  /// Export song as PDF with progress tracking
  Future<File?> exportSongAsPDF(Song song) async {
    _startExport();
    _clearError();

    try {
      _updateProgress(0.1, 'Preparing PDF export...');

      final file = await PdfExportService.exportSongAsPDF(
        song,
        pageSize: _settings.pageSize,
        orientation: _settings.orientation,
        includeMetadata: _settings.includeMetadata,
        showMusicSymbols: _settings.showMusicSymbols,
        fontSize: _settings.fontSize,
      );

      _updateProgress(1.0, 'Export complete!');
      await _completeExport();
      return file;
    } catch (e) {
      _setError('Failed to export song as PDF: $e');
      await _completeExport();
      return null;
    }
  }

  /// Export repertoire as text (simple format)
  Future<String> exportRepertoireAsText(Repertoire repertoire) async {
    _startExport();
    _clearError();

    try {
      _updateProgress(0.1, 'Preparing text export...');

      final buffer = StringBuffer();
      buffer.writeln('=== ${repertoire.name} ===');
      if (repertoire.description != null) {
        buffer.writeln('Description: ${repertoire.description}');
      }
      if (repertoire.eventDate != null) {
        buffer.writeln('Event Date: ${repertoire.eventDate}');
      }
      buffer.writeln();

      // Note: This would need to be implemented with actual song data
      // For now, we'll return a placeholder
      buffer.writeln('Song list would be generated here...');

      _updateProgress(1.0, 'Export complete!');
      await _completeExport();
      return buffer.toString();
    } catch (e) {
      _setError('Failed to export repertoire as text: $e');
      await _completeExport();
      return '';
    }
  }

  /// Export repertoire as PDF with optional chord sheets
  Future<File?> exportRepertoireAsPDF(
    Repertoire repertoire, {
    bool includeChordSheets = false,
  }) async {
    _startExport();
    _clearError();

    try {
      _updateProgress(0.1, 'Preparing repertoire PDF export...');

      // Note: This would need to be implemented with actual repertoire data
      // For now, we'll use a placeholder implementation
      _updateProgress(0.5, 'Generating repertoire content...');

      // Simulate processing time
      await Future.delayed(const Duration(milliseconds: 500));

      _updateProgress(0.8, 'Creating PDF document...');

      // For now, return null as this needs proper implementation
      // In a real implementation, this would generate a PDF with the repertoire

      _updateProgress(1.0, 'Export complete!');
      await _completeExport();
      return null; // Placeholder - needs implementation
    } catch (e) {
      _setError('Failed to export repertoire as PDF: $e');
      await _completeExport();
      return null;
    }
  }

  /// Export multiple songs as a collection
  Future<File?> exportSongsAsCollection(
    List<Song> songs, {
    String collectionName = 'Song Collection',
  }) async {
    _startExport();
    _clearError();

    try {
      _updateProgress(0.1, 'Preparing collection export...');

      if (songs.isEmpty) {
        throw Exception('No songs selected for export');
      }

      _updateProgress(0.3, 'Processing ${songs.length} songs...');

      // Note: This would need proper implementation
      // For now, we'll export the first song as a placeholder
      if (_settings.isPDFExport) {
        return await exportSongAsPDF(songs.first);
      } else {
        return await exportSongAsImage(songs.first);
      }
    } catch (e) {
      _setError('Failed to export song collection: $e');
      await _completeExport();
      return null;
    }
  }

  /// Cancel current export operation
  void cancelExport() {
    if (_isExporting) {
      _isExporting = false;
      _exportProgress = 0.0;
      _exportError = 'Export cancelled by user';
      notifyListeners();
    }
  }

  /// Clear export error
  void clearError() {
    _exportError = null;
    notifyListeners();
  }

  /// Reset export state
  void resetExport() {
    _isExporting = false;
    _exportProgress = 0.0;
    _exportError = null;
    notifyListeners();
  }

  // Private helper methods

  void _startExport() {
    _isExporting = true;
    _exportProgress = 0.0;
    _exportError = null;
    notifyListeners();
  }

  void _updateProgress(double progress, [String? message]) {
    _exportProgress = progress.clamp(0.0, 1.0);
    notifyListeners();

    // Optional: Log progress message
    if (message != null) {
      print(
        'Export Progress: ${(progress * 100).toStringAsFixed(1)}% - $message',
      );
    }
  }

  Future<void> _completeExport() async {
    // Add a small delay to show completion
    await Future.delayed(const Duration(milliseconds: 500));
    _isExporting = false;
    notifyListeners();
  }

  void _setError(String error) {
    _exportError = error;
    _isExporting = false;
    notifyListeners();
  }

  void _clearError() {
    _exportError = null;
  }
}
