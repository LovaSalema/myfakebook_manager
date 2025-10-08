import '../constants/app_constants.dart';
import '../constants/music_constants.dart';

/// Input validation utilities
class Validators {
  /// Validate song title
  static String? validateSongTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Song title is required';
    }
    if (value.length > AppConstants.maxSongTitleLength) {
      return 'Song title must be less than ${AppConstants.maxSongTitleLength} characters';
    }
    return null;
  }

  /// Validate artist name
  static String? validateArtistName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Artist name is required';
    }
    if (value.length > AppConstants.maxArtistNameLength) {
      return 'Artist name must be less than ${AppConstants.maxArtistNameLength} characters';
    }
    return null;
  }

  /// Validate section name
  static String? validateSectionName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Section name is required';
    }
    if (value.length > AppConstants.maxSectionNameLength) {
      return 'Section name must be less than ${AppConstants.maxSectionNameLength} characters';
    }
    return null;
  }

  /// Validate chord symbol
  static String? validateChord(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Empty chord is allowed
    }
    if (value.length > AppConstants.maxChordLength) {
      return 'Chord symbol must be less than ${AppConstants.maxChordLength} characters';
    }
    if (!MusicConstants.isValidChord(value)) {
      return 'Invalid chord symbol';
    }
    return null;
  }

  /// Validate time signature
  static String? validateTimeSignature(String? value) {
    if (value == null || value.isEmpty) {
      return 'Time signature is required';
    }

    final pattern = RegExp(r'^\d+\/\d+$');
    if (!pattern.hasMatch(value)) {
      return 'Invalid time signature format (e.g., 4/4)';
    }

    final parts = value.split('/');
    final numerator = int.tryParse(parts[0]);
    final denominator = int.tryParse(parts[1]);

    if (numerator == null || denominator == null) {
      return 'Invalid time signature numbers';
    }

    if (numerator <= 0 || denominator <= 0) {
      return 'Time signature numbers must be positive';
    }

    // Check for common denominator values
    if (![2, 4, 8, 16].contains(denominator)) {
      return 'Denominator must be 2, 4, 8, or 16';
    }

    return null;
  }

  /// Validate key signature
  static String? validateKeySignature(String? value) {
    if (value == null || value.isEmpty) {
      return 'Key signature is required';
    }

    final validKeys = [
      ...MusicConstants.majorKeys,
      ...MusicConstants.minorKeys,
    ];
    if (!validKeys.contains(value)) {
      return 'Invalid key signature';
    }

    return null;
  }

  /// Validate tempo
  static String? validateTempo(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tempo is required';
    }

    final tempo = int.tryParse(value);
    if (tempo == null) {
      return 'Tempo must be a number';
    }

    if (tempo < 20 || tempo > 300) {
      return 'Tempo must be between 20 and 300 BPM';
    }

    return null;
  }

  /// Validate measures per line
  static String? validateMeasuresPerLine(String? value) {
    if (value == null || value.isEmpty) {
      return 'Measures per line is required';
    }

    final measures = int.tryParse(value);
    if (measures == null) {
      return 'Measures per line must be a number';
    }

    if (measures < 1 || measures > 8) {
      return 'Measures per line must be between 1 and 8';
    }

    return null;
  }

  /// Validate file name
  static String? validateFileName(String? value) {
    if (value == null || value.isEmpty) {
      return 'File name is required';
    }

    if (!AppConstants.isValidFileName(value)) {
      return 'File name contains invalid characters';
    }

    if (value.length > 100) {
      return 'File name must be less than 100 characters';
    }

    return null;
  }

  /// Validate email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    if (!AppConstants.emailRegex.hasMatch(value)) {
      return 'Invalid email address';
    }

    return null;
  }

  /// Validate URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }

    if (!AppConstants.urlRegex.hasMatch(value)) {
      return 'Invalid URL';
    }

    return null;
  }

  /// Validate positive integer
  static String? validatePositiveInteger(
    String? value, {
    String fieldName = 'Value',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return '$fieldName must be a number';
    }

    if (number <= 0) {
      return '$fieldName must be positive';
    }

    return null;
  }

  /// Validate positive double
  static String? validatePositiveDouble(
    String? value, {
    String fieldName = 'Value',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName must be a number';
    }

    if (number <= 0) {
      return '$fieldName must be positive';
    }

    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(
    String? value,
    int minLength, {
    String fieldName = 'Field',
  }) {
    if (value == null || value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(
    String? value,
    int maxLength, {
    String fieldName = 'Field',
  }) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    return null;
  }

  /// Validate chord progression
  static List<String> validateChordProgression(List<String> chords) {
    final errors = <String>[];

    if (chords.isEmpty) {
      errors.add('Chord progression cannot be empty');
      return errors;
    }

    for (int i = 0; i < chords.length; i++) {
      final chord = chords[i];
      final chordError = validateChord(chord);
      if (chordError != null) {
        errors.add('Position ${i + 1}: $chordError');
      }
    }

    return errors;
  }

  /// Validate song structure
  static String? validateSongStructure(Map<String, dynamic> structure) {
    if (structure.isEmpty) {
      return 'Song structure cannot be empty';
    }

    final sections = structure.keys.toList();
    if (sections.isEmpty) {
      return 'Song must have at least one section';
    }

    for (final section in sections) {
      final sectionError = validateSectionName(section);
      if (sectionError != null) {
        return 'Invalid section name: $section';
      }
    }

    return null;
  }

  /// Validate export settings
  static String? validateExportSettings(Map<String, dynamic> settings) {
    final format = settings['format'] as String?;
    if (format == null || !AppConstants.exportFormats.contains(format)) {
      return 'Invalid export format';
    }

    final fileName = settings['fileName'] as String?;
    final fileNameError = validateFileName(fileName);
    if (fileNameError != null) {
      return fileNameError;
    }

    final quality = settings['quality'] as int?;
    if (quality != null && (quality < 1 || quality > 100)) {
      return 'Quality must be between 1 and 100';
    }

    return null;
  }
}
