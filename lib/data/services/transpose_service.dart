import '../models/song.dart';
import '../models/section.dart';
import '../models/structure.dart';
import '../models/measure.dart';
import '../../core/constants/music_constants.dart';
import '../../core/utils/chord_parser.dart';

/// Service for transposing songs and chord progressions
class TransposeService {
  /// Transpose a song by semitones
  static Song transposeSong(Song song, int semitones) {
    // Calculate new key
    final newKey = _transposeKey(song.key, semitones);

    // Transpose all sections and measures
    final transposedSections = song.sections
        .map((section) => transposeSection(section, semitones))
        .toList();

    return song.copyWith(
      key: newKey,
      sections: transposedSections,
      updatedAt: DateTime.now(),
    );
  }

  /// Transpose a section by semitones
  static Section transposeSection(Section section, int semitones) {
    final transposedMeasures = section.measures
        .map((measure) => transposeMeasure(measure, semitones))
        .toList();

    return section.copyWith(measures: transposedMeasures);
  }

  /// Transpose a measure by semitones
  static Measure transposeMeasure(Measure measure, int semitones) {
    final transposedChords = measure.chords
        .map(
          (chord) =>
              chord.isEmpty ? '' : ChordParser.transposeChord(chord, semitones),
        )
        .toList();

    return measure.copyWith(chords: transposedChords);
  }

  /// Transpose a single chord by semitones
  static String transposeChord(String chord, int semitones) {
    if (chord.isEmpty) return '';
    return ChordParser.transposeChord(chord, semitones);
  }

  /// Transpose key signature by semitones
  static String _transposeKey(String key, int semitones) {
    if (key.isEmpty) return key;

    // Handle major keys
    if (MusicConstants.majorKeys.contains(key)) {
      final currentIndex = MusicConstants.majorKeys.indexOf(key);
      final newIndex =
          (currentIndex + semitones) % MusicConstants.majorKeys.length;
      return MusicConstants.majorKeys[newIndex];
    }

    // Handle minor keys
    if (MusicConstants.minorKeys.contains(key)) {
      final currentIndex = MusicConstants.minorKeys.indexOf(key);
      final newIndex =
          (currentIndex + semitones) % MusicConstants.minorKeys.length;
      return MusicConstants.minorKeys[newIndex];
    }

    // Fallback: use note transposition
    return MusicConstants.transposeNote(key, semitones);
  }

  /// Get available transposition options for a song
  static List<Map<String, dynamic>> getTranspositionOptions(Song song) {
    final options = <Map<String, dynamic>>[];
    final currentKey = song.key;

    // Common transpositions: -5 to +6 semitones
    for (int semitones = -5; semitones <= 6; semitones++) {
      final newKey = _transposeKey(currentKey, semitones);
      final description = _getTranspositionDescription(semitones);

      options.add({
        'semitones': semitones,
        'newKey': newKey,
        'description': description,
        'isOriginal': semitones == 0,
      });
    }

    return options;
  }

  /// Get human-readable transposition description
  static String _getTranspositionDescription(int semitones) {
    if (semitones == 0) return 'Original Key';

    final absSemitones = semitones.abs();
    final direction = semitones > 0 ? 'Up' : 'Down';

    if (absSemitones == 1) return '$direction 1 Semitone';
    if (absSemitones == 2) return '$direction 1 Whole Step';
    if (absSemitones == 3) return '$direction Minor 3rd';
    if (absSemitones == 4) return '$direction Major 3rd';
    if (absSemitones == 5) return '$direction Perfect 4th';
    if (absSemitones == 6) return '$direction Tritone';
    if (absSemitones == 7) return '$direction Perfect 5th';
    if (absSemitones == 8) return '$direction Minor 6th';
    if (absSemitones == 9) return '$direction Major 6th';
    if (absSemitones == 10) return '$direction Minor 7th';
    if (absSemitones == 11) return '$direction Major 7th';
    if (absSemitones == 12) return '$direction Octave';

    return '$direction $absSemitones Semitones';
  }

