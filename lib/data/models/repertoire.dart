import 'package:flutter/material.dart';

/// Represents a collection of songs for a specific event or purpose
class Repertoire {
  final int? id;
  final String name;
  final String? description;
  final DateTime? eventDate;
  final String coverColor;
  final String icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Repertoire({
    this.id,
    required this.name,
    this.description,
    this.eventDate,
    required this.coverColor,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a new Repertoire with default values
  factory Repertoire.create({
    required String name,
    String? description,
    DateTime? eventDate,
    String coverColor = '#3B82F6',
    String icon = 'music_note',
  }) {
    final now = DateTime.now();
    return Repertoire(
      name: name,
      description: description,
      eventDate: eventDate,
      coverColor: coverColor,
      icon: icon,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Converts Repertoire to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'event_date': eventDate?.millisecondsSinceEpoch,
      'cover_color': coverColor,
      'icon': icon,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Creates Repertoire from Map (database result)
  factory Repertoire.fromMap(Map<String, dynamic> map) {
    return Repertoire(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      eventDate: map['event_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['event_date'])
          : null,
      coverColor: map['cover_color'] ?? map['coverColor'],
      icon: map['icon'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] ?? map['createdAt'],
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updated_at'] ?? map['updatedAt'],
      ),
    );
  }

  /// Creates a copy of the Repertoire with updated fields
  Repertoire copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? eventDate,
    String? coverColor,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Repertoire(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      coverColor: coverColor ?? this.coverColor,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validates repertoire data
  bool validate() {
    if (name.isEmpty) return false;
    if (!_isValidColor(coverColor)) return false;
    if (!_isValidIcon(icon)) return false;
    return true;
  }

  /// Checks if color is valid
  bool _isValidColor(String color) {
    final regex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    return regex.hasMatch(color);
  }

  /// Checks if icon is valid
  bool _isValidIcon(String icon) {
    final validIcons = [
      'music_note',
      'event',
      'star',
      'favorite',
      'playlist',
      'album',
      'mic',
      'guitar',
      'piano',
      'drums',
      'violin',
      'trumpet',
      'saxophone',
    ];
    return validIcons.contains(icon);
  }

  /// Gets the display name for the event date
  String get eventDateDisplay {
    if (eventDate == null) return 'No date set';

    final now = DateTime.now();
    final difference = eventDate!.difference(now);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Tomorrow';
    if (difference.inDays == -1) return 'Yesterday';
    if (difference.inDays > 0 && difference.inDays <= 7)
      return 'In ${difference.inDays} days';
    if (difference.inDays < 0 && difference.inDays >= -7)
      return '${difference.inDays.abs()} days ago';

    return '${eventDate!.day}/${eventDate!.month}/${eventDate!.year}';
  }

  /// Checks if the event is upcoming
  bool get isUpcoming {
    if (eventDate == null) return false;
    return eventDate!.isAfter(DateTime.now());
  }

  /// Checks if the event is today
  bool get isToday {
    if (eventDate == null) return false;
    final now = DateTime.now();
    return eventDate!.year == now.year &&
        eventDate!.month == now.month &&
        eventDate!.day == now.day;
  }

  /// Gets the color as a Color object
  Color get color {
    return Color(int.parse(coverColor.replaceFirst('#', '0xFF')));
  }

  /// Gets the days until the event
  int? get daysUntilEvent {
    if (eventDate == null) return null;
    final now = DateTime.now();
    return eventDate!.difference(now).inDays;
  }

  /// Gets the formatted event date
  String get formattedEventDate {
    if (eventDate == null) return '';
    return '${eventDate!.day}/${eventDate!.month}/${eventDate!.year}';
  }

  /// Gets the formatted creation date
  String get formattedCreatedAt {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Gets the formatted update date
  String get formattedUpdatedAt {
    return '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';
  }

  /// Checks if the repertoire has a description
  bool get hasDescription {
    return description != null && description!.isNotEmpty;
  }

  /// Gets the first letter of the name for avatars
  String get nameInitial {
    if (name.isEmpty) return 'R';
    return name[0].toUpperCase();
  }

  @override
  String toString() {
    return 'Repertoire(id: $id, name: $name, eventDate: $eventDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Repertoire &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.eventDate == eventDate &&
        other.coverColor == coverColor &&
        other.icon == icon;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, description, eventDate, coverColor, icon);
  }
}
