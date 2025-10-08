import '../models/measure.dart';

/// Represents a section of a song (verse, chorus, bridge, etc.)
class Section {
  final int? id;
  final int songId;
  final String sectionType;
  final String sectionLabel;
  final String? sectionName;
  final int sectionOrder;
  final List<Measure> measures;
  final int repeatCount;
  final bool hasRepeatSign;

  const Section({
    this.id,
    required this.songId,
    required this.sectionType,
    required this.sectionLabel,
    this.sectionName,
    required this.sectionOrder,
    required this.measures,
    this.repeatCount = 1,
    this.hasRepeatSign = false,
  });

  /// Creates a new Section with default measures
  factory Section.create({
    required int songId,
    required String sectionType,
    required String sectionLabel,
    String? sectionName,
    required int sectionOrder,
    String timeSignature = '4/4',
    int measureCount = 4,
  }) {
    final measures = List<Measure>.generate(
      measureCount,
      (index) => Measure.create(
        sectionId: 0, // Will be set when saved
        measureOrder: index,
        timeSignature: timeSignature,
      ),
    );

    return Section(
      songId: songId,
      sectionType: sectionType,
      sectionLabel: sectionLabel,
      sectionName: sectionName,
      sectionOrder: sectionOrder,
      measures: measures,
      repeatCount: 1,
      hasRepeatSign: false,
    );
  }

