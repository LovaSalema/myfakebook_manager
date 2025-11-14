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

  /// NEW: Organize chord data into a grid structure for easy UI display
  Map<String, dynamic> organizeIntoGrid(
    Map<String, dynamic> apiData,
    String fileName, {
    int measuresPerRow = 4,
    int? maxMeasures,
  }) {
    try {
      print('Organizing chord data into grid...');

      final chordData = apiData['chords'];
      final beatData = apiData['beats'];

      if (chordData == null || beatData == null) {
        throw Exception('Missing API data');
      }

      final chords = chordData['chords'] as List;
      final downbeats = beatData['downbeats'] as List;
      final bpm = (beatData['bpm'] as num?)?.toDouble() ?? 120.0;

      final timeSignature = _parseTimeSignature(
        beatData['time_signature'],
        beatData['beats'],
        downbeats,
      );

      final beatsPerMeasure = _getBeatsPerMeasure(timeSignature);

      // Create measures from downbeats
      final measures = _createMeasuresFromDownbeats(
        chords,
        downbeats,
        timeSignature,
      );

      // Limit measures if specified
      final finalMeasures = maxMeasures != null && maxMeasures < measures.length
          ? measures.sublist(0, maxMeasures)
          : measures;

      // Organize into grid rows
      final grid = <Map<String, dynamic>>[];

      for (int i = 0; i < finalMeasures.length; i += measuresPerRow) {
        final endIndex = (i + measuresPerRow).clamp(0, finalMeasures.length);
        final rowMeasures = finalMeasures.sublist(i, endIndex);

        // Flatten measures into a single row of cells
        final rowCells = <Map<String, dynamic>>[];

        for (int mIdx = 0; mIdx < rowMeasures.length; mIdx++) {
          final measure = rowMeasures[mIdx];

          for (int beatIdx = 0; beatIdx < measure.chords.length; beatIdx++) {
            rowCells.add({
              'chord': measure.chords[beatIdx],
              'measureIndex': i + mIdx,
              'beatIndex': beatIdx,
              'isDownbeat': beatIdx == 0,
              'isEmpty': measure.chords[beatIdx].isEmpty,
            });
          }
        }

        grid.add({
          'rowIndex': grid.length,
          'measureStartIndex': i,
          'measureEndIndex': endIndex - 1,
          'cells': rowCells,
          'measuresInRow': rowMeasures.length,
        });
      }

      // Detect key and extract metadata
      final detectedKey = _detectKey(chords);
      final title = _extractTitleFromFileName(fileName);

      return {
        'grid': grid,
        'metadata': {
          'title': title,
          'artist': 'Unknown',
          'key': detectedKey,
          'timeSignature': timeSignature,
          'bpm': bpm.round(),
          'beatsPerMeasure': beatsPerMeasure,
          'totalMeasures': finalMeasures.length,
          'measuresPerRow': measuresPerRow,
        },
        'rawMeasures': finalMeasures
            .map(
              (m) => {
                'chords': m.chords,
                'measureOrder': m.measureOrder,
                'timeSignature': m.timeSignature,
              },
            )
            .toList(),
      };
    } catch (e) {
      print('Error in organizeIntoGrid: $e');
      throw Exception('Error organizing chord grid: $e');
    }
  }

  /// Convert API data to Song object (original method)
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
        songId: 0,
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
  String _parseTimeSignature(dynamic timeSig, List? beats, List? downbeats) {
    if (timeSig == null) {
      print('No time signature provided, defaulting to 4/4');
      return '4/4';
    }

    String timeSignature;

    if (timeSig is String) {
      timeSignature = timeSig;
    } else if (timeSig is int) {
      timeSignature = '$timeSig/4';
    } else if (timeSig is List && timeSig.length >= 2) {
      timeSignature = '${timeSig[0]}/${timeSig[1]}';
    } else {
      print('Unexpected time signature format: $timeSig, defaulting to 4/4');
      return '4/4';
    }

    if (!RegExp(r'^\d+/\d+$').hasMatch(timeSignature)) {
      print('Invalid time signature format: $timeSignature, defaulting to 4/4');
      return '4/4';
    }

    final parts = timeSignature.split('/');
    final numerator = int.tryParse(parts[0]);

    if (numerator == null || parts.length != 2) {
      print(
        'Could not parse time signature: $timeSignature, defaulting to 4/4',
      );
      return '4/4';
    }

    if (numerator < 1 || numerator > 16) {
      print('Invalid numerator: $numerator, defaulting to 4/4');
      return '4/4';
    }

    print('Using time signature from API: $timeSignature');
    return timeSignature;
  }

  /// Get beats per measure from time signature (toujours le numérateur)
  int _getBeatsPerMeasure(String timeSignature) {
    final parts = timeSignature.split('/');
    final numerator = int.parse(parts[0]);
    return numerator; // 6/8 = 6 beats, 4/4 = 4 beats
  }

  /// Convert chord from API format to display format
  String _convertChordFormat(String apiChord) {
    if (apiChord == 'N') {
      return '%';
    }

    if (!apiChord.contains(':')) {
      return apiChord;
    }

    final parts = apiChord.split(':');
    if (parts.length != 2) return apiChord;

    final root = parts[0];
    final quality = parts[1];

    if (quality.startsWith('min')) {
      final extension = quality.substring(3);
      return '$root${extension.isEmpty ? 'm' : 'm$extension'}';
    }

    if (quality.startsWith('maj')) {
      final extension = quality.substring(3);
      return '$root$extension';
    }

    if (quality.startsWith('dim')) {
      final extension = quality.substring(3);
      return '$root${extension.isEmpty ? '°' : '°$extension'}';
    }

    if (quality.startsWith('aug')) {
      final extension = quality.substring(3);
      return '$root${extension.isEmpty ? '+' : '+$extension'}';
    }

    if (quality.contains(RegExp(r'^\d'))) {
      return '$root$quality';
    }

    return '$root$quality';
  }

  /// Create measures from downbeats and chords
  /// CORRECTION: Synchronise les chords avec les beats de chaque mesure
  List<Measure> _createMeasuresFromDownbeats(
    List chords,
    List downbeats,
    String timeSignature,
  ) {
    final beatsPerMeasure = _getBeatsPerMeasure(timeSignature);
    final measures = <Measure>[];

    final downbeatTimes = downbeats.map((db) => (db as num).toDouble()).toList()
      ..sort();

    print('Creating measures from ${downbeatTimes.length} downbeats...');
    print('Time signature: $timeSignature');
    print('Beats per measure: $beatsPerMeasure');

    int measureOrder = 0;

    // Handle intro measure if exists (before first downbeat)
    if (downbeatTimes.isNotEmpty && downbeatTimes[0] > 0.1) {
      bool hasChordsBefore = chords.any(
        (c) => (c['start'] as num).toDouble() < downbeatTimes[0],
      );

      if (hasChordsBefore) {
        final measureStart = 0.0;
        final measureEnd = downbeatTimes[0];

        final measure = _createMeasureWithBeatSync(
          chords,
          measureStart,
          measureEnd,
          beatsPerMeasure,
          timeSignature,
          measureOrder,
          null,
        );

        measures.add(measure);
        print('Measure $measureOrder (intro): $measureStart - $measureEnd');
        print('  Chords: ${measure.chords}');
        measureOrder++;
      }
    }

    // Process regular measures between downbeats
    for (int i = 0; i < downbeatTimes.length - 1; i++) {
      final measureStart = downbeatTimes[i];
      final measureEnd = downbeatTimes[i + 1];

      final previousMeasure = measures.isNotEmpty ? measures.last : null;

      final measure = _createMeasureWithBeatSync(
        chords,
        measureStart,
        measureEnd,
        beatsPerMeasure,
        timeSignature,
        measureOrder,
        previousMeasure,
      );

      measures.add(measure);
      print('Measure $measureOrder: $measureStart - $measureEnd');
      print('  Chords: ${measure.chords}');
      measureOrder++;
    }

    // Handle last measure if there are chords after last downbeat
    if (downbeatTimes.isNotEmpty) {
      final lastDownbeat = downbeatTimes.last;
      final hasChordsAfter = chords.any(
        (c) => (c['start'] as num).toDouble() >= lastDownbeat,
      );

      if (hasChordsAfter) {
        final avgDuration = downbeatTimes.length > 1
            ? (downbeatTimes.last - downbeatTimes.first) /
                  (downbeatTimes.length - 1)
            : 2.0;

        final measureStart = lastDownbeat;
        final measureEnd = lastDownbeat + avgDuration;

        final previousMeasure = measures.isNotEmpty ? measures.last : null;

        final measure = _createMeasureWithBeatSync(
          chords,
          measureStart,
          measureEnd,
          beatsPerMeasure,
          timeSignature,
          measureOrder,
          previousMeasure,
        );

        measures.add(measure);
        print('Measure $measureOrder (last): $measureStart - $measureEnd');
        print('  Chords: ${measure.chords}');
        measureOrder++;
      }
    }

    // Pad to minimum 4 measures if needed
    if (measures.length < 4) {
      print('Padding to minimum 4 measures (currently ${measures.length})');

      final lastChord = measures.isNotEmpty && measures.last.chords.isNotEmpty
          ? measures.last.chords.firstWhere(
              (c) => c.isNotEmpty && c != '-',
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

  /// CORRECTION PRINCIPALE: Créer une mesure avec synchronisation précise des accords
  /// Cette méthode divise chaque mesure en beats et assigne le bon accord à chaque beat
  Measure _createMeasureWithBeatSync(
    List chords,
    double measureStart,
    double measureEnd,
    int beatsPerMeasure,
    String timeSignature,
    int measureOrder,
    Measure? previousMeasure,
  ) {
    final measureDuration = measureEnd - measureStart;
    final beatDuration = measureDuration / beatsPerMeasure;

    // Initialiser le tableau de chords pour cette mesure
    final measureChords = List<String>.filled(beatsPerMeasure, '');

    print(
      '  Creating measure $measureOrder: start=$measureStart, end=$measureEnd, duration=$measureDuration',
    );
    print(
      '  Beat duration: $beatDuration, beats per measure: $beatsPerMeasure',
    );

    // DEBUG: Log all chords in this time range
    print('  Available chords in measure range:');
    for (final chordData in chords) {
      final chordStart = (chordData['start'] as num).toDouble();
      final chordEnd = (chordData['end'] as num).toDouble();
      final chordName = chordData['chord'] as String;
      if (chordStart < measureEnd && chordEnd > measureStart) {
        print('    Chord: $chordName from $chordStart to $chordEnd');
      }
    }

    // IMPROVED METHOD: Quantize chord starts to beat boundaries and assign accordingly
    // First, collect all chord changes within this measure
    final chordChanges = <Map<String, dynamic>>[];

    for (final chordData in chords) {
      final chordStart = (chordData['start'] as num).toDouble();
      final chordEnd = (chordData['end'] as num).toDouble();

      if (chordStart < measureEnd && chordEnd > measureStart) {
        // Quantize start time to nearest beat boundary
        final relativeStart = chordStart - measureStart;
        final beatIndex = (relativeStart / beatDuration).round();
        final quantizedStart = measureStart + (beatIndex * beatDuration);

        chordChanges.add({
          'originalStart': chordStart,
          'quantizedStart': quantizedStart.clamp(measureStart, measureEnd),
          'end': chordEnd,
          'chord': _convertChordFormat(chordData['chord'] as String),
          'beatIndex': beatIndex.clamp(0, beatsPerMeasure - 1),
        });

        print(
          '    Chord change: ${chordData['chord']} at $chordStart -> quantized to beat ${beatIndex} ($quantizedStart)',
        );
      }
    }

    // Sort chord changes by quantized start time
    chordChanges.sort(
      (a, b) => (a['quantizedStart'] as double).compareTo(
        b['quantizedStart'] as double,
      ),
    );

    print('    Sorted chord changes: $chordChanges');

    // Assign chords to beats based on quantized positions
    String currentChord = '';
    int currentChangeIndex = 0;

    for (int beatIdx = 0; beatIdx < beatsPerMeasure; beatIdx++) {
      final beatStart = measureStart + (beatIdx * beatDuration);

      // Check if there's a chord change at or before this beat
      while (currentChangeIndex < chordChanges.length &&
          (chordChanges[currentChangeIndex]['quantizedStart'] as double) <=
              beatStart) {
        currentChord = chordChanges[currentChangeIndex]['chord'] as String;
        print('    Beat $beatIdx: chord change to $currentChord');
        currentChangeIndex++;
      }

      // If we have a current chord and it still active at this beat
      if (currentChord.isNotEmpty) {
        // Check if the chord is still active (ends after beat start)
        bool isActive = false;
        for (final change in chordChanges) {
          if (change['chord'] == currentChord &&
              (change['end'] as double) > beatStart) {
            isActive = true;
            break;
          }
        }

        if (isActive) {
          measureChords[beatIdx] = currentChord;
          print('    Assigned: $currentChord to beat $beatIdx');
        } else {
          print('    Beat $beatIdx: chord $currentChord no longer active');
        }
      } else {
        print('    Beat $beatIdx: no chord assigned yet');
      }
    }

    // Forward fill: si un beat n'a pas de chord, utiliser le précédent
    String lastChord = '';

    // Essayer de commencer avec le dernier chord de la mesure précédente
    if (previousMeasure != null && measureChords[0].isEmpty) {
      final prevChords = previousMeasure.chords;
      for (int i = prevChords.length - 1; i >= 0; i--) {
        if (prevChords[i].isNotEmpty &&
            prevChords[i] != '-' &&
            prevChords[i] != '%') {
          lastChord = prevChords[i];
          print('  Using last chord from previous measure: $lastChord');
          break;
        }
      }
    }

    // Forward fill les beats vides
    for (int beatIdx = 0; beatIdx < beatsPerMeasure; beatIdx++) {
      if (measureChords[beatIdx].isNotEmpty &&
          measureChords[beatIdx] != '%' &&
          measureChords[beatIdx] != '-') {
        lastChord = measureChords[beatIdx];
      } else if (measureChords[beatIdx].isEmpty && lastChord.isNotEmpty) {
        measureChords[beatIdx] = lastChord;
        print('  Beat $beatIdx: forward filled with $lastChord');
      }
    }

    // Remplacer les accords consécutifs identiques par '-'
    String previousChord = '';
    for (int beatIdx = 0; beatIdx < beatsPerMeasure; beatIdx++) {
      final chord = measureChords[beatIdx];

      if (chord.isNotEmpty && chord != '%' && chord == previousChord) {
        measureChords[beatIdx] = '-';
      } else if (chord.isNotEmpty && chord != '%' && chord != '-') {
        previousChord = chord;
      }
    }

    print('  Final measure chords: $measureChords');

    return Measure.create(
      sectionId: 0,
      measureOrder: measureOrder,
      timeSignature: timeSignature,
    ).copyWith(chords: measureChords);
  }

  /// Detect key from chord progression
  String _detectKey(List chords) {
    if (chords.isEmpty) return 'C';

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

    final progressionChords = <String>[];
    for (final chordData in chords) {
      final chord = chordData['chord'] as String;
      if (chord == 'N') continue;

      var normalized = chord;
      if (chord.contains(':')) {
        final parts = chord.split(':');
        final root = parts[0];
        var quality = parts[1];

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

    final keyScores = <String, double>{};

    for (final key in majorKeys) {
      final diatonic = majorDiatonicChords[key]!;
      var score = 0.0;

      for (var i = 0; i < progressionChords.length; i++) {
        final chord = progressionChords[i];
        final index = diatonic.indexOf(chord);

        if (index != -1) {
          if (index == 0) {
            score += 3.0;
          } else if (index == 4) {
            score += 2.5;
          } else if (index == 3) {
            score += 2.0;
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

    for (final key in minorKeys) {
      final diatonic = minorDiatonicChords[key]!;
      var score = 0.0;

      for (var i = 0; i < progressionChords.length; i++) {
        final chord = progressionChords[i];
        final index = diatonic.indexOf(chord);

        if (index != -1) {
          if (index == 0) {
            score += 3.0;
          } else if (index == 4) {
            score += 2.5;
          } else if (index == 3) {
            score += 2.0;
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
    final nameWithoutExt = fileName.split('.').first;
    return nameWithoutExt.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  }
}
