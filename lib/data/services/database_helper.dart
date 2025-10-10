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

/// Custom database exception with clear error messages
class DatabaseException implements Exception {
  final String message;
  final String operation;
  final dynamic error;

  DatabaseException(this.message, {this.operation = '', this.error});

  @override
  String toString() {
    return 'DatabaseException: $message${operation.isNotEmpty ? ' (Operation: $operation)' : ''}${error != null ? ' - $error' : ''}';
  }
}

/// Professional DatabaseHelper singleton with repository pattern
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Light memory cache
  Song? _lastAccessedSong;
  Repertoire? _lastAccessedRepertoire;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
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
      final path = join(await getDatabasesPath(), AppConstants.databaseName);
      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _createTables,
        onUpgrade: _migrateDatabase,
      );
    } catch (e) {
      throw DatabaseException('Failed to initialize database', error: e);
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

      // Seed database with example data
      await _seedDatabase(db);
    } catch (e) {
      throw DatabaseException('Failed to create database tables', error: e);
    }
  }

  /// Create database indexes
  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_songs_title ON songs(title)');
    await db.execute('CREATE INDEX idx_songs_artist ON songs(artist)');
    await db.execute('CREATE INDEX idx_songs_key ON songs(key)');
    await db.execute('CREATE INDEX idx_songs_favorite ON songs(is_favorite)');
    await db.execute('CREATE INDEX idx_songs_created ON songs(created_at)');
    await db.execute('CREATE INDEX idx_repertoires_name ON repertoires(name)');
    await db.execute(
      'CREATE INDEX idx_repertoires_event ON repertoires(event_date)',
    );
    await db.execute('CREATE INDEX idx_sections_song ON sections(song_id)');
    await db.execute(
      'CREATE INDEX idx_measures_section ON measures(section_id)',
    );
    await db.execute(
      'CREATE INDEX idx_repertoire_songs_order ON repertoire_songs(order_index)',
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
      throw DatabaseException('Database migration failed', error: e);
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
      throw DatabaseException(
        'Failed to insert song',
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
      throw DatabaseException(
        'Failed to get song by ID',
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
      throw DatabaseException(
        'Failed to get all songs',
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

        // Insert updated sections and measures
        for (final section in song.sections) {
          final sectionId = await txn.insert('sections', section.toMap());

          for (final measure in section.measures) {
            final measureMap = measure.copyWith(sectionId: sectionId).toMap();
            await txn.insert('measures', measureMap);
          }
        }

        _lastAccessedSong = null;
        return result;
      });
    } catch (e) {
      throw DatabaseException(
        'Failed to update song',
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
      throw DatabaseException(
        'Failed to delete song',
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
      throw DatabaseException(
        'Failed to search songs',
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
      throw DatabaseException(
        'Failed to get songs by key',
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
      throw DatabaseException(
        'Failed to get recent songs',
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

      if (current.isEmpty) throw DatabaseException('Song not found');

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
      throw DatabaseException(
        'Failed to toggle favorite',
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
      throw DatabaseException(
        'Failed to transpose song',
        operation: 'transposeSong',
        error: e,
      );
    }
  }

  // ===========================================================================
  // REPERTOIRE REPOSITORY
  // ===========================================================================

  /// Insert repertoire
  Future<int> insertRepertoire(Repertoire repertoire) async {
    final db = await database;

    try {
      final id = await db.insert('repertoires', repertoire.toMap());
      _lastAccessedRepertoire = repertoire.copyWith(id: id);
      return id;
    } catch (e) {
      throw DatabaseException(
        'Failed to insert repertoire',
        operation: 'insertRepertoire',
        error: e,
      );
    }
  }

  /// Get repertoire by ID with ordered songs
  Future<Repertoire?> getRepertoireById(int id) async {
    if (_lastAccessedRepertoire?.id == id) return _lastAccessedRepertoire;

    final db = await database;

    try {
      final maps = await db.query(
        'repertoires',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;

      final repertoire = Repertoire.fromMap(maps.first);
      _lastAccessedRepertoire = repertoire;
      return repertoire;
    } catch (e) {
      throw DatabaseException(
        'Failed to get repertoire by ID',
        operation: 'getRepertoireById',
        error: e,
      );
    }
  }

  /// Get all repertoires with optional ordering
  Future<List<Repertoire>> getAllRepertoires({String? orderBy}) async {
    final db = await database;

    try {
      final orderByClause = _getOrderByClause(orderBy, 'repertoires');
      final maps = await db.query('repertoires', orderBy: orderByClause);
      return maps.map((map) => Repertoire.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException(
        'Failed to get all repertoires',
        operation: 'getAllRepertoires',
        error: e,
      );
    }
  }

  /// Update repertoire
  Future<int> updateRepertoire(Repertoire repertoire) async {
    final db = await database;

    try {
      final result = await db.update(
        'repertoires',
        repertoire.toMap(),
        where: 'id = ?',
        whereArgs: [repertoire.id],
      );

      _lastAccessedRepertoire = null;
      return result;
    } catch (e) {
      throw DatabaseException(
        'Failed to update repertoire',
        operation: 'updateRepertoire',
        error: e,
      );
    }
  }

  /// Delete repertoire with cascade deletion
  Future<int> deleteRepertoire(int id) async {
    final db = await database;

    try {
      final result = await db.delete(
        'repertoires',
        where: 'id = ?',
        whereArgs: [id],
      );
      _lastAccessedRepertoire = null;
      return result;
    } catch (e) {
      throw DatabaseException(
        'Failed to delete repertoire',
        operation: 'deleteRepertoire',
        error: e,
      );
    }
  }

  /// Add multiple songs to repertoire
  Future<void> addSongsToRepertoire(int repertoireId, List<int> songIds) async {
    final db = await database;

    try {
      await db.transaction((txn) async {
        // Get current max order index
        final currentMax = await txn.rawQuery(
          'SELECT MAX(order_index) as max_order FROM repertoire_songs WHERE repertoire_id = ?',
          [repertoireId],
        );

        // Handle case when no songs exist in repertoire (max_order will be null)
        final maxOrder = currentMax.first['max_order'];
        int nextOrder = (maxOrder != null ? maxOrder as int : -1) + 1;

        // Insert each song
        for (int i = 0; i < songIds.length; i++) {
          final repertoireSong = RepertoireSong.create(
            repertoireId: repertoireId,
            songId: songIds[i],
            orderIndex: nextOrder + i,
          );
          await txn.insert('repertoire_songs', repertoireSong.toMap());
        }
      });
    } catch (e) {
      throw DatabaseException(
        'Failed to add songs to repertoire',
        operation: 'addSongsToRepertoire',
        error: e,
      );
    }
  }

  /// Remove song from repertoire
  Future<int> removeSongFromRepertoire(int repertoireId, int songId) async {
    final db = await database;

    try {
      return await db.delete(
        'repertoire_songs',
        where: 'repertoire_id = ? AND song_id = ?',
        whereArgs: [repertoireId, songId],
      );
    } catch (e) {
      throw DatabaseException(
        'Failed to remove song from repertoire',
        operation: 'removeSongFromRepertoire',
        error: e,
      );
    }
  }

  /// Reorder songs in repertoire
  Future<void> reorderSongsInRepertoire(
    int repertoireId,
    List<int> orderedSongIds,
  ) async {
    final db = await database;

    try {
      await db.transaction((txn) async {
        // Delete all current songs
        await txn.delete(
          'repertoire_songs',
          where: 'repertoire_id = ?',
          whereArgs: [repertoireId],
        );

        // Insert in new order
        for (int i = 0; i < orderedSongIds.length; i++) {
          final repertoireSong = RepertoireSong.create(
            repertoireId: repertoireId,
            songId: orderedSongIds[i],
            orderIndex: i,
          );
          await txn.insert('repertoire_songs', repertoireSong.toMap());
        }
      });
    } catch (e) {
      throw DatabaseException(
        'Failed to reorder songs in repertoire',
        operation: 'reorderSongsInRepertoire',
        error: e,
      );
    }
  }

  /// Get songs in repertoire with ordering
  Future<List<Song>> getSongsInRepertoire(
    int repertoireId, {
    String? orderBy,
  }) async {
    final db = await database;

    try {
      final orderByClause = orderBy == 'title'
          ? 's.title ASC'
          : 'rs.order_index ASC';

      final maps = await db.rawQuery(
        '''
        SELECT s.* FROM songs s
        INNER JOIN repertoire_songs rs ON s.id = rs.song_id
        WHERE rs.repertoire_id = ?
        ORDER BY $orderByClause
      ''',
        [repertoireId],
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
      throw DatabaseException(
        'Failed to get songs in repertoire',
        operation: 'getSongsInRepertoire',
        error: e,
      );
    }
  }

  /// Get repertoires containing a specific song
  Future<List<Repertoire>> getRepertoiresBySongId(int songId) async {
    final db = await database;

    try {
      final maps = await db.rawQuery(
        '''
        SELECT r.* FROM repertoires r
        INNER JOIN repertoire_songs rs ON r.id = rs.repertoire_id
        WHERE rs.song_id = ?
        ORDER BY r.name ASC
      ''',
        [songId],
      );

      return maps.map((map) => Repertoire.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException(
        'Failed to get repertoires by song ID',
        operation: 'getRepertoiresBySongId',
        error: e,
      );
    }
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
      throw DatabaseException(
        'Failed to get sections for song',
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

  /// Seed database with example data
  Future<void> _seedDatabase(Database db) async {
    try {
      // Example song 1: Autumn Leaves
      final autumnLeaves = Song.create(
        title: 'Autumn Leaves',
        artist: 'Joseph Kosma',
        key: 'Cm',
        timeSignature: '4/4',
        tempo: 120,
        style: 'Jazz Standard',
      );

      final songId1 = await db.insert('songs', autumnLeaves.toMap());

      // Add structure
      await db.insert(
        'structures',
        Structure.create(
          songId: songId1,
          pattern: 'AABA',
          description: 'Classic AABA form',
        ).toMap(),
      );

      // Add sections and measures
      final sections1 = [
        Section.create(
          songId: songId1,
          sectionType: 'VERSE',
          sectionLabel: 'A',
          sectionOrder: 0,
          measureCount: 8,
        ),
        Section.create(
          songId: songId1,
          sectionType: 'VERSE',
          sectionLabel: 'A',
          sectionOrder: 1,
          measureCount: 8,
        ),
        Section.create(
          songId: songId1,
          sectionType: 'BRIDGE',
          sectionLabel: 'B',
          sectionOrder: 2,
          measureCount: 8,
        ),
        Section.create(
          songId: songId1,
          sectionType: 'VERSE',
          sectionLabel: 'A',
          sectionOrder: 3,
          measureCount: 8,
        ),
      ];

      for (final section in sections1) {
        final sectionId = await db.insert('sections', section.toMap());

        // Add example measures with chords
        for (int i = 0; i < section.measures.length; i++) {
          final measure = section.measures[i];
          final measureMap = measure.copyWith(sectionId: sectionId).toMap();
          measureMap['chords_json'] = jsonEncode([
            'Cm7',
            'F7',
            'BbMaj7',
            'EbMaj7',
          ]);
          await db.insert('measures', measureMap);
        }
      }

      // Example song 2: Blue Bossa
      final blueBossa = Song.create(
        title: 'Blue Bossa',
        artist: 'Kenny Dorham',
        key: 'Cm',
        timeSignature: '4/4',
        tempo: 132,
        style: 'Bossa Nova',
      );

      final songId2 = await db.insert('songs', blueBossa.toMap());

      // Add structure
      await db.insert(
        'structures',
        Structure.create(
          songId: songId2,
          pattern: 'AB',
          description: 'Simple AB form',
        ).toMap(),
      );

      // Add sections
      final sections2 = [
        Section.create(
          songId: songId2,
          sectionType: 'VERSE',
          sectionLabel: 'A',
          sectionOrder: 0,
          measureCount: 8,
        ),
        Section.create(
          songId: songId2,
          sectionType: 'BRIDGE',
          sectionLabel: 'B',
          sectionOrder: 1,
          measureCount: 8,
        ),
      ];

      for (final section in sections2) {
        final sectionId = await db.insert('sections', section.toMap());

        for (int i = 0; i < section.measures.length; i++) {
          final measure = section.measures[i];
          final measureMap = measure.copyWith(sectionId: sectionId).toMap();
          measureMap['chords_json'] = jsonEncode(['Cm7', 'Fm7', 'Dm7b5', 'G7']);
          await db.insert('measures', measureMap);
        }
      }

      // Example repertoire
      final jazzStandards = Repertoire.create(
        name: 'Jazz Standards',
        description: 'Essential jazz repertoire for gigs',
        eventDate: DateTime.now().add(Duration(days: 30)),
        coverColor: '#3B82F6',
        icon: 'music_note',
      );

      final repertoireId = await db.insert(
        'repertoires',
        jazzStandards.toMap(),
      );

      // Add songs to repertoire
      await db.insert(
        'repertoire_songs',
        RepertoireSong.create(
          repertoireId: repertoireId,
          songId: songId1,
          orderIndex: 0,
          notes: 'Great for opening sets',
        ).toMap(),
      );

      await db.insert(
        'repertoire_songs',
        RepertoireSong.create(
          repertoireId: repertoireId,
          songId: songId2,
          orderIndex: 1,
          notes: 'Perfect bossa nova groove',
        ).toMap(),
      );
    } catch (e) {
      // Log seed error but don't fail initialization
      print('Database seeding failed: $e');
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
    final path = join(await getDatabasesPath(), AppConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
    _lastAccessedSong = null;
    _lastAccessedRepertoire = null;
  }

  /// Export database as backup
  Future<Map<String, dynamic>> exportDatabase() async {
    final db = await database;

    try {
      final songs = await getAllSongs();
      final repertoires = await getAllRepertoires();
      final repertoireSongs = <RepertoireSong>[];

      // Get all repertoire songs
      for (final repertoire in repertoires) {
        final songsInRepertoire = await getSongsInRepertoire(repertoire.id!);
        for (final song in songsInRepertoire) {
          final rsMaps = await db.query(
            'repertoire_songs',
            where: 'repertoire_id = ? AND song_id = ?',
            whereArgs: [repertoire.id, song.id],
          );
          if (rsMaps.isNotEmpty) {
            repertoireSongs.add(RepertoireSong.fromMap(rsMaps.first));
          }
        }
      }

      return {
        'songs': songs.map((song) => song.toMap()).toList(),
        'repertoires': repertoires
            .map((repertoire) => repertoire.toMap())
            .toList(),
        'repertoireSongs': repertoireSongs.map((rs) => rs.toMap()).toList(),
        'exportedAt': DateTime.now().millisecondsSinceEpoch,
        'version': AppConstants.databaseVersion,
      };
    } catch (e) {
      throw DatabaseException(
        'Failed to export database',
        operation: 'exportDatabase',
        error: e,
      );
    }
  }

  /// Import database from backup
  Future<void> importDatabase(Map<String, dynamic> backup) async {
    final db = await database;

    try {
      await db.transaction((txn) async {
        // Clear existing data
        await txn.delete('songs');
        await txn.delete('repertoires');
        await txn.delete('repertoire_songs');
        await txn.delete('structures');
        await txn.delete('sections');
        await txn.delete('measures');

        // Import songs
        final songs = (backup['songs'] as List).cast<Map<String, dynamic>>();
        for (final songData in songs) {
          await txn.insert('songs', songData);
        }

        // Import repertoires
        final repertoires = (backup['repertoires'] as List)
            .cast<Map<String, dynamic>>();
        for (final repertoireData in repertoires) {
          await txn.insert('repertoires', repertoireData);
        }

        // Import repertoire songs
        final repertoireSongs = (backup['repertoireSongs'] as List)
            .cast<Map<String, dynamic>>();
        for (final rsData in repertoireSongs) {
          await txn.insert('repertoire_songs', rsData);
        }
      });

      // Clear cache
      _lastAccessedSong = null;
      _lastAccessedRepertoire = null;
    } catch (e) {
      throw DatabaseException(
        'Failed to import database',
        operation: 'importDatabase',
        error: e,
      );
    }
  }
}
