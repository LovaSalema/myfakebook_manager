import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/song.dart';
import '../models/structure.dart';
import '../models/section.dart';
import '../models/measure.dart';
import '../models/repertoire.dart';
import '../models/repertoire_song.dart';
import '../models/export_settings.dart';
import '../../core/constants/app_constants.dart';
import 'database_helper.dart';

/// Custom database exception with clear error messages
class ExtractionDatabaseException implements Exception {
  final String message;
  final String operation;
  final dynamic error;

  ExtractionDatabaseException(this.message, {this.operation = '', this.error});

  @override
  String toString() {
    return 'ExtractionDatabaseException: $message${operation.isNotEmpty ? ' (Operation: $operation)' : ''}${error != null ? ' - $error' : ''}';
  }
}

/// Professional ExtractionDatabaseHelper singleton for extracted songs
class ExtractionDatabaseHelper implements BaseDatabaseHelper {
  static final ExtractionDatabaseHelper _instance =
      ExtractionDatabaseHelper._internal();
  static Database? _database;

  // Light memory cache
  Song? _lastAccessedSong;
  Repertoire? _lastAccessedRepertoire;

  ExtractionDatabaseHelper._internal();

  factory ExtractionDatabaseHelper() {
    return _instance;
  }

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database with migration support
  Future<Database> _initDatabase() async {
    try {
      final path = join(await getDatabasesPath(), 'myfakebook_extractions.db');
      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _createTables,
        onUpgrade: _migrateDatabase,
      );
    } catch (e) {
      throw ExtractionDatabaseException(
        'Failed to initialize extraction database',
        error: e,
      );
    }
  }

  /// Create all database tables with foreign keys and indexes
  Future<void> _createTables(Database db, int version) async {
    try {
      await db.execute('PRAGMA foreign_keys = ON');

      // Songs table
      await db.execute('''
        CREATE TABLE songs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          artist TEXT NOT NULL,
          key TEXT NOT NULL,
          time_signature TEXT NOT NULL,
          tempo INTEGER,
          style TEXT,
          notation_type TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          is_favorite INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Structures table
      await db.execute('''
        CREATE TABLE structures(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          song_id INTEGER NOT NULL,
          pattern TEXT NOT NULL,
          description TEXT,
          FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE,
          UNIQUE(song_id)
        )
      ''');

      // Sections table
      await db.execute('''
        CREATE TABLE sections(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          song_id INTEGER NOT NULL,
          section_type TEXT NOT NULL,
          section_label TEXT NOT NULL,
          section_name TEXT,
          section_order INTEGER NOT NULL,
          repeat_count INTEGER NOT NULL DEFAULT 1,
          has_repeat_sign INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
        )
      ''');

      // Measures table
      await db.execute('''
        CREATE TABLE measures(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          section_id INTEGER NOT NULL,
          measure_order INTEGER NOT NULL,
          time_signature TEXT NOT NULL,
          chords_json TEXT NOT NULL,
          special_symbol TEXT,
          has_first_ending INTEGER NOT NULL DEFAULT 0,
          has_second_ending INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE CASCADE
        )
      ''');

      // Repertoires table
      await db.execute('''
        CREATE TABLE repertoires(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          event_date INTEGER,
          cover_color TEXT NOT NULL,
          icon TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Repertoire songs junction table
      await db.execute('''
        CREATE TABLE repertoire_songs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          repertoire_id INTEGER NOT NULL,
          song_id INTEGER NOT NULL,
          order_index INTEGER NOT NULL,
          notes TEXT,
          added_at INTEGER NOT NULL,
          FOREIGN KEY (repertoire_id) REFERENCES repertoires(id) ON DELETE CASCADE,
          FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE,
          UNIQUE(repertoire_id, song_id)
        )
      ''');

      // Create indexes for better performance
      await _createIndexes(db);
    } catch (e) {
      throw ExtractionDatabaseException(
        'Failed to create extraction database tables',
        error: e,
      );
    }
  }

  /// Create database indexes
  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_extraction_songs_title ON songs(title)');
    await db.execute(
      'CREATE INDEX idx_extraction_songs_artist ON songs(artist)',
    );
    await db.execute('CREATE INDEX idx_extraction_songs_key ON songs(key)');
    await db.execute(
      'CREATE INDEX idx_extraction_songs_favorite ON songs(is_favorite)',
    );
    await db.execute(
      'CREATE INDEX idx_extraction_songs_created ON songs(created_at)',
    );
    await db.execute(
      'CREATE INDEX idx_extraction_repertoires_name ON repertoires(name)',
    );
    await db.execute(
      'CREATE INDEX idx_extraction_repertoires_event ON repertoires(event_date)',
    );
    await db.execute(
      'CREATE INDEX idx_extraction_sections_song ON sections(song_id)',
    );
    await db.execute(
      'CREATE INDEX idx_extraction_measures_section ON measures(section_id)',
    );
    await db.execute(
      'CREATE INDEX idx_extraction_repertoire_songs_order ON repertoire_songs(order_index)',
    );
  }

  /// Database migration logic
  Future<void> _migrateDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    try {
      for (int version = oldVersion + 1; version <= newVersion; version++) {
        switch (version) {
          case 2:
            // Future migration logic
            break;
          // Add more migration cases as needed
        }
      }
    } catch (e) {
      throw ExtractionDatabaseException(
        'Extraction database migration failed',
        error: e,
      );
    }
  }

  // ===========================================================================
  // SONG REPOSITORY
  // ===========================================================================

  /// Insert a complete song with all sections and measures in a single transaction
  Future<int> insertSong(Song song) async {
    final db = await database;

    try {
      return await db.transaction((txn) async {
        // Insert song
        final songId = await txn.insert('songs', song.toMap());

        // Insert structure if exists
        if (song.structure != null) {
          final structure = song.structure!.copyWith(songId: songId);
          await txn.insert('structures', structure.toMap());
        }

        // Insert sections and measures
        for (final section in song.sections) {
          final sectionWithSongId = section.copyWith(songId: songId);
          final sectionId = await txn.insert(
            'sections',
            sectionWithSongId.toMap(),
          );

          // Insert measures for this section
          for (final measure in section.measures) {
            final measureWithSectionId = measure.copyWith(sectionId: sectionId);
            final measureMap = measureWithSectionId.toMap();
            await txn.insert('measures', measureMap);
          }
        }

        return songId;
      });
    } catch (e) {
      throw ExtractionDatabaseException(
        'Failed to insert song in extraction database',
        operation: 'insertSong',
        error: e,
      );
    }
  }

  /// Get complete song by ID with all related data
  Future<Song?> getSongById(int id) async {
    if (_lastAccessedSong?.id == id) return _lastAccessedSong;

    final db = await database;

    try {
      final songMaps = await db.query(
        'songs',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (songMaps.isEmpty) return null;

      final songMap = songMaps.first;
      final song = Song.fromMap(songMap);

      // Load structure
      final structureMaps = await db.query(
        'structures',
        where: 'song_id = ?',
        whereArgs: [id],
      );
      Structure? structure;
      if (structureMaps.isNotEmpty) {
        structure = Structure.fromMap(structureMaps.first);
      }

      // Load sections with measures
      final sections = await _getSectionsForSong(id);

      // Create song with structure and sections
      final completeSong = song.copyWith(
        structure: structure,
        sections: sections,
      );

      _lastAccessedSong = completeSong;
      return completeSong;
    } catch (e) {
      throw ExtractionDatabaseException(
        'Failed to get song by ID from extraction database',
        operation: 'getSongById',
        error: e,
      );
    }
  }

  /// Get all songs with optional filtering and ordering
  Future<List<Song>> getAllSongs({String? orderBy, bool? favoritesOnly}) async {
    final db = await database;

    try {
      var whereClause = '';
      var whereArgs = <dynamic>[];

      if (favoritesOnly == true) {
        whereClause = 'is_favorite = ?';
        whereArgs.add(1);
      }

      final orderByClause = _getOrderByClause(orderBy, 'songs');
      final maps = await db.query(
        'songs',
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: orderByClause,
      );

      // Load complete song data with sections and measures
      final songs = <Song>[];
      for (final map in maps) {
        final song = Song.fromMap(map);
        final songId = song.id!;

        // Load structure
        final structureMaps = await db.query(
          'structures',
          where: 'song_id = ?',
          whereArgs: [songId],
        );
        Structure? structure;
        if (structureMaps.isNotEmpty) {
          structure = Structure.fromMap(structureMaps.first);
        }

        // Load sections with measures
        final sections = await _getSectionsForSong(songId);

        // Create complete song
        final completeSong = song.copyWith(
          structure: structure,
          sections: sections,
        );
        songs.add(completeSong);
      }

      return songs;
    } catch (e) {
      throw ExtractionDatabaseException(
        'Failed to get all songs from extraction database',
        operation: 'getAllSongs',
        error: e,
      );
    }
  }

  /// Update complete song with all related data in transaction
  Future<int> updateSong(Song song) async {
    final db = await database;

    try {
      return await db.transaction((txn) async {
        // Update song
        final result = await txn.update(
          'songs',
          song.toMap(),
          where: 'id = ?',
          whereArgs: [song.id],
        );

        // Update structure
        if (song.structure != null) {
          await txn.delete(
            'structures',
            where: 'song_id = ?',
            whereArgs: [song.id],
          );
          await txn.insert('structures', song.structure!.toMap());
        }

        // Delete existing sections and measures
        await txn.delete(
          'sections',
          where: 'song_id = ?',
          whereArgs: [song.id],
        );

        // Insert updated sections and measures with correct song ID
        for (final section in song.sections) {
          // Ensure section has the correct song ID
          final sectionWithCorrectSongId = section.copyWith(songId: song.id!);
          final sectionId = await txn.insert(
            'sections',
            sectionWithCorrectSongId.toMap(),
          );

          for (final measure in section.measures) {
            final measureMap = measure.copyWith(sectionId: sectionId).toMap();
            await txn.insert('measures', measureMap);
          }
        }

        _lastAccessedSong = null;
        return result;
      });
    } catch (e) {
      throw ExtractionDatabaseException(
        'Failed to update song in extraction database',
        operation: 'updateSong',
        error: e,
      );
    }
  }

  /// Delete song with cascade deletion
  Future<int> deleteSong(int id) async {
    final db = await database;

    try {
      final result = await db.delete('songs', where: 'id = ?', whereArgs: [id]);
      _lastAccessedSong = null;
      return result;
    } catch (e) {
      throw ExtractionDatabaseException(
        'Failed to delete song from extraction database',
        operation: 'deleteSong',
        error: e,
      );
    }
  }

  /// Search songs by title, artist, or style
  Future<List<Song>> searchSongs(String query) async {
    final db = await database;

    try {
      final maps = await db.query(
        'songs',
        where: 'title LIKE ? OR artist LIKE ? OR style LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'title ASC',
      );

      // Load complete song data with sections and measures
      final songs = <Song>[];
      for (final map in maps) {
        final song = Song.fromMap(map);
        final songId = song.id!;

        // Load structure
        final structureMaps = await db.query(
          'structures',
          where: 'song_id = ?',
          whereArgs: [songId],
        );
        Structure? structure;
        if (structureMaps.isNotEmpty) {
          structure = Structure.fromMap(structureMaps.first);
        }

        // Load sections with measures
        final sections = await _getSectionsForSong(songId);

        // Create complete song
        final completeSong = song.copyWith(
          structure: structure,
          sections: sections,
        );
        songs.add(completeSong);
      }

      return songs;
    } catch (e) {
      throw ExtractionDatabaseException(
        'Failed to search songs in extraction database',
        operation: 'searchSongs',
        error: e,
      );
    }
  }

  /// Get songs by musical key
  Future<List<Song>> getSongsByKey(String key) async {
    final db = await database;

    try {
      final maps = await db.query(
        'songs',
        where: 'key = ?',
        whereArgs: [key],
        orderBy: 'title ASC',
      );

      // Load complete song data with sections and measures
      final songs = <Song>[];
      for (final map in maps) {
        final song = Song.fromMap(map);
        final songId = song.id!;

        // Load structure
        final structureMaps = await db.query(
          'structures',
          where: 'song_id = ?',
          whereArgs: [songId],
        );
        Structure? structure;
        if (structureMaps.isNotEmpty) {
          structure = Structure.fromMap(structureMaps.first);
        }

        // Load sections with measures
        final sections = await _getSectionsForSong(songId);

        // Create complete song
        final completeSong = song.copyWith(
          structure: structure,
          sections: sections,
        );
        songs.add(completeSong);
      }

      return songs;
    } catch (e) {
      throw ExtractionDatabaseException(
        'Failed to get songs by key from extraction database',
        operation: 'getSongsByKey',
        error: e,
      );
    }
  }

  /// Get recently created songs
  Future<List<Song>> getRecentSongs(int limit) async {
    final db = await database;

    try {
      final maps = await db.query(
        'songs',
        orderBy: 'created_at DESC',
        limit: limit,
      );

      // Load complete song data with sections and measures
      final songs = <Song>[];
      for (final map in maps) {
        final song = Song.fromMap(map);
        final songId = song.id!;

        // Load structure
        final structureMaps = await db.query(
          'structures',
          where: 'song_id = ?',
          whereArgs: [songId],
        );
        Structure? structure;
        if (structureMaps.isNotEmpty) {
          structure = Structure.fromMap(structureMaps.first);
        }

        // Load sections with measures
        final sections = await _getSectionsForSong(songId);

        // Create complete song
        final completeSong = song.copyWith(
          structure: structure,
          sections: sections,
        );
        songs.add(completeSong);
      }

      return songs;
    } catch (e) {
      throw ExtractionDatabaseException(
        'Failed to get recent songs from extraction database',
        operation: 'getRecentSongs',
        error: e,
      );
    }
  }

  /// Toggle song favorite status
  Future<int> toggleFavorite(int id) async {
    final db = await database;

    try {
      // Get current favorite status
      final current = await db.query(
        'songs',
        columns: ['is_favorite'],
        where: 'id = ?',
        whereArgs: [id],
      );

      if (current.isEmpty)
        throw ExtractionDatabaseException(
          'Song not found in extraction database',
        );

      final newStatus = current.first['is_favorite'] == 1 ? 0 : 1;

      return await db.update(
        'songs',
        {
          'is_favorite': newStatus,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw ExtractionDatabaseException(
        'Failed to toggle favorite in extraction database',
        operation: 'toggleFavorite',
        error: e,
      );
    }
  }

  /// Transpose song to new key and save
  Future<int> transposeSong(int songId, String newKey) async {
    final db = await database;

    try {
      return await db.update(
        'songs',
        {'key': newKey, 'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [songId],
      );
    } catch (e) {
      throw ExtractionDatabaseException(
        'Failed to transpose song in extraction database',
        operation: 'transposeSong',
        error: e,
      );
    }
  }

  /// Check if a song with the same title and artist already exists (not applicable for extraction DB)
  Future<Song?> findSongByTitleAndArtist(String title, String artist) async {
    // Extraction database doesn't need duplicate checking
    return null;
  }

  /// Clean up duplicate songs (not applicable for extraction DB - always returns 0)
  Future<int> cleanupDuplicateSongs() async {
    // Extraction database doesn't need cleanup
    return 0;
  }

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================

  /// Get sections with measures for a song
  Future<List<Section>> _getSectionsForSong(int songId) async {
    final db = await database;

    try {
      final sectionMaps = await db.query(
        'sections',
        where: 'song_id = ?',
        whereArgs: [songId],
        orderBy: 'section_order ASC',
      );

      final sections = <Section>[];

      for (final sectionMap in sectionMaps) {
        final section = Section.fromMap(sectionMap);

        // Load measures for this section
        final measureMaps = await db.query(
          'measures',
          where: 'section_id = ?',
          whereArgs: [section.id],
          orderBy: 'measure_order ASC',
        );

        final measures = measureMaps.map((measureMap) {
          // Parse chords from JSON
          final chordsJson = measureMap['chords_json'] as String? ?? '[]';
          final chords = (jsonDecode(chordsJson) as List).cast<String>();

          return Measure(
            id: measureMap['id'] as int?,
            sectionId: measureMap['section_id'] as int,
            measureOrder: measureMap['measure_order'] as int,
            timeSignature: measureMap['time_signature'] as String,
            chords: chords,
            specialSymbol: measureMap['special_symbol'] as String?,
            hasFirstEnding: (measureMap['has_first_ending'] as int?) == 1,
            hasSecondEnding: (measureMap['has_second_ending'] as int?) == 1,
          );
        }).toList();

        sections.add(section.copyWith(measures: measures));
      }

      return sections;
    } catch (e) {
      throw ExtractionDatabaseException(
        'Failed to get sections for song from extraction database',
        operation: '_getSectionsForSong',
        error: e,
      );
    }
  }

  /// Get order by clause for queries
  String _getOrderByClause(String? orderBy, String table) {
    switch (orderBy) {
      case 'title':
        return '$table.title ASC';
      case 'artist':
        return '$table.artist ASC';
      case 'created':
        return '$table.created_at DESC';
      case 'updated':
        return '$table.updated_at DESC';
      case 'name':
        return '$table.name ASC';
      case 'event_date':
        return '$table.event_date ASC';
      default:
        // Use appropriate default for each table
        if (table == 'repertoires') {
          return '$table.name ASC';
        } else {
          return '$table.title ASC';
        }
    }
  }

  // ===========================================================================
  // DATABASE MAINTENANCE
  // ===========================================================================

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    _lastAccessedSong = null;
    _lastAccessedRepertoire = null;
  }

  /// Delete database (for testing/reset)
  Future<void> deleteDatabase() async {
    final path = join(await getDatabasesPath(), 'myfakebook_extractions.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
    _lastAccessedSong = null;
    _lastAccessedRepertoire = null;
  }
}
