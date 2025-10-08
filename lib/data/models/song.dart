import 'package:flutter/material.dart';
import '../models/section.dart';
import '../models/structure.dart';

/// Represents a complete song with musical structure
class Song {
  final int? id;
  final String title;
  final String artist;
  final String key;
  final String timeSignature;
  final int? tempo;
  final String? style;
  final String notationType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final Structure? structure;
  final List<Section> sections;

  const Song({
    this.id,
    required this.title,
    required this.artist,
    required this.key,
    required this.timeSignature,
    this.tempo,
    this.style,
    required this.notationType,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.structure,
    required this.sections,
  });

  /// Creates a new Song with default values
  factory Song.create({
    required String title,
    required String artist,
    String key = 'C',
    String timeSignature = '4/4',
    int? tempo,
    String? style,
    String notationType = 'CHORDS',
  }) {
    final now = DateTime.now();
    return Song(
      title: title,
      artist: artist,
      key: key,
      timeSignature: timeSignature,
      tempo: tempo,
      style: style,
      notationType: notationType,
      createdAt: now,
      updatedAt: now,
      isFavorite: false,
      sections: [],
    );
  }

  /// Converts Song to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'key': key,
      'time_signature': timeSignature,
      'tempo': tempo,
      'style': style,
      'notation_type': notationType,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  /// Creates Song from Map (database result)
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'],
      title: map['title'],
      artist: map['artist'],
      key: map['key'],
      timeSignature: map['time_signature'],
      tempo: map['tempo'],
      style: map['style'],
      notationType: map['notation_type'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      isFavorite: map['is_favorite'] == 1,
      sections: [], // Sections will be loaded separately
    );
  }

  /// Creates a copy of the Song with updated fields
  Song copyWith({
    int? id,
    String? title,
    String? artist,
    String? key,
    String? timeSignature,
    int? tempo,
    String? style,
    String? notationType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    Structure? structure,
    List<Section>? sections,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      key: key ?? this.key,
      timeSignature: timeSignature ?? this.timeSignature,
      tempo: tempo ?? this.tempo,
      style: style ?? this.style,
      notationType: notationType ?? this.notationType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      structure: structure ?? this.structure,
      sections: sections ?? this.sections,
    );
  }

  /// Validates song data
  bool validate() {
    if (title.isEmpty || artist.isEmpty) return false;
    if (!['CHORDS', 'ROMAN_NUMERALS'].contains(notationType)) return false;
    if (!_isValidKey(key)) return false;
    if (!_isValidTimeSignature(timeSignature)) return false;
    if (tempo != null && (tempo! < 20 || tempo! > 300)) return false;
    return true;
  }

  /// Checks if key is valid
  bool _isValidKey(String key) {
    final validKeys = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
      'Cm',
      'C#m',
      'Dm',
      'D#m',
      'Em',
      'Fm',
      'F#m',
      'Gm',
      'G#m',
      'Am',
      'A#m',
      'Bm',
    ];
    return validKeys.contains(key);
  }

  /// Checks if time signature is valid
  bool _isValidTimeSignature(String timeSignature) {
    final validSignatures = [
      '4/4',
      '3/4',
      '2/4',
      '6/8',
      '12/8',
      '2/2',
      '3/2',
      '5/4',
      '7/4',
    ];
    return validSignatures.contains(timeSignature);
  }

  /// Gets the total number of measures in the song
  int get totalMeasures {
    return sections.fold(
      0,
      (total, section) => total + section.measures.length,
    );
  }

  /// Gets the duration in minutes (approximate)
  double get estimatedDuration {
    if (tempo == null) return 0.0;
    final totalBeats = totalMeasures * _getBeatsPerMeasure();
    return totalBeats / tempo!;
  }

  /// Gets beats per measure based on time signature
  int _getBeatsPerMeasure() {
    final parts = timeSignature.split('/');
    if (parts.length != 2) return 4;
    return int.tryParse(parts[0]) ?? 4;
  }

  /// Gets all chords used in the song
  Set<String> get allChords {
    final chords = <String>{};
    for (final section in sections) {
      for (final measure in section.measures) {
        chords.addAll(measure.chords.where((chord) => chord.isNotEmpty));
      }
    }
    return chords;
  }

  /// Transposes the song to a new key
  Song transpose(String newKey) {
    // This would require a transposition service
    // For now, return a copy with the new key
    return copyWith(key: newKey, updatedAt: DateTime.now());
  }

  /// Checks if the song has a complete structure
  bool get hasCompleteStructure {
    return sections.isNotEmpty &&
        sections.every((section) => section.measures.length >= 4);
  }

  /// Gets the song's structure pattern (AABA, ABAB, etc.)
  String get structurePattern {
    if (structure != null) return structure!.pattern;

    // Generate pattern from section labels
    final labels = sections.map((s) => s.sectionLabel).toList();
    return labels.join();
  }

  @override
  String toString() {
    return 'Song(id: $id, title: $title, artist: $artist, key: $key, timeSignature: $timeSignature, tempo: $tempo, notationType: $notationType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Song &&
        other.id == id &&
        other.title == title &&
        other.artist == artist &&
        other.key == key &&
        other.timeSignature == timeSignature &&
        other.tempo == tempo &&
        other.style == style &&
        other.notationType == notationType &&
        other.isFavorite == isFavorite;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      artist,
      key,
      timeSignature,
      tempo,
      style,
      notationType,
      isFavorite,
    );
  }
}
