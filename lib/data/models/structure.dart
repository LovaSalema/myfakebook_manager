/// Represents the overall structure pattern of a song
class Structure {
  final int? id;
  final int songId;
  final String pattern;
  final String? description;

  const Structure({
    this.id,
    required this.songId,
    required this.pattern,
    this.description,
  });

  /// Creates a new Structure with validation
  factory Structure.create({
    required int songId,
    required String pattern,
    String? description,
  }) {
    if (!_isValidPattern(pattern)) {
      throw ArgumentError('Invalid structure pattern: $pattern');
    }

    return Structure(
      songId: songId,
      pattern: pattern,
      description: description,
    );
  }

  /// Converts Structure to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'song_id': songId,
      'pattern': pattern,
      'description': description,
    };
  }

  /// Creates Structure from Map (database result)
  factory Structure.fromMap(Map<String, dynamic> map) {
    return Structure(
      id: map['id'],
      songId: map['song_id'] ?? map['songId'], // Handle both column names
      pattern: map['pattern'],
      description: map['description'],
    );
  }

  /// Creates a copy of the Structure with updated fields
  Structure copyWith({
    int? id,
    int? songId,
    String? pattern,
    String? description,
  }) {
    return Structure(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      pattern: pattern ?? this.pattern,
      description: description ?? this.description,
    );
  }

  /// Validates the structure pattern
  static bool _isValidPattern(String pattern) {
    if (pattern.isEmpty) return false;

    // Common patterns: AABA, ABAB, AABC, ABAC, etc.
    final validPatterns = [
      'A',
      'AA',
      'AAA',
      'AAB',
      'AABA',
      'AABB',
      'AABC',
      'AB',
      'ABA',
      'ABAB',
      'ABAC',
      'ABBA',
      'ABBC',
      'ABCB',
      'ABC',
      'ABCD',
      'ABACABA',
      'AABACA',
      'AABABA',
    ];

    // Check if pattern contains only valid characters (A-Z)
    final regex = RegExp(r'^[A-Z]+$');
    if (!regex.hasMatch(pattern)) return false;

    // For now, accept any pattern with valid characters
    // In a real app, you might want more sophisticated validation
    return true;
  }

  /// Gets the description of the pattern
  String get patternDescription {
    if (description != null && description!.isNotEmpty) {
      return description!;
    }

    // Generate description from pattern
    final parts = pattern.split('');
    final uniqueParts = parts.toSet().toList()..sort();

    final descriptions = {
      'A': 'Verse',
      'B': 'Chorus',
      'C': 'Bridge',
      'D': 'Solo',
      'E': 'Intro',
      'F': 'Outro',
      'G': 'Interlude',
    };

    final descriptionParts = <String>[];
    for (final part in parts) {
      final desc = descriptions[part] ?? part;
      descriptionParts.add(desc);
    }

    return descriptionParts.join(' - ');
  }

  /// Gets the number of sections in the pattern
  int get sectionCount {
    return pattern.length;
  }

  /// Gets unique section labels used in the pattern
  Set<String> get uniqueSectionLabels {
    return pattern.split('').toSet();
  }

  /// Validates if a list of sections matches this structure
  bool validateSections(List<String> sectionLabels) {
    if (sectionLabels.length != pattern.length) return false;

    // Check if section labels match the pattern
    for (int i = 0; i < pattern.length; i++) {
      final expected = pattern[i];
      final actual = sectionLabels[i];

      // For now, allow any label that matches the pattern character
      // In a real app, you might want more specific validation
      if (actual != expected) return false;
    }

    return true;
  }

  /// Gets the next section label for a given position
  String getNextSectionLabel(int currentPosition) {
    if (currentPosition >= pattern.length - 1) {
      return pattern[0]; // Loop back to start
    }
    return pattern[currentPosition + 1];
  }

  /// Gets the previous section label for a given position
  String getPreviousSectionLabel(int currentPosition) {
    if (currentPosition <= 0) {
      return pattern[pattern.length - 1]; // Loop to end
    }
    return pattern[currentPosition - 1];
  }

  /// Checks if this is a common structure pattern
  bool get isCommonPattern {
    final commonPatterns = ['AABA', 'ABAB', 'ABAC', 'AABC', 'ABCB'];
    return commonPatterns.contains(pattern);
  }

  /// Gets the repetition count for each section type
  Map<String, int> get repetitionCounts {
    final counts = <String, int>{};
    for (final char in pattern.split('')) {
      counts[char] = (counts[char] ?? 0) + 1;
    }
    return counts;
  }

  @override
  String toString() {
    return 'Structure(id: $id, songId: $songId, pattern: $pattern, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Structure &&
        other.id == id &&
        other.songId == songId &&
        other.pattern == pattern &&
        other.description == description;
  }

  @override
  int get hashCode {
    return Object.hash(id, songId, pattern, description);
  }
}
