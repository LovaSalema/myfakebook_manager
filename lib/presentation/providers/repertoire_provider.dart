import 'package:flutter/material.dart';
import '../../data/services/database_helper.dart';
import '../../data/models/repertoire.dart';
import '../../data/models/song.dart';
import '../../core/utils/validators.dart';

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
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load repertoire songs: $e');
    }
  }

  /// Add multiple songs to repertoire
  Future<bool> addSongsToRepertoire(int repertoireId, List<int> songIds) async {
    _clearError();

    if (songIds.isEmpty) {
      _setError('No songs selected');
      return false;
    }

    try {
      await _databaseHelper.addSongsToRepertoire(repertoireId, songIds);

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
