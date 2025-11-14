import 'package:flutter/material.dart';
import '../../data/services/database_helper.dart';
import '../../data/services/extraction_database_helper.dart';
import '../../data/models/repertoire.dart';
import '../../data/models/song.dart';

/// Modern RepertoireProvider with advanced state management features
class RepertoireProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Core state
  List<Repertoire> _repertoires = [];
  bool _isLoading = false;
  String? _errorMessage;
  Repertoire? _selectedRepertoire;
  List<Song> _repertoireSongs = [];

  // Getters
  List<Repertoire> get repertoires => _repertoires;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Repertoire? get selectedRepertoire => _selectedRepertoire;
  List<Song> get currentRepertoireSongs => _repertoireSongs;
  int get repertoireCount => _repertoires.length;

  /// Load all repertoires from database
  Future<void> loadRepertoires() async {
    _setLoading(true);
    _clearError();

    try {
      _repertoires = await _databaseHelper.getAllRepertoires();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load repertoires: $e');
    }
  }

  /// Create new repertoire with validation
  Future<bool> createRepertoire(Repertoire repertoire) async {
    _clearError();

    // Validate repertoire
    final errors = repertoire.validate();
    if (errors) {
      _setError('Invalid repertoire data');
      return false;
    }

    try {
      final id = await _databaseHelper.insertRepertoire(repertoire);
      if (id > 0) {
        final newRepertoire = repertoire.copyWith(id: id);
        _repertoires.add(newRepertoire);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to create repertoire: $e');
      return false;
    }
  }

  /// Update existing repertoire
  Future<bool> updateRepertoire(Repertoire repertoire) async {
    _clearError();

    // Validate repertoire
    final errors = repertoire.validate();
    if (errors) {
      _setError('Invalid repertoire data');
      return false;
    }

    try {
      final result = await _databaseHelper.updateRepertoire(repertoire);
      if (result > 0) {
        final index = _repertoires.indexWhere((r) => r.id == repertoire.id);
        if (index != -1) {
          _repertoires[index] = repertoire;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to update repertoire: $e');
      return false;
    }
  }

  /// Delete repertoire with cascade deletion
  Future<bool> deleteRepertoire(int id) async {
    _clearError();

    try {
      final result = await _databaseHelper.deleteRepertoire(id);
      if (result > 0) {
        _repertoires.removeWhere((r) => r.id == id);
        if (_selectedRepertoire?.id == id) {
          _selectedRepertoire = null;
          _repertoireSongs.clear();
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to delete repertoire: $e');
      return false;
    }
  }

  /// Select repertoire and load its songs
  Future<void> selectRepertoire(int id) async {
    _clearError();

    try {
      final repertoire = await _databaseHelper.getRepertoireById(id);
      if (repertoire != null) {
        _selectedRepertoire = repertoire;
        await loadSongsInRepertoire(id);
        notifyListeners();
      } else {
        _setError('Repertoire not found');
      }
    } catch (e) {
      _setError('Failed to select repertoire: $e');
    }
  }

  /// Load songs in selected repertoire
  Future<void> loadSongsInRepertoire(int repertoireId) async {
    _setLoading(true);
    _clearError();

    try {
      _repertoireSongs = await _databaseHelper.getSongsInRepertoire(
        repertoireId,
      );
      print(
        'DEBUG: loadSongsInRepertoire loaded ${_repertoireSongs.length} songs for repertoire $repertoireId',
      );
      _repertoireSongs.forEach((song) {
        print(
          'DEBUG: Song in repertoire: ${song.title} by ${song.artist} (ID: ${song.id})',
        );
      });
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load repertoire songs: $e');
    }
  }

  /// Add multiple songs to repertoire (supports both regular and extracted songs)
  Future<bool> addSongsToRepertoire(int repertoireId, List<int> songIds) async {
    _clearError();

    if (songIds.isEmpty) {
      _setError('No songs selected');
      return false;
    }

    try {
      // Separate regular and extracted song IDs
      final regularSongIds = <int>[];
      final extractedSongIds = <int>[];

      for (final songId in songIds) {
        if (songId < 0) {
          // Extracted song (negative ID)
          extractedSongIds.add(-(songId + 1000000)); // Convert back to positive
        } else {
          // Regular song
          regularSongIds.add(songId);
        }
      }

      // Add regular songs
      if (regularSongIds.isNotEmpty) {
        await _databaseHelper.addSongsToRepertoire(
          repertoireId,
          regularSongIds,
        );
      }

      // Add extracted songs (copy them to main database first if not already present)
      if (extractedSongIds.isNotEmpty) {
        final extractionHelper = ExtractionDatabaseHelper();

        for (final extractedSongId in extractedSongIds) {
          print('DEBUG: Processing extracted song ID: $extractedSongId');
          // Get the extracted song
          final extractedSong = await extractionHelper.getSongById(
            extractedSongId,
          );
          print(
            'DEBUG: Retrieved extracted song: ${extractedSong?.title} by ${extractedSong?.artist}',
          );
          if (extractedSong != null) {
            // Validate the song before copying
            if (!extractedSong.validate()) {
              print('DEBUG: Extracted song validation failed');
              print(
                'DEBUG: Title: "${extractedSong.title}", Artist: "${extractedSong.artist}", Key: "${extractedSong.key}", TimeSig: "${extractedSong.timeSignature}", Notation: "${extractedSong.notationType}"',
              );
              continue;
            }

            // Check if a song with the same title and artist already exists in main database
            final existingSong = await _databaseHelper.findSongByTitleAndArtist(
              extractedSong.title,
              extractedSong.artist,
            );

            int songIdToUse;
            if (existingSong != null) {
              print(
                'DEBUG: Song already exists in main database with ID: ${existingSong.id}',
              );
              songIdToUse = existingSong.id!;
            } else {
              // Copy to main database using database helper directly
              print(
                'DEBUG: Attempting to insert song directly to main database...',
              );
              try {
                final newSongId = await _databaseHelper.insertSong(
                  extractedSong,
                );
                print('DEBUG: Insert result - new song ID: $newSongId');

                if (newSongId > 0) {
                  songIdToUse = newSongId;
                } else {
                  print(
                    'DEBUG: Failed to insert song - returned ID: $newSongId',
                  );
                  continue;
                }
              } catch (e) {
                print('DEBUG: Exception during song insertion: $e');
                continue;
              }
            }

            // Add the song (existing or newly copied) to repertoire
            await _databaseHelper.addSongsToRepertoire(repertoireId, [
              songIdToUse,
            ]);
            print('DEBUG: Successfully added song to repertoire');
          } else {
            print('DEBUG: Could not retrieve extracted song');
          }
        }
      }

      // Reload repertoire songs if this is the selected repertoire
      if (_selectedRepertoire?.id == repertoireId) {
        await loadSongsInRepertoire(repertoireId);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add songs to repertoire: $e');
      return false;
    }
  }

  /// Remove song from repertoire
  Future<bool> removeSongFromRepertoire(int repertoireId, int songId) async {
    _clearError();

    try {
      final result = await _databaseHelper.removeSongFromRepertoire(
        repertoireId,
        songId,
      );
      if (result > 0) {
        // Remove from local state if this is the selected repertoire
        if (_selectedRepertoire?.id == repertoireId) {
          _repertoireSongs.removeWhere((song) => song.id == songId);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to remove song from repertoire: $e');
      return false;
    }
  }

  /// Reorder songs in repertoire
  Future<bool> reorderSongs(
    int repertoireId,
    int oldIndex,
    int newIndex,
  ) async {
    _clearError();

    try {
      // Get current song IDs in order
      final currentSongIds = _repertoireSongs.map((song) => song.id!).toList();

      // Reorder locally for immediate feedback
      if (oldIndex < currentSongIds.length &&
          newIndex < currentSongIds.length) {
        final songId = currentSongIds.removeAt(oldIndex);
        currentSongIds.insert(newIndex, songId);

        // Update local state
        final song = _repertoireSongs.removeAt(oldIndex);
        _repertoireSongs.insert(newIndex, song);
        notifyListeners();
      }

      // Save new order to database
      await _databaseHelper.reorderSongsInRepertoire(
        repertoireId,
        currentSongIds,
      );
      return true;
    } catch (e) {
      // Rollback local reorder on error
      if (_selectedRepertoire?.id == repertoireId) {
        await loadSongsInRepertoire(repertoireId);
      }
      _setError('Failed to reorder songs: $e');
      return false;
    }
  }

  /// Get repertoires containing a specific song
  Future<List<Repertoire>> getRepertoiresBySongId(int songId) async {
    try {
      return await _databaseHelper.getRepertoiresBySongId(songId);
    } catch (e) {
      _setError('Failed to get repertoires for song: $e');
      return [];
    }
  }

  /// Clear selected repertoire
  void clearSelectedRepertoire() {
    _selectedRepertoire = null;
    _repertoireSongs.clear();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Private helper methods

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
