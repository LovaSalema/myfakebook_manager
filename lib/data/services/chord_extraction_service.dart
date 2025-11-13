import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../data/models/song.dart';
import '../../data/models/section.dart';
import '../../data/models/measure.dart';

class ChordExtractionService {
  static const String baseUrl =
      'https://chordmini-backend-191567167632.us-central1.run.app';

  /// Extract chords and beats from audio file
  Future<Map<String, dynamic>> extractChordsAndBeats(File audioFile) async {
    try {
      print('Starting chord and beat extraction...');

      // Extract chords
      final chordRequest = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/recognize-chords'),
      );

      chordRequest.files.add(
        await http.MultipartFile.fromPath('file', audioFile.path),
      );
      chordRequest.fields['model'] = 'chord-cnn-lstm';

      print('Sending chord recognition request...');
      final chordResponse = await chordRequest.send();
      final chordResponseBody = await chordResponse.stream.bytesToString();

      if (chordResponse.statusCode != 200) {
        throw Exception(
          'Chord API failed: ${chordResponse.statusCode} - $chordResponseBody',
        );
      }

      final chordData = jsonDecode(chordResponseBody);
      print('Chord data received: ${chordData.keys}');

      if (chordData['success'] != true) {
        throw Exception(
          'Chord extraction failed: ${chordData['error'] ?? 'Unknown error'}',
        );
      }

      // Extract beats
      final beatRequest = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/detect-beats'),
      );

      beatRequest.files.add(
        await http.MultipartFile.fromPath('file', audioFile.path),
      );
      beatRequest.fields['detector'] = 'beat-transformer';

      print('Sending beat detection request...');
      final beatResponse = await beatRequest.send();
      final beatResponseBody = await beatResponse.stream.bytesToString();

      if (beatResponse.statusCode != 200) {
        throw Exception(
          'Beat API failed: ${beatResponse.statusCode} - $beatResponseBody',
        );
      }

      final beatData = jsonDecode(beatResponseBody);
      print('Beat data received: ${beatData.keys}');

      if (beatData['success'] != true) {
        throw Exception(
          'Beat detection failed: ${beatData['error'] ?? 'Unknown error'}',
        );
      }

