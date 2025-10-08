import '../constants/music_constants.dart';

/// Chord parsing and manipulation utilities
class ChordParser {
  /// Parse a chord string into its components
  static Map<String, dynamic> parseChord(String chord) {
    if (chord.isEmpty) {
      return {
        'root': '',
        'quality': '',
        'extension': '',
        'bass': '',
        'isValid': false,
      };
    }

    // Remove spaces and normalize
    final cleanChord = chord.trim().replaceAll(' ', '');

    // Pattern to match chord components
    // Groups: 1=root, 2=quality, 3=extension, 4=bass note
    final pattern = RegExp(
      r'^([A-G][#♯b♭]?)(maj|min|m|M|dim|aug|sus|add)?(\d*)(?:\/([A-G][#♯b♭]?))?$',
      caseSensitive: false,
    );

    final match = pattern.firstMatch(cleanChord);
    if (match == null) {
      return {
        'root': chord,
        'quality': '',
        'extension': '',
        'bass': '',
        'isValid': false,
      };
    }

    final root = match.group(1) ?? '';
    String quality = match.group(2) ?? '';
    final extension = match.group(3) ?? '';
    final bass = match.group(4) ?? '';

    // Normalize quality names
    quality = _normalizeQuality(quality);

    return {
      'root': root,
      'quality': quality,
      'extension': extension,
      'bass': bass,
      'isValid': true,
    };
  }

  /// Normalize chord quality names
  static String _normalizeQuality(String quality) {
    switch (quality.toLowerCase()) {
      case 'maj':
      case 'm':
      case '':
        return '';
      case 'min':
        return 'm';
      case 'm':
        return 'm';
      case 'dim':
        return 'dim';
      case 'aug':
        return 'aug';
      case 'sus':
        return 'sus';
      case 'add':
        return 'add';
      default:
        return quality;
    }
  }

  /// Transpose a chord by semitones
  static String transposeChord(String chord, int semitones) {
    final components = parseChord(chord);
    if (!components['isValid'] as bool) {
      return chord;
    }

    final root = components['root'] as String;
    final quality = components['quality'] as String;
    final extension = components['extension'] as String;
    final bass = components['bass'] as String;

    final transposedRoot = MusicConstants.transposeNote(root, semitones);
    final transposedBass = bass.isNotEmpty
        ? MusicConstants.transposeNote(bass, semitones)
        : '';

    final result = transposedRoot + quality + extension;
    return transposedBass.isNotEmpty ? '$result/$transposedBass' : result;
  }

  /// Get chord display name with proper formatting
  static String getDisplayName(String chord) {
    final components = parseChord(chord);
    if (!components['isValid'] as bool) {
      return chord;
    }

    final root = components['root'] as String;
    final quality = components['quality'] as String;
    final extension = components['extension'] as String;
    final bass = components['bass'] as String;

    // Format root with proper symbols
    final formattedRoot = root
        .replaceAll('#', MusicConstants.sharp)
        .replaceAll('b', MusicConstants.flat);

    final formattedBass = bass.isNotEmpty
        ? bass
              .replaceAll('#', MusicConstants.sharp)
              .replaceAll('b', MusicConstants.flat)
        : '';

    final result = formattedRoot + quality + extension;
    return formattedBass.isNotEmpty ? '$result/$formattedBass' : result;
  }

  /// Check if two chords are enharmonically equivalent
  static bool areEnharmonic(String chord1, String chord2) {
    final parsed1 = parseChord(chord1);
    final parsed2 = parseChord(chord2);

    if (!parsed1['isValid'] as bool || !parsed2['isValid'] as bool) {
      return chord1 == chord2;
    }

    // Compare components
    return parsed1['quality'] == parsed2['quality'] &&
        parsed1['extension'] == parsed2['extension'] &&
        parsed1['bass'] == parsed2['bass'] &&
        _areNotesEnharmonic(
          parsed1['root'] as String,
          parsed2['root'] as String,
        );
  }

  /// Check if two notes are enharmonic equivalents
  static bool _areNotesEnharmonic(String note1, String note2) {
    final index1 = MusicConstants.getNoteIndex(note1);
    final index2 = MusicConstants.getNoteIndex(note2);
    return index1 == index2;
  }

  /// Get chord complexity score (simpler chords have lower scores)
  static int getComplexity(String chord) {
    final components = parseChord(chord);
    if (!components['isValid'] as bool) {
      return 0;
    }

    int score = 0;

    // Base score for having a chord
    score += 1;

    // Quality complexity
    final quality = components['quality'] as String;
    if (quality.isNotEmpty) {
      score += 1;
      if (quality == 'dim' || quality == 'aug') {
        score += 1;
      }
    }

    // Extension complexity
    final extension = components['extension'] as String;
    if (extension.isNotEmpty) {
      score += 1;
      if (int.tryParse(extension) != null) {
        final extNum = int.parse(extension);
        if (extNum > 7) score += 1;
        if (extNum > 9) score += 1;
      }
    }

    // Bass note complexity
    if ((components['bass'] as String).isNotEmpty) {
      score += 1;
    }

    return score;
  }

  /// Validate chord progression (basic music theory rules)
  static List<String> validateProgression(List<String> chords) {
    final errors = <String>[];

    if (chords.isEmpty) {
      errors.add('Chord progression cannot be empty');
      return errors;
    }

    for (int i = 0; i < chords.length; i++) {
      final chord = chords[i];
      final parsed = parseChord(chord);

      if (!parsed['isValid'] as bool) {
        errors.add('Invalid chord at position ${i + 1}: $chord');
        continue;
      }

      // Check for very complex chords that might be errors
      if (getComplexity(chord) > 5) {
        errors.add('Very complex chord at position ${i + 1}: $chord');
      }
    }

    return errors;
  }

  /// Get suggested chord substitutions
  static List<String> getSubstitutions(String chord) {
    final parsed = parseChord(chord);
    if (!parsed['isValid'] as bool) {
      return [];
    }

    final root = parsed['root'] as String;
    final quality = parsed['quality'] as String;
    final extension = parsed['extension'] as String;

    final substitutions = <String>[];

    // Major chord substitutions
    if (quality.isEmpty) {
      substitutions.add('${root}maj7');
      substitutions.add('${root}6');
      substitutions.add('${root}sus4');
      if (extension.isEmpty) {
        substitutions.add('${root}9');
      }
    }

    // Minor chord substitutions
    if (quality == 'm') {
      substitutions.add('${root}m7');
      substitutions.add('${root}m6');
      substitutions.add('${root}m9');
    }

    // Dominant 7th substitutions
    if (quality.isEmpty && extension == '7') {
      substitutions.add('${root}9');
      substitutions.add('${root}13');
      substitutions.add('${root}7sus4');
    }

    return substitutions;
  }
}