  /// Converts Section to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'songId': songId,
      'sectionType': sectionType,
      'sectionLabel': sectionLabel,
      'sectionName': sectionName,
      'sectionOrder': sectionOrder,
      'repeatCount': repeatCount,
      'hasRepeatSign': hasRepeatSign ? 1 : 0,
    };
  }

  /// Creates Section from Map (database result)
  factory Section.fromMap(Map<String, dynamic> map) {
    return Section(
      id: map['id'],
      songId: map['songId'],
      sectionType: map['sectionType'],
      sectionLabel: map['sectionLabel'],
      sectionName: map['sectionName'],
      sectionOrder: map['sectionOrder'],
      measures: [], // Measures will be loaded separately
      repeatCount: map['repeatCount'] ?? 1,
      hasRepeatSign: map['hasRepeatSign'] == 1,
    );
  }

  /// Creates a copy of the Section with updated fields
  Section copyWith({
    int? id,
    int? songId,
    String? sectionType,
    String? sectionLabel,
    String? sectionName,
    int? sectionOrder,
    List<Measure>? measures,
    int? repeatCount,
    bool? hasRepeatSign,
  }) {
    return Section(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      sectionType: sectionType ?? this.sectionType,
      sectionLabel: sectionLabel ?? this.sectionLabel,
      sectionName: sectionName ?? this.sectionName,
      sectionOrder: sectionOrder ?? this.sectionOrder,
      measures: measures ?? this.measures,
      repeatCount: repeatCount ?? this.repeatCount,
      hasRepeatSign: hasRepeatSign ?? this.hasRepeatSign,
    );
  }

  /// Validates section data
  bool validate() {
    if (!_isValidSectionType(sectionType)) return false;
    if (!_isValidSectionLabel(sectionLabel)) return false;
    if (sectionOrder < 0) return false;
    if (repeatCount < 1) return false;
    if (measures.length < 4) return false; // Minimum 4 measures per section

    // Validate all measures
    for (final measure in measures) {
      if (!measure.validate()) return false;
    }

    return true;
  }

  /// Checks if section type is valid
  bool _isValidSectionType(String type) {
    final validTypes = [
      'INTRO',
      'VERSE',
      'CHORUS',
      'BRIDGE',
      'OUTRO',
      'SOLO',
      'INTERLUDE',
      'PRE-CHORUS',
      'POST-CHORUS',
      'BREAK',
      'INSTRUMENTAL',
      'CODA',
    ];
    return validTypes.contains(type);
  }

  /// Checks if section label is valid
  bool _isValidSectionLabel(String label) {
    final regex = RegExp(r'^[A-Z]$');
    return regex.hasMatch(label);
  }

  /// Gets the display name for the section
  String get displayName {
    if (sectionName != null && sectionName!.isNotEmpty) {
      return sectionName!;
    }

    final typeNames = {
      'INTRO': 'Intro',
      'VERSE': 'Verse',
      'CHORUS': 'Chorus',
      'BRIDGE': 'Bridge',
      'OUTRO': 'Outro',
      'SOLO': 'Solo',
      'INTERLUDE': 'Interlude',
      'PRE-CHORUS': 'Pre-Chorus',
      'POST-CHORUS': 'Post-Chorus',
      'BREAK': 'Break',
      'INSTRUMENTAL': 'Instrumental',
      'CODA': 'Coda',
    };

    return typeNames[sectionType] ?? sectionType;
  }

  /// Gets the total number of measures including repeats
  int get totalMeasures {
    return measures.length * repeatCount;
  }

  /// Gets all chords used in this section
  Set<String> get allChords {
    final chords = <String>{};
    for (final measure in measures) {
      chords.addAll(measure.chords.where((chord) => chord.isNotEmpty));
    }
    return chords;
  }

  /// Adds a measure to the section
  Section addMeasure(Measure measure) {
    final newMeasures = List<Measure>.from(measures)..add(measure);
    return copyWith(measures: newMeasures);
  }

  /// Removes a measure from the section
  Section removeMeasure(int measureOrder) {
    final newMeasures = List<Measure>.from(measures)
      ..removeWhere((measure) => measure.measureOrder == measureOrder);

    // Reorder remaining measures
    for (int i = 0; i < newMeasures.length; i++) {
      newMeasures[i] = newMeasures[i].copyWith(measureOrder: i);
    }

    return copyWith(measures: newMeasures);
  }

  /// Updates a measure in the section
  Section updateMeasure(int measureOrder, Measure updatedMeasure) {
    final newMeasures = List<Measure>.from(measures);
    final index = newMeasures.indexWhere((m) => m.measureOrder == measureOrder);

    if (index != -1) {
      newMeasures[index] = updatedMeasure;
    }

    return copyWith(measures: newMeasures);
  }

  /// Gets the measure at the specified order
  Measure? getMeasure(int measureOrder) {
    try {
      return measures.firstWhere(
        (measure) => measure.measureOrder == measureOrder,
      );
    } catch (e) {
      return null;
    }
  }

  /// Checks if this section has special symbols
  bool get hasSpecialSymbols {
    return hasRepeatSign ||
        measures.any((measure) => measure.specialSymbol != null);
  }

  /// Gets the color for this section type
  int get color {
    final colors = {
      'INTRO': 0xFFFBBF24, // Yellow
      'VERSE': 0xFF60A5FA, // Blue
      'CHORUS': 0xFF34D399, // Green
      'BRIDGE': 0xFFA78BFA, // Purple
      'OUTRO': 0xFFF87171, // Red
      'SOLO': 0xFFF472B6, // Pink
      'INTERLUDE': 0xFFF59E0B, // Orange
      'PRE-CHORUS': 0xFF6EE7B7, // Light Green
      'POST-CHORUS': 0xFF93C5FD, // Light Blue
      'BREAK': 0xFFD1D5DB, // Gray
      'INSTRUMENTAL': 0xFF9CA3AF, // Dark Gray
      'CODA': 0xFF7DD3FC, // Light Blue
    };

    return colors[sectionType] ?? 0xFF3B82F6; // Default blue
  }

  @override
  String toString() {
    return 'Section(id: $id, songId: $songId, type: $sectionType, label: $sectionLabel, order: $sectionOrder, measures: ${measures.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Section &&
        other.id == id &&
        other.songId == songId &&
        other.sectionType == sectionType &&
        other.sectionLabel == sectionLabel &&
        other.sectionName == sectionName &&
        other.sectionOrder == sectionOrder &&
        other.repeatCount == repeatCount &&
        other.hasRepeatSign == hasRepeatSign;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      songId,
      sectionType,
      sectionLabel,
      sectionName,
      sectionOrder,
      repeatCount,
      hasRepeatSign,
    );
  }
}
