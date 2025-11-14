import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/database_helper.dart';
import '../../data/services/extraction_database_helper.dart';
import '../../data/models/song.dart';
import '../../core/utils/validators.dart';

/// Modern SongProvider with advanced state management features
class SongProvider with ChangeNotifier {
  final BaseDatabaseHelper _databaseHelper;

  // Constructor with optional database helper (defaults to main database)
  SongProvider([BaseDatabaseHelper? databaseHelper])
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  // Core state
  List<Song> _songs = [];
  bool _isLoading = false;
  String? _errorMessage;
  Song? _selectedSong;

  // Filter state
  String? _searchQuery;
  String? _keyFilter;
  bool _favoritesOnly = false;
  bool _includeExtractedSongs = false;
  Timer? _searchDebounceTimer;

  // Getters
  List<Song> get songs => _applyFilters(_songs);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Song? get selectedSong => _selectedSong;
  String? get searchQuery => _searchQuery;
  String? get keyFilter => _keyFilter;
  bool get favoritesOnly => _favoritesOnly;
  bool get includeExtractedSongs => _includeExtractedSongs;

  // Computed getters
  List<Song> get favoriteSongs =>
      _songs.where((song) => song.isFavorite).toList();
  int get songCount => _songs.length;
  int get favoriteCount => favoriteSongs.length;

  /// Load all songs from database
  Future<void> loadSongs() async {
    _setLoading(true);
    _clearError();

    try {
      _songs = await _databaseHelper.getAllSongs();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load songs: $e');
    }
  }

  /// Load all songs including extracted songs for repertoire selection
  Future<void> loadAllSongsForRepertoire() async {
    _setLoading(true);
    _clearError();

    try {
      // Clean up any duplicate songs first
      final cleanedCount = await _databaseHelper.cleanupDuplicateSongs();
      if (cleanedCount > 0) {
        print('DEBUG: Cleaned up $cleanedCount duplicate songs');
      }

      // Load regular songs
      final regularSongs = await _databaseHelper.getAllSongs();

      // Load extracted songs
      final extractionHelper = ExtractionDatabaseHelper();
      final extractedSongs = await extractionHelper.getAllSongs();

      // Mark extracted songs and combine lists
      final markedExtractedSongs = extractedSongs.map((song) {
        // Create a special ID for extracted songs (negative to avoid conflicts)
        return song.copyWith(
          id: -(song.id! + 1000000),
        ); // Offset to avoid conflicts
      }).toList();

      _songs = [...regularSongs, ...markedExtractedSongs];
      _includeExtractedSongs = true;
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load songs: $e');
    }
  }

  /// Add a new song with validation and optimistic update
  Future<bool> addSong(Song song) async {
    _clearError();

    // Validate song
    if (!song.validate()) {
      print('Song validation failed in provider');
      _setError('Invalid song data');
      return false;
    }

    // Optimistic update
    final optimisticSong = song.copyWith(id: -1); // Temporary ID
    _songs.add(optimisticSong);
    notifyListeners();

    try {
      print('Calling database insertSong');
      final id = await _databaseHelper.insertSong(song);
      print('Database insertSong returned id: $id');
      if (id > 0) {
        // Replace optimistic song with real one
        final index = _songs.indexWhere((s) => s.id == -1);
        if (index != -1) {
          _songs[index] = song.copyWith(id: id);
          notifyListeners();
        }
        return true;
      }
      // Rollback optimistic update
      _songs.removeWhere((s) => s.id == -1);
      notifyListeners();
      return false;
    } catch (e) {
      print('Database insertSong failed: $e');
      // Rollback optimistic update
      _songs.removeWhere((s) => s.id == -1);
      _setError('Failed to add song: $e');
      return false;
    }
  }

  /// Update existing song with optimistic update
  Future<bool> updateSong(Song song) async {
    _clearError();

    // Validate song
    if (!song.validate()) {
      _setError('Invalid song data');
      return false;
    }

    // Optimistic update
    final index = _songs.indexWhere((s) => s.id == song.id);
    if (index == -1) {
      _setError('Song not found');
      return false;
    }

    final oldSong = _songs[index];
    _songs[index] = song;
    notifyListeners();

    try {
      final result = await _databaseHelper.updateSong(song);
      if (result > 0) {
        return true;
      }
      // Rollback optimistic update
      _songs[index] = oldSong;
      notifyListeners();
      return false;
    } catch (e) {
      // Rollback optimistic update
      _songs[index] = oldSong;
      _setError('Failed to update song: $e');
      notifyListeners();
      return false;
    }
  }