  /// Check if transposition is valid for a song
  static List<String> validateTransposition(Song song, int semitones) {
    final errors = <String>[];

    if (semitones < -12 || semitones > 12) {
      errors.add('Transposition range must be between -12 and +12 semitones');
    }

    // Check if the new key is valid
    final newKey = _transposeKey(song.key, semitones);
    if (!MusicConstants.majorKeys.contains(newKey) &&
        !MusicConstants.minorKeys.contains(newKey)) {
      errors.add('Invalid resulting key: $newKey');
    }

    // Check for extreme transpositions that might cause issues
    if (semitones.abs() > 7) {
      errors.add(
        'Extreme transposition may result in difficult-to-play chords',
      );
    }

    return errors;
  }

  /// Get chord complexity analysis for transposition
  static Map<String, dynamic> getComplexityAnalysis(Song song, int semitones) {
    final originalComplexity = _calculateSongComplexity(song);
    final transposedSong = transposeSong(song, semitones);
    final transposedComplexity = _calculateSongComplexity(transposedSong);

    final complexityChange = transposedComplexity - originalComplexity;
    String complexityDescription;

    if (complexityChange < -2) {
      complexityDescription = 'Much simpler';
    } else if (complexityChange < 0) {
      complexityDescription = 'Simpler';
    } else if (complexityChange == 0) {
      complexityDescription = 'Same complexity';
    } else if (complexityChange <= 2) {
      complexityDescription = 'Slightly more complex';
    } else {
      complexityDescription = 'More complex';
    }

    return {
      'originalComplexity': originalComplexity,
      'transposedComplexity': transposedComplexity,
      'complexityChange': complexityChange,
      'complexityDescription': complexityDescription,
      'recommended': complexityChange <= 0, // Recommend if not more complex
    };
  }

  /// Calculate song complexity score
  static int _calculateSongComplexity(Song song) {
    int complexity = 0;

    for (final section in song.sections) {
      for (final measure in section.measures) {
        for (final chord in measure.chords) {
          if (chord.isNotEmpty) {
            complexity += ChordParser.getComplexity(chord);
          }
        }
      }
    }

    return complexity;
  }

  /// Get common transposition targets for vocal ranges
  static List<Map<String, dynamic>> getVocalRangeOptions(Song song) {
    final options = <Map<String, dynamic>>[];
    final currentKey = song.key;

    // Common vocal transpositions
    final vocalTranspositions = [
      {'semitones': -2, 'description': 'Lower for Baritone/Bass'},
      {'semitones': -1, 'description': 'Slightly Lower'},
      {'semitones': 0, 'description': 'Original (Tenor/Mezzo)'},
      {'semitones': 1, 'description': 'Slightly Higher'},
      {'semitones': 2, 'description': 'Higher for Soprano/Alto'},
      {'semitones': 3, 'description': 'Much Higher'},
      {'semitones': -3, 'description': 'Much Lower'},
    ];

    for (final transposition in vocalTranspositions) {
      final semitones = transposition['semitones'] as int;
      final newKey = _transposeKey(currentKey, semitones);

      options.add({
        'semitones': semitones,
        'newKey': newKey,
        'description': transposition['description'],
        'vocalRange': _getVocalRange(semitones),
      });
    }

    return options;
  }

  /// Get vocal range description
  static String _getVocalRange(int semitones) {
    if (semitones <= -3) return 'Bass';
    if (semitones == -2) return 'Baritone';
    if (semitones == -1) return 'Low Tenor';
    if (semitones == 0) return 'Tenor/Mezzo';
    if (semitones == 1) return 'High Tenor';
    if (semitones == 2) return 'Alto';
    return 'Soprano';
  }

  /// Get capo positions for guitar
  static List<Map<String, dynamic>> getCapoOptions(
    Song song, {
    int maxCapo = 7,
  }) {
    final options = <Map<String, dynamic>>[];
    final currentKey = song.key;

    for (int capo = 0; capo <= maxCapo; capo++) {
      final semitones = -capo; // Capo raises pitch, so we transpose down
      final newKey = _transposeKey(currentKey, semitones);
      final openChordKey = _transposeKey(
        currentKey,
        0,
      ); // Key when playing open chords

      options.add({
        'capo': capo,
        'semitones': semitones,
        'newKey': newKey,
        'openChordKey': openChordKey,
        'description': 'Capo $capo: Play in $openChordKey',
        'difficulty': _getCapoDifficulty(capo),
      });
    }

    return options;
  }

