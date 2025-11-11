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
      beatRequest.fields['model'] = 'auto';

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
      if (downbeats == null || downbeats.isEmpty) {
        throw Exception('Données de downbeats manquantes');
      }
      print('Total downbeats: ${downbeats.length}');

      final bpm = (beatData['bpm'] as num?)?.toDouble();
      if (bpm == null) {
        throw Exception('BPM manquant');
      }
      print('BPM: $bpm');

      final timeSignature = beatData['time_signature'] as String? ?? '4/4';
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

  /// Create measures from downbeats and chords
  List<Measure> _createMeasuresFromDownbeats(
    List chords,
    List downbeats,
    String timeSignature,
  ) {
    final beatsPerMeasure = _getBeatsPerMeasure(timeSignature);
    final measures = <Measure>[];

    // Convert downbeats to doubles
    final downbeatTimes = downbeats
        .map((db) => (db as num).toDouble())
        .toList();

    print('Creating measures from ${downbeatTimes.length} downbeats...');

    for (int i = 0; i < downbeatTimes.length - 1; i++) {
      final measureStart = downbeatTimes[i];
      final measureEnd = downbeatTimes[i + 1];

      // Initialize measure with empty chords
      final measureChords = List<String>.filled(beatsPerMeasure, '');

      // Find chords that start within this measure
      for (final chordData in chords) {
        final chordName = chordData['chord'] as String;
        final start = (chordData['start'] as num).toDouble();
        final end = (chordData['end'] as num).toDouble();

        // Skip 'N' (no chord)
        if (chordName == 'N') continue;

        // Check if chord starts in this measure
        if (start >= measureStart && start < measureEnd) {
          // Convert API format to display format
          final displayChord = _convertChordFormat(chordName);

          // Calculate which beat within the measure
          final positionInMeasure =
              (start - measureStart) / (measureEnd - measureStart);
          final beatIndex = (positionInMeasure * beatsPerMeasure).floor();

          if (beatIndex >= 0 && beatIndex < beatsPerMeasure) {
            measureChords[beatIndex] = displayChord;
            print('Assigned $displayChord to measure $i, beat $beatIndex');
          }
        }
      }

      // Ensure at least one chord per measure
      if (measureChords.every((c) => c.isEmpty)) {
        // If no chords in measure, use the last known chord or first chord
        if (measures.isNotEmpty) {
          final lastMeasure = measures.last;
          final lastChord = lastMeasure.chords.lastWhere(
            (c) => c.isNotEmpty,
            orElse: () => '',
          );
          if (lastChord.isNotEmpty) {
            measureChords[0] = lastChord;
          }
        }
      }

      final measure = Measure.create(
        sectionId: 0,
        measureOrder: i,
        timeSignature: timeSignature,
      ).copyWith(chords: measureChords);

      measures.add(measure);
    }

    // Ensure we have at least 4 measures
    while (measures.length < 4) {
      final lastChord = measures.isNotEmpty && measures.last.chords.isNotEmpty
          ? measures.last.chords.first
          : '';

      measures.add(
        Measure.create(
          sectionId: 0,
          measureOrder: measures.length,
          timeSignature: timeSignature,
        ).copyWith(
          chords: List<String>.filled(
            beatsPerMeasure,
            lastChord.isEmpty ? '' : lastChord,
          ),
        ),
      );
    }

    return measures;
  }

  /// Convert API chord format to display format
  String _convertChordFormat(String apiChord) {
    // API format: "E:maj", "C#:min", "F#:min7", "B:7"
    // Display format: "E", "C#m", "F#m7", "B7"

    if (apiChord == 'N') return '';

    final parts = apiChord.split(':');
    if (parts.length != 2) return apiChord;

    final root = parts[0];
    final quality = parts[1];

    // Convert quality
    if (quality == 'maj') return root;
    if (quality == 'min') return '${root}m';
    if (quality == 'dim') return '${root}°';
    if (quality == 'aug') return '${root}+';

    // Handle complex chords
    if (quality.contains('min7')) return '${root}m7';
    if (quality.contains('maj7')) return '${root}maj7';
    if (quality.contains('7')) return root + quality;
    if (quality.contains('sus')) return root + quality;

    // Default: just concatenate
    return root + quality;
  }

  /// Detect key from chord progression
  String _detectKey(List chords) {
    final chordCounts = <String, int>{};

    for (final chordData in chords) {
      final chord = chordData['chord'] as String;
      if (chord == 'N') continue;

      // Extract root note
      final root = chord.split(':').first;
      chordCounts[root] = (chordCounts[root] ?? 0) + 1;
    }

    if (chordCounts.isEmpty) return 'C';

    // Find most common root note
    final sortedRoots = chordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedRoots.first.key;
  }

  String _extractTitleFromFileName(String fileName) {
    // Remove extension and clean up
    final nameWithoutExt = fileName.split('.').first;
    return nameWithoutExt.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  }

  int _getBeatsPerMeasure(String timeSignature) {
    final parts = timeSignature.split('/');
    if (parts.length != 2) return 4;
    return int.tryParse(parts[0]) ?? 4;
  }
}