  /// Delete song with confirmation simulation
  Future<bool> deleteSong(int id) async {
    _clearError();

    // Optimistic removal
    final songToDelete = _songs.firstWhere((s) => s.id == id);
    _songs.removeWhere((s) => s.id == id);
    notifyListeners();

    try {
      final result = await _databaseHelper.deleteSong(id);
      if (result > 0) {
        return true;
      }
      // Rollback optimistic removal
      _songs.add(songToDelete);
      notifyListeners();
      return false;
    } catch (e) {
      // Rollback optimistic removal
      _songs.add(songToDelete);
      _setError('Failed to delete song: $e');
      notifyListeners();
      return false;
    }
  }

  /// Toggle favorite status with optimistic update
  Future<bool> toggleFavorite(int id) async {
    _clearError();

    final index = _songs.indexWhere((s) => s.id == id);
    if (index == -1) {
      _setError('Song not found');
      return false;
    }

    final song = _songs[index];
    final newFavoriteStatus = !song.isFavorite;

    // Optimistic update
    _songs[index] = song.copyWith(isFavorite: newFavoriteStatus);
    notifyListeners();

    try {
      final result = await _databaseHelper.toggleFavorite(id);
      if (result > 0) {
        return true;
      }
      // Rollback optimistic update
      _songs[index] = song;
      notifyListeners();
      return false;
    } catch (e) {
      // Rollback optimistic update
      _songs[index] = song;
      _setError('Failed to toggle favorite: $e');
      notifyListeners();
      return false;
    }
  }

  /// Search songs with debounce
  void searchSongs(String query) {
    _searchQuery = query.trim().isEmpty ? null : query.trim();

    // Cancel previous debounce timer
    _searchDebounceTimer?.cancel();

    // Set new debounce timer
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      notifyListeners();
    });
  }

  /// Set key filter
  void setKeyFilter(String? key) {
    _keyFilter = key;
    notifyListeners();
  }

  /// Toggle favorites filter
  void toggleFavoritesFilter() {
    _favoritesOnly = !_favoritesOnly;
    notifyListeners();
  }

  /// Select song
  void selectSong(int id) {
    _selectedSong = _songs.firstWhere((s) => s.id == id);
    notifyListeners();
  }

  /// Clear selected song
  void clearSelectedSong() {
    _selectedSong = null;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = null;
    _keyFilter = null;
    _favoritesOnly = false;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get song by ID
  Future<Song?> getSongById(int id) async {
    try {
      return await _databaseHelper.getSongById(id);
    } catch (e) {
      _setError('Failed to get song: $e');
      return null;
    }
  }

  /// Get recent songs
  Future<List<Song>> getRecentSongs({int limit = 10}) async {
    try {
      return await _databaseHelper.getRecentSongs(limit);
    } catch (e) {
      _setError('Failed to get recent songs: $e');
      return [];
    }
  }

  /// Get songs by key
  Future<List<Song>> getSongsByKey(String key) async {
    try {
      return await _databaseHelper.getSongsByKey(key);
    } catch (e) {
      _setError('Failed to get songs by key: $e');
      return [];
    }
  }

  /// Get songs by time signature
  Future<List<Song>> getSongsByTimeSignature(String timeSignature) async {
    try {
      return await _databaseHelper.searchSongs(
        timeSignature,
      ); // Using search as fallback
    } catch (e) {
      _setError('Failed to get songs by time signature: $e');
      return [];
    }
  }

  /// Get statistics
  Future<Map<String, int>> getStats() async {
    try {
      return {'songCount': songCount, 'favoriteCount': favoriteCount};
    } catch (e) {
      _setError('Failed to get stats: $e');
      return {'songCount': 0, 'favoriteCount': 0};
    }
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

  List<Song> _applyFilters(List<Song> songs) {
    var filteredSongs = songs;

    // Apply search filter
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filteredSongs = filteredSongs.where((song) {
        return song.title.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
            song.artist.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
            (song.style?.toLowerCase().contains(_searchQuery!.toLowerCase()) ??
                false);
      }).toList();
    }

    // Apply key filter
    if (_keyFilter != null) {
      filteredSongs = filteredSongs
          .where((song) => song.key == _keyFilter)
          .toList();
    }

    // Apply favorites filter
    if (_favoritesOnly) {
      filteredSongs = filteredSongs.where((song) => song.isFavorite).toList();
    }

    return filteredSongs;
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}
