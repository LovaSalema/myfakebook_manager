/// Represents the many-to-many relationship between repertoires and songs
class RepertoireSong {
  final int? id;
  final int repertoireId;
  final int songId;
  final int orderIndex;
  final String? notes;
  final DateTime addedAt;

  const RepertoireSong({
    this.id,
    required this.repertoireId,
    required this.songId,
    required this.orderIndex,
    this.notes,
    required this.addedAt,
  });

  /// Creates a new RepertoireSong with default values
  factory RepertoireSong.create({
    required int repertoireId,
    required int songId,
    required int orderIndex,
    String? notes,
  }) {
    return RepertoireSong(
      repertoireId: repertoireId,
      songId: songId,
      orderIndex: orderIndex,
      notes: notes,
      addedAt: DateTime.now(),
    );
  }

  /// Converts RepertoireSong to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'repertoire_id': repertoireId,
      'song_id': songId,
      'order_index': orderIndex,
      'notes': notes,
      'added_at': addedAt.millisecondsSinceEpoch,
    };
  }

  /// Creates RepertoireSong from Map (database result)
  factory RepertoireSong.fromMap(Map<String, dynamic> map) {
    return RepertoireSong(
      id: map['id'],
      repertoireId: map['repertoire_id'] ?? map['repertoireId'],
      songId: map['song_id'] ?? map['songId'],
      orderIndex: map['order_index'] ?? map['orderIndex'],
      notes: map['notes'],
      addedAt: DateTime.fromMillisecondsSinceEpoch(
        map['added_at'] ?? map['addedAt'],
      ),
    );
  }

  /// Creates a copy of the RepertoireSong with updated fields
  RepertoireSong copyWith({
    int? id,
    int? repertoireId,
    int? songId,
    int? orderIndex,
    String? notes,
    DateTime? addedAt,
  }) {
    return RepertoireSong(
      id: id ?? this.id,
      repertoireId: repertoireId ?? this.repertoireId,
      songId: songId ?? this.songId,
      orderIndex: orderIndex ?? this.orderIndex,
      notes: notes ?? this.notes,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  /// Validates repertoire song data
  bool validate() {
    if (repertoireId <= 0) return false;
    if (songId <= 0) return false;
    if (orderIndex < 0) return false;
    return true;
  }

  /// Gets the formatted added date
  String get formattedAddedAt {
    return '${addedAt.day}/${addedAt.month}/${addedAt.year}';
  }

  /// Checks if there are notes
  bool get hasNotes {
    return notes != null && notes!.isNotEmpty;
  }

  /// Gets the display order (1-based)
  int get displayOrder {
    return orderIndex + 1;
  }

  /// Updates the order index
  RepertoireSong withOrderIndex(int newOrderIndex) {
    return copyWith(orderIndex: newOrderIndex);
  }

  /// Updates the notes
  RepertoireSong withNotes(String? newNotes) {
    return copyWith(notes: newNotes);
  }

  @override
  String toString() {
    return 'RepertoireSong(id: $id, repertoireId: $repertoireId, songId: $songId, orderIndex: $orderIndex)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RepertoireSong &&
        other.id == id &&
        other.repertoireId == repertoireId &&
        other.songId == songId &&
        other.orderIndex == orderIndex &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(id, repertoireId, songId, orderIndex, notes);
  }
}