      return {'chords': chordData, 'beats': beatData};
    } catch (e) {
      print('Error in extractChordsAndBeats: $e');
      if (e is http.ClientException) {
        throw Exception('Network error: Please check your internet connection');
      } else if (e is FormatException) {
        throw Exception('Invalid response format from API');
      } else {
        rethrow;
      }
    }
  }

  /// Convert API data to Song object
  Song createSongFromApiData(Map<String, dynamic> apiData, String fileName) {
    try {
      print('Creating song from API data...');
      print('Debug: Received API data in createSongFromApiData: $apiData');
      final chordData = apiData['chords'];
      final beatData = apiData['beats'];

      if (chordData == null || beatData == null) {
        throw Exception('Données API manquantes');
      }

      final chords = chordData['chords'] as List?;
      if (chords == null || chords.isEmpty) {
        throw Exception('Données de chords manquantes');
      }
      print('Total chords from API: ${chords.length}');

      final downbeats = beatData['downbeats'] as List?;
      final beats = beatData['beats'] as List?;

      if (downbeats == null || downbeats.isEmpty) {
        throw Exception('Données de downbeats manquantes');
      }
      print('Total downbeats: ${downbeats.length}');

      final bpm = (beatData['bpm'] as num?)?.toDouble();
      if (bpm == null) {
        throw Exception('BPM manquant');
      }
      print('BPM: $bpm');

      // Parse and validate time signature
      final timeSignature = _parseTimeSignature(
        beatData['time_signature'],
        beats,
        downbeats,
      );
      print('Time signature: $timeSignature');

      // Detect key from chords
      final detectedKey = _detectKey(chords);
      print('Detected key: $detectedKey');

      // Extract title from filename
      final title = _extractTitleFromFileName(fileName);
      print('Song title: $title');

      // Create measures from downbeats
      final measures = _createMeasuresFromDownbeats(
        chords,
        downbeats,
        timeSignature,
      );
      print('Created ${measures.length} measures');

      // Validate measures
      for (int i = 0; i < measures.length; i++) {
        final measure = measures[i];
        print(
          'Measure $i: chords=${measure.chords}, order=${measure.measureOrder}',
        );
        if (!measure.validate()) {
          print('WARNING: Measure $i validation failed!');
        }
      }

      // Create section with populated measures
      final sectionWithChords = Section(
        songId: 0, // Will be set when saved
        sectionType: 'VERSE',
        sectionLabel: 'A',
        sectionOrder: 0,
        measures: measures,
      );

      print('Section validation: ${sectionWithChords.validate()}');

      // Create song
      final song = Song.create(
        title: title,
        artist: 'Unknown',
        key: detectedKey,
        timeSignature: timeSignature,
        tempo: bpm.round(),
      );

      final finalSong = song.copyWith(sections: [sectionWithChords]);
      print('Final song validation: ${finalSong.validate()}');

      return finalSong;
    } catch (e) {
      print('Error in createSongFromApiData: $e');
      throw Exception('Erreur lors de la création de la chanson: $e');
    }
  }

  /// Parse and validate time signature from API
  /// Use the time signature directly from API as the data is correct
  String _parseTimeSignature(dynamic timeSig, List? beats, List? downbeats) {
    // Use the time signature directly from API
    if (timeSig == null) {
      print('No time signature provided, defaulting to 4/4');
      return '4/4';
    }

    String timeSignature;

    // Handle different formats from API
    if (timeSig is String) {
      timeSignature = timeSig;
    } else if (timeSig is int) {
      // If API returns just the numerator (e.g., 4), assume /4 denominator
      timeSignature = '$timeSig/4';
    } else if (timeSig is List && timeSig.length >= 2) {
      // If API returns [numerator, denominator]
      timeSignature = '${timeSig[0]}/${timeSig[1]}';
    } else {
      print('Unexpected time signature format: $timeSig, defaulting to 4/4');
      return '4/4';
    }

    // Validate format
    if (!RegExp(r'^\d+/\d+$').hasMatch(timeSignature)) {
      print('Invalid time signature format: $timeSignature, defaulting to 4/4');
      return '4/4';
    }

    // Parse and validate values
    final parts = timeSignature.split('/');
    final numerator = int.tryParse(parts[0]);

    if (numerator == null || parts.length != 2) {
      print(
        'Could not parse time signature: $timeSignature, defaulting to 4/4',
      );
      return '4/4';
    }

    // Validate numerator (typically 1-16)
    if (numerator < 1 || numerator > 16) {
      print('Invalid numerator: $numerator, defaulting to 4/4');
      return '4/4';
    }

    // Trust the API's time signature as it's correct
    print('Using time signature from API: $timeSignature');
    return timeSignature;
  }

  /// Map beat count to one of the supported time signatures
  /// CORRECTED: Better handling of compound meters and edge cases

  /// Get beats per measure from time signature
  /// CORRECTED: Handle compound meters properly
  int _getBeatsPerMeasure(String timeSignature) {
    final parts = timeSignature.split('/');
    final numerator = int.parse(parts[0]);
    final denominator = int.parse(parts[1]);

    // For compound meters (x/8 where x is divisible by 3),
    // the numerator represents eighth notes, not beats
    // But for our chord display purposes, we use the numerator
    // Example: 6/8 has 6 eighth notes (or 2 dotted quarter beats)
    // but we display 6 chord positions
    return numerator;
  }

  /// Convert chord from API format to display format
  /// API format: "E:maj", "C#:min", "F#:min7", "B:7"
  /// Display format: "E", "C#m", "F#m7", "B7"
  String _convertChordFormat(String apiChord) {
    if (apiChord == 'N') return '';

    if (!apiChord.contains(':')) {
      return apiChord; // Already in display format or invalid
    }

    final parts = apiChord.split(':');
    if (parts.length != 2) return apiChord;

    final root = parts[0];
    final quality = parts[1];

    // Handle minor chords
    if (quality.startsWith('min')) {
      final extension = quality.substring(3); // Get everything after "min"
      return '$root${extension.isEmpty ? 'm' : 'm$extension'}';
    }

    // Handle major chords
    if (quality.startsWith('maj')) {
      final extension = quality.substring(3); // Get everything after "maj"
      return '$root$extension';
    }

    // Handle diminished
    if (quality.startsWith('dim')) {
      final extension = quality.substring(3);
      return '$root${extension.isEmpty ? '°' : '°$extension'}';
    }

    // Handle augmented
    if (quality.startsWith('aug')) {
      final extension = quality.substring(3);
      return '$root${extension.isEmpty ? '+' : '+$extension'}';
    }

    // Handle seventh chords and other extensions (B:7, B:9, etc.)
    if (quality.contains(RegExp(r'^\d'))) {
      return '$root$quality';
    }

    // Default: just append quality
    return '$root$quality';
  }

  /// Create measures from downbeats and chords
  /// CORRECTED: Better beat position calculation and chord assignment
  List<Measure> _createMeasuresFromDownbeats(
    List chords,
    List downbeats,
    String timeSignature,
  ) {
    final beatsPerMeasure = _getBeatsPerMeasure(timeSignature);
    final measures = <Measure>[];

    // Convert downbeats to doubles and sort
    final downbeatTimes = downbeats.map((db) => (db as num).toDouble()).toList()
      ..sort();

    print('Creating measures from ${downbeatTimes.length} downbeats...');
    print('Beats per measure: $beatsPerMeasure');

    // Process each measure
    for (int i = 0; i < downbeatTimes.length - 1; i++) {
      final measureStart = downbeatTimes[i];
      final measureEnd = downbeatTimes[i + 1];
      final measureDuration = measureEnd - measureStart;

      print(
        'Measure $i: $measureStart - $measureEnd (duration: $measureDuration)',
      );

      // Initialize measure with empty chords
      final measureChords = List<String>.filled(beatsPerMeasure, '');
      final beatDuration = measureDuration / beatsPerMeasure;

      // Find all chords that overlap with this measure
      for (final chordData in chords) {
        final chordName = chordData['chord'] as String;
        final chordStart = (chordData['start'] as num).toDouble();
        final chordEnd = (chordData['end'] as num).toDouble();

        // Skip 'N' (no chord)
        if (chordName == 'N') continue;

        // Check if chord overlaps with this measure
        if (chordEnd <= measureStart || chordStart >= measureEnd) {
          continue; // No overlap
        }

        // Convert API format to display format
        final displayChord = _convertChordFormat(chordName);

        // Calculate which beats this chord should occupy
        // Use center point of each beat for more accurate assignment
        for (int beat = 0; beat < beatsPerMeasure; beat++) {
          final beatCenter = measureStart + (beat + 0.5) * beatDuration;

          // Assign chord if beat center falls within chord duration
          if (beatCenter >= chordStart && beatCenter < chordEnd) {
            measureChords[beat] = displayChord;
          }
        }
      }

      // Handle empty beats by extending previous chord or using last non-empty
      String lastNonEmptyChord = '';
      for (int beat = 0; beat < beatsPerMeasure; beat++) {
        if (measureChords[beat].isNotEmpty) {
          lastNonEmptyChord = measureChords[beat];
        } else if (lastNonEmptyChord.isNotEmpty) {
          // Extend previous beat's chord
          measureChords[beat] = lastNonEmptyChord;
        } else if (measures.isNotEmpty) {
          // Use last chord from previous measure
          final lastMeasure = measures.last;
          final lastChord = lastMeasure.chords.lastWhere(
            (c) => c.isNotEmpty,
            orElse: () => '',
          );
          if (lastChord.isNotEmpty) {
            measureChords[beat] = lastChord;
            lastNonEmptyChord = lastChord;
          }
        }
      }

      // Create measure
      final measure = Measure.create(
        sectionId: 0,
        measureOrder: i,
        timeSignature: timeSignature,
      ).copyWith(chords: measureChords);

      measures.add(measure);
      print('  Created measure with chords: $measureChords');
    }

    // Ensure we have at least 4 measures if needed
    if (measures.length < 4) {
      print('Padding to minimum 4 measures (currently ${measures.length})');

      final lastChord = measures.isNotEmpty && measures.last.chords.isNotEmpty
          ? measures.last.chords.firstWhere(
              (c) => c.isNotEmpty,
              orElse: () => '',
            )
          : '';

      while (measures.length < 4) {
        measures.add(
          Measure.create(
            sectionId: 0,
            measureOrder: measures.length,
            timeSignature: timeSignature,
          ).copyWith(chords: List<String>.filled(beatsPerMeasure, lastChord)),
        );
      }
    }

    print('Final measure count: ${measures.length}');
    return measures;
  }

  /// Detect key from chord progression
  String _detectKey(List chords) {
    if (chords.isEmpty) return 'C';

    // Define major and minor scales (circle of fifths order)
    final majorKeys = [
      'C',
      'G',
      'D',
      'A',
      'E',
      'B',
      'F#',
      'Db',
      'Ab',
      'Eb',
      'Bb',
      'F',
    ];
    final minorKeys = [
      'Am',
      'Em',
      'Bm',
      'F#m',
      'C#m',
      'G#m',
      'D#m',
      'Bbm',
      'Fm',
      'Cm',
      'Gm',
      'Dm',
    ];

    // Diatonic chords for each key (I, ii, iii, IV, V, vi, vii°)
    final majorDiatonicChords = {
      'C': ['C:maj', 'D:min', 'E:min', 'F:maj', 'G:maj', 'A:min', 'B:dim'],
      'G': ['G:maj', 'A:min', 'B:min', 'C:maj', 'D:maj', 'E:min', 'F#:dim'],
      'D': ['D:maj', 'E:min', 'F#:min', 'G:maj', 'A:maj', 'B:min', 'C#:dim'],
      'A': ['A:maj', 'B:min', 'C#:min', 'D:maj', 'E:maj', 'F#:min', 'G#:dim'],
      'E': ['E:maj', 'F#:min', 'G#:min', 'A:maj', 'B:maj', 'C#:min', 'D#:dim'],
      'B': ['B:maj', 'C#:min', 'D#:min', 'E:maj', 'F#:maj', 'G#:min', 'A#:dim'],
      'F#': [
        'F#:maj',
        'G#:min',
        'A#:min',
        'B:maj',
        'C#:maj',
        'D#:min',
        'E#:dim',
      ],
      'Db': [
        'Db:maj',
        'Eb:min',
        'F:min',
        'Gb:maj',
        'Ab:maj',
        'Bb:min',
        'C:dim',
      ],
      'Ab': ['Ab:maj', 'Bb:min', 'C:min', 'Db:maj', 'Eb:maj', 'F:min', 'G:dim'],
      'Eb': ['Eb:maj', 'F:min', 'G:min', 'Ab:maj', 'Bb:maj', 'C:min', 'D:dim'],
      'Bb': ['Bb:maj', 'C:min', 'D:min', 'Eb:maj', 'F:maj', 'G:min', 'A:dim'],
      'F': ['F:maj', 'G:min', 'A:min', 'Bb:maj', 'C:maj', 'D:min', 'E:dim'],
    };

    final minorDiatonicChords = {
      'Am': ['A:min', 'B:dim', 'C:maj', 'D:min', 'E:min', 'F:maj', 'G:maj'],
      'Em': ['E:min', 'F#:dim', 'G:maj', 'A:min', 'B:min', 'C:maj', 'D:maj'],
      'Bm': ['B:min', 'C#:dim', 'D:maj', 'E:min', 'F#:min', 'G:maj', 'A:maj'],
      'F#m': ['F#:min', 'G#:dim', 'A:maj', 'B:min', 'C#:min', 'D:maj', 'E:maj'],
      'C#m': [
        'C#:min',
        'D#:dim',
        'E:maj',
        'F#:min',
        'G#:min',
        'A:maj',
        'B:maj',
      ],
      'G#m': [
        'G#:min',
        'A#:dim',
        'B:maj',
        'C#:min',
        'D#:min',
        'E:maj',
        'F#:maj',
      ],
      'D#m': [
        'D#:min',
        'E#:dim',
        'F#:maj',
        'G#:min',
        'A#:min',
        'B:maj',
        'C#:maj',
      ],
      'Bbm': [
        'Bb:min',
        'C:dim',
        'Db:maj',
        'Eb:min',
        'F:min',
        'Gb:maj',
        'Ab:maj',
      ],
      'Fm': ['F:min', 'G:dim', 'Ab:maj', 'Bb:min', 'C:min', 'Db:maj', 'Eb:maj'],
      'Cm': ['C:min', 'D:dim', 'Eb:maj', 'F:min', 'G:min', 'Ab:maj', 'Bb:maj'],
      'Gm': ['G:min', 'A:dim', 'Bb:maj', 'C:min', 'D:min', 'Eb:maj', 'F:maj'],
      'Dm': ['D:min', 'E:dim', 'F:maj', 'G:min', 'A:min', 'Bb:maj', 'C:maj'],
    };

    // Extract and normalize chords
    final progressionChords = <String>[];
    for (final chordData in chords) {
      final chord = chordData['chord'] as String;
      if (chord == 'N') continue;

      // Normalize chord format: "E:maj", "C#:min7" -> "E:maj", "C#:min"
      // Remove extensions (7, 9, etc.) and keep only root:quality
      var normalized = chord;
      if (chord.contains(':')) {
        final parts = chord.split(':');
        final root = parts[0];
        var quality = parts[1];

        // Strip extensions - keep only base quality (maj, min, dim, aug)
        if (quality.startsWith('min')) {
          quality = 'min';
        } else if (quality.startsWith('maj') ||
            quality == '7' ||
            quality.contains('7')) {
          quality = 'maj';
        } else if (quality.startsWith('dim')) {
          quality = 'dim';
        } else if (quality.startsWith('aug')) {
          quality = 'aug';
        }

        normalized = '$root:$quality';
      }
      progressionChords.add(normalized);
    }

    if (progressionChords.isEmpty) return 'C';

    // Score each possible key
    final keyScores = <String, double>{};

    for (final key in majorKeys) {
      final diatonic = majorDiatonicChords[key]!;
      var score = 0.0;

      for (var i = 0; i < progressionChords.length; i++) {
        final chord = progressionChords[i];
        final index = diatonic.indexOf(chord);

        if (index != -1) {
          // Weight important chords more heavily
          if (index == 0) {
            score += 3.0; // Tonic (I)
          } else if (index == 4) {
            score += 2.5; // Dominant (V)
          } else if (index == 3) {
            score += 2.0; // Subdominant (IV)
          } else {
            score += 1.0;
          }

          // Bonus for first/last chord being tonic
          if ((i == 0 || i == progressionChords.length - 1) && index == 0) {
            score += 2.0;
          }
        }
      }

      keyScores[key] = score;
    }

    for (final key in minorKeys) {
      final diatonic = minorDiatonicChords[key]!;
      var score = 0.0;

      for (var i = 0; i < progressionChords.length; i++) {
        final chord = progressionChords[i];
        final index = diatonic.indexOf(chord);

        if (index != -1) {
          if (index == 0) {
            score += 3.0; // Tonic (i)
          } else if (index == 4) {
            score += 2.5; // Dominant (v)
          } else if (index == 3) {
            score += 2.0; // Subdominant (iv)
          } else {
            score += 1.0;
          }

          if ((i == 0 || i == progressionChords.length - 1) && index == 0) {
            score += 2.0;
          }
        }
      }

      keyScores[key] = score;
    }

    // Find the key with highest score
    var bestKey = 'C';
    var bestScore = 0.0;

    keyScores.forEach((key, score) {
      if (score > bestScore) {
        bestScore = score;
        bestKey = key;
      }
    });

    return bestScore > 0 ? bestKey : 'C';
  }

  String _extractTitleFromFileName(String fileName) {
    // Remove extension and clean up
    final nameWithoutExt = fileName.split('.').first;
    return nameWithoutExt.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  }
}
