/// Represents a single measure in a song section
class Measure {
  final int? id;
  final int sectionId;
  final int measureOrder;
  final String timeSignature;
  final List<String> chords;
  final String? specialSymbol;
  final bool hasFirstEnding;
  final bool hasSecondEnding;

  const Measure({
    this.id,
    required this.sectionId,
    required this.measureOrder,
    required this.timeSignature,
    required this.chords,
    this.specialSymbol,
    this.hasFirstEnding = false,
    this.hasSecondEnding = false,
  });

  /// Creates a new Measure with default chords
  factory Measure.create({
    required int sectionId,
    required int measureOrder,
    required String timeSignature,
  }) {
    final maxChords = _getMaxChordsForTimeSignature(timeSignature);
    final chords = List<String>.filled(maxChords, '');

    return Measure(
      sectionId: sectionId,
      measureOrder: measureOrder,
      timeSignature: timeSignature,
      chords: chords,
      specialSymbol: null,
      hasFirstEnding: false,
      hasSecondEnding: false,
    );
  }

  /// Converts Measure to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sectionId': sectionId,
      'measureOrder': measureOrder,
      'timeSignature': timeSignature,
      'chords': chords.join('|'), // Store chords as pipe-separated string
      'specialSymbol': specialSymbol,
      'hasFirstEnding': hasFirstEnding ? 1 : 0,
      'hasSecondEnding': hasSecondEnding ? 1 : 0,
    };
  }

  /// Creates Measure from Map (database result)
  factory Measure.fromMap(Map<String, dynamic> map) {
    final chordsString = map['chords'] as String? ?? '';
    final chords = chordsString.split('|');

    return Measure(
      id: map['id'],
      sectionId: map['sectionId'],
      measureOrder: map['measureOrder'],
      timeSignature: map['timeSignature'],
      chords: chords,
      specialSymbol: map['specialSymbol'],
      hasFirstEnding: map['hasFirstEnding'] == 1,
      hasSecondEnding: map['hasSecondEnding'] == 1,
    );
  }

  /// Creates a copy of the Measure with updated fields
  Measure copyWith({
    int? id,
    int? sectionId,
    int? measureOrder,
    String? timeSignature,
    List<String>? chords,
    String? specialSymbol,
    bool? hasFirstEnding,
    bool? hasSecondEnding,
  }) {
    return Measure(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      measureOrder: measureOrder ?? this.measureOrder,
      timeSignature: timeSignature ?? this.timeSignature,
      chords: chords ?? this.chords,
      specialSymbol: specialSymbol ?? this.specialSymbol,
      hasFirstEnding: hasFirstEnding ?? this.hasFirstEnding,
      hasSecondEnding: hasSecondEnding ?? this.hasSecondEnding,
    );
  }

  /// Validates measure data
  bool validate() {
    if (!_isValidTimeSignature(timeSignature)) return false;
    if (measureOrder < 0) return false;

    final maxChords = _getMaxChordsForTimeSignature(timeSignature);
    if (chords.length > maxChords) return false;

    // Validate chords
    for (final chord in chords) {
      if (chord.isNotEmpty && !_isValidChord(chord)) return false;
    }

    // Validate special symbol
    if (specialSymbol != null && !_isValidSpecialSymbol(specialSymbol!)) {
      return false;
    }

    return true;
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

  /// Checks if chord is valid
  bool _isValidChord(String chord) {
    if (chord.isEmpty) return true;

    // Simple chord validation - check if it starts with a valid note
    final rootPattern = RegExp(r'^[A-G][#♯b♭]?');
    return rootPattern.hasMatch(chord);
  }

  /// Checks if special symbol is valid
  bool _isValidSpecialSymbol(String symbol) {
    final validSymbols = [
      '%',
      'D.C.',
      'D.S.',
      'Fine',
      'Coda',
      'To Coda',
      '1.',
      '2.',
      '3.',
      '4.',
    ];
    return validSymbols.contains(symbol);
  }

  /// Gets the maximum number of chords for a time signature
  static int _getMaxChordsForTimeSignature(String timeSignature) {
    switch (timeSignature) {
      case '4/4':
      case '2/2':
      case '2/4':
        return 4;
      case '3/4':
        return 3;
      case '6/8':
        return 6;
      case '12/8':
        return 12;
      case '5/4':
        return 5;
      case '7/4':
        return 7;
      default:
        return 4;
    }
  }

  /// Gets the number of beats per measure
  int get beatsPerMeasure {
    final parts = timeSignature.split('/');
    if (parts.length != 2) return 4;
    return int.tryParse(parts[0]) ?? 4;
  }

  /// Gets the beat value (quarter note, eighth note, etc.)
  int get beatValue {
    final parts = timeSignature.split('/');
    if (parts.length != 2) return 4;
    return int.tryParse(parts[1]) ?? 4;
  }

  /// Checks if the measure is empty (no chords)
  bool get isEmpty {
    return chords.every((chord) => chord.isEmpty);
  }

  /// Gets the number of chords in the measure
  int get chordCount {
    return chords.where((chord) => chord.isNotEmpty).length;
  }

  /// Sets a chord at a specific position
  Measure setChord(int position, String chord) {
    if (position < 0 || position >= chords.length) return this;

    final newChords = List<String>.from(chords);
    newChords[position] = chord;

    return copyWith(chords: newChords);
  }

  /// Gets the chord at a specific position
  String getChord(int position) {
    if (position < 0 || position >= chords.length) return '';
    return chords[position];
  }

  /// Clears all chords in the measure
  Measure clearChords() {
    final newChords = List<String>.filled(chords.length, '');
    return copyWith(chords: newChords);
  }

  /// Checks if this measure has any special features
  bool get hasSpecialFeatures {
    return specialSymbol != null || hasFirstEnding || hasSecondEnding;
  }

  /// Gets the display text for the measure
  String get displayText {
    if (specialSymbol != null) return specialSymbol!;

    final chordText = chords.where((chord) => chord.isNotEmpty).join(' ');
    return chordText.isEmpty ? '|' : chordText;
  }

  /// Gets the measure number (1-based)
  int get measureNumber {
    return measureOrder + 1;
  }

  /// Checks if this measure is the first in a section
  bool get isFirstInSection {
    return measureOrder == 0;
  }

  /// Checks if this measure is the last in a section
  bool get isLastInSection {
    // This would need to be determined by the parent section
    return false;
  }

  @override
  String toString() {
    return 'Measure(id: $id, sectionId: $sectionId, order: $measureOrder, timeSignature: $timeSignature, chords: $chords)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Measure &&
        other.id == id &&
        other.sectionId == sectionId &&
        other.measureOrder == measureOrder &&
        other.timeSignature == timeSignature &&
        other.chords == chords &&
        other.specialSymbol == specialSymbol &&
        other.hasFirstEnding == hasFirstEnding &&
        other.hasSecondEnding == hasSecondEnding;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      sectionId,
      measureOrder,
      timeSignature,
      chords,
      specialSymbol,
      hasFirstEnding,
      hasSecondEnding,
    );
  }
}