  /// Get capo difficulty rating
  static String _getCapoDifficulty(int capo) {
    if (capo == 0) return 'Easy';
    if (capo <= 2) return 'Very Easy';
    if (capo <= 4) return 'Easy';
    if (capo <= 6) return 'Moderate';
    return 'Difficult';
  }

  /// Batch transpose multiple songs
  static List<Song> transposeSongs(List<Song> songs, int semitones) {
    return songs.map((song) => transposeSong(song, semitones)).toList();
  }

  /// Get transposition history for a song
  static List<Map<String, dynamic>> getTranspositionHistory(Song song) {
    // This would typically load from database
    // For now, return empty list
    return [];
  }

  /// Save transposition preference for a song
  static Future<void> saveTranspositionPreference(
    Song song,
    int semitones,
  ) async {
    // This would typically save to database
    // For now, just print
    print(
      'Saved transposition preference for ${song.title}: $semitones semitones',
    );
  }

  /// Get most common transpositions for a song
  static List<Map<String, dynamic>> getCommonTranspositions(Song song) {
    // This would analyze usage patterns
    // For now, return some common options
    return [
      {
        'semitones': -2,
        'usageCount': 5,
        'description': 'Popular for male vocals',
      },
      {'semitones': 0, 'usageCount': 10, 'description': 'Original key'},
      {
        'semitones': 2,
        'usageCount': 3,
        'description': 'Popular for female vocals',
      },
    ];
  }

  /// Check if song is in a comfortable key for guitar
  static bool isGuitarFriendlyKey(String key) {
    final guitarFriendlyKeys = ['C', 'G', 'D', 'A', 'E', 'Am', 'Em', 'Dm'];
    return guitarFriendlyKeys.contains(key);
  }

  /// Suggest optimal key for instrument
  static Map<String, dynamic> suggestOptimalKey(Song song, String instrument) {
    final currentKey = song.key;
    final suggestions = <Map<String, dynamic>>[];

    // Test different transpositions
    for (int semitones = -6; semitones <= 6; semitones++) {
      final newKey = _transposeKey(currentKey, semitones);
      final score = _calculateKeyScore(newKey, instrument);

      suggestions.add({
        'semitones': semitones,
        'key': newKey,
        'score': score,
        'description': _getKeyDescription(newKey, instrument),
      });
    }

    // Sort by score (descending)
    suggestions.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );

    return {
      'currentKey': currentKey,
      'suggestions': suggestions.take(3).toList(), // Top 3 suggestions
      'instrument': instrument,
    };
  }

  /// Calculate key score for instrument
  static double _calculateKeyScore(String key, String instrument) {
    double score = 0.5; // Base score

    // Guitar-friendly keys
    final guitarKeys = ['C', 'G', 'D', 'A', 'E'];
    if (instrument.toLowerCase().contains('guitar')) {
      if (guitarKeys.contains(key)) score += 0.3;
      if (key.endsWith('m') &&
          guitarKeys.contains(key.substring(0, key.length - 1))) {
        score += 0.2;
      }
    }

    // Piano-friendly keys (fewer sharps/flats)
    final pianoKeys = ['C', 'F', 'G', 'Bb', 'D', 'Eb'];
    if (instrument.toLowerCase().contains('piano')) {
      if (pianoKeys.contains(key)) score += 0.3;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Get key description for instrument
  static String _getKeyDescription(String key, String instrument) {
    if (instrument.toLowerCase().contains('guitar')) {
      final guitarFriendly = ['C', 'G', 'D', 'A', 'E'];
      if (guitarFriendly.contains(key)) return 'Very guitar-friendly';
      if (key.endsWith('m') &&
          guitarFriendly.contains(key.substring(0, key.length - 1))) {
        return 'Guitar-friendly minor';
      }
      return 'Moderate difficulty';
    }

    if (instrument.toLowerCase().contains('piano')) {
      final easyKeys = ['C', 'F', 'G'];
      if (easyKeys.contains(key)) return 'Easy piano key';
      return 'Standard piano key';
    }

    return 'Standard key';
  }
}
