import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/repertoire.dart';
import '../../data/models/song.dart';
import '../providers/repertoire_provider.dart';
import '../providers/song_provider.dart';
import '../providers/theme_provider.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import 'add_song_screen.dart';
import 'song_detail_screen.dart';
import '../../data/services/database_helper.dart';

/// Screen for viewing and managing repertoire details
class RepertoireDetailScreen extends StatefulWidget {
  final int repertoireId;

  const RepertoireDetailScreen({super.key, required this.repertoireId});

  @override
  State<RepertoireDetailScreen> createState() => _RepertoireDetailScreenState();
}

class _RepertoireDetailScreenState extends State<RepertoireDetailScreen> {
  Repertoire? _repertoire;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRepertoireData();
  }

  /// Load repertoire data and its songs
  Future<void> _loadRepertoireData() async {
    try {
      final databaseHelper = DatabaseHelper();

      // Load repertoire details
      _repertoire = await databaseHelper.getRepertoireById(widget.repertoireId);

      // Load songs in repertoire
      final repertoireProvider = Provider.of<RepertoireProvider>(
        context,
        listen: false,
      );
      await repertoireProvider.loadSongsInRepertoire(widget.repertoireId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Erreur lors du chargement: $e');
    }
  }

  /// Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Show success message
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// Navigate to add existing songs screen
  void _addExistingSongs() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _AddSongsToRepertoireSheet(
          repertoireId: widget.repertoireId,
          onSongsAdded: _loadRepertoireData,
        );
      },
    );
  }

  /// Navigate to create new song screen for this repertoire
  void _createNewSong() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                AddSongScreen(repertoireId: widget.repertoireId),
          ),
        )
        .then((_) {
          // Reload data when returning from song creation
          _loadRepertoireData();
        });
  }

  /// Show modal with add options
  void _showAddOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _addExistingSongs();
                  },
                  child: const Text('Ajouter'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _createNewSong();
                  },
                  child: const Text('Créer'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Remove song from repertoire
  Future<void> _removeSongFromRepertoire(int songId) async {
    try {
      final repertoireProvider = Provider.of<RepertoireProvider>(
        context,
        listen: false,
      );

      final success = await repertoireProvider.removeSongFromRepertoire(
        widget.repertoireId,
        songId,
      );

      if (success) {
        _showSuccess('Chanson retirée du répertoire');
        _loadRepertoireData();
      } else {
        _showError('Erreur lors du retrait de la chanson');
      }
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  /// Navigate to song detail
  void _navigateToSongDetail(Song song) {
    if (song.id != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SongDetailScreen(songId: song.id!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? Color(AppColors.backgroundDark)
          : Color(AppColors.backgroundLight),
      appBar: AppBar(
        backgroundColor: isDark
            ? Color(AppColors.backgroundDark)
            : Color(AppColors.backgroundLight),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _repertoire?.name ?? 'Détails du répertoire',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addExistingSongs,
            tooltip: 'Ajouter des chansons existantes',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _repertoire == null
          ? _buildErrorState()
          : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptionsModal,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  /// Build error state
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text('Répertoire non trouvé', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Le répertoire demandé n\'existe pas',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Build main content
  Widget _buildContent() {
    return Consumer<RepertoireProvider>(
      builder: (context, repertoireProvider, child) {
        final songs = repertoireProvider.currentRepertoireSongs;
        final filteredSongs = _getFilteredSongs(songs);

        return Column(
          children: [
            // Repertoire header
            _buildRepertoireHeader(),

            // Search bar
            _buildSearchBar(),

            // Songs list
            Expanded(
              child: songs.isEmpty
                  ? _buildEmptyState()
                  : _buildSongsList(filteredSongs),
            ),
          ],
        );
      },
    );
  }

  /// Build repertoire header with details
  Widget _buildRepertoireHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _repertoire!.name,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_repertoire!.description?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              _repertoire!.description!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
          if (_repertoire!.eventDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  _repertoire!.eventDateDisplay,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Consumer<RepertoireProvider>(
            builder: (context, repertoireProvider, child) {
              final songCount =
                  repertoireProvider.currentRepertoireSongs.length;
              return Text(
                '$songCount chanson${songCount > 1 ? 's' : ''}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher dans le répertoire...',
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) => setState(() {}),
                style: AppTextStyles.bodyMedium,
              ),
            ),
            if (_searchController.text.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune chanson dans ce répertoire',
              style: AppTextStyles.headlineSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des chansons existantes ou créez-en de nouvelles',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build songs list
  Widget _buildSongsList(List<Song> songs) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return _SongListItem(
          song: song,
          onTap: () => _navigateToSongDetail(song),
          onRemove: () => _removeSongFromRepertoire(song.id!),
        );
      },
    );
  }

  /// Filter songs based on search query
  List<Song> _getFilteredSongs(List<Song> songs) {
    if (_searchController.text.isEmpty) {
      return songs;
    }

    final query = _searchController.text.toLowerCase();
    return songs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query) ||
          song.key.toLowerCase().contains(query);
    }).toList();
  }
}

/// Song list item widget
class _SongListItem extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SongListItem({
    required this.song,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getSongColor(song.title),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      song.title.isNotEmpty ? song.title[0].toUpperCase() : '?',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            song.artist,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          if (song.key.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                song.key,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: onRemove,
                  tooltip: 'Retirer du répertoire',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getSongColor(String title) {
    final colors = [
      Color(AppColors.primary),
      Color(AppColors.secondary),
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
    ];
    final index = title.isNotEmpty ? title.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }
}

/// Bottom sheet for adding existing songs to repertoire
class _AddSongsToRepertoireSheet extends StatefulWidget {
  final int repertoireId;
  final VoidCallback onSongsAdded;

  const _AddSongsToRepertoireSheet({
    required this.repertoireId,
    required this.onSongsAdded,
  });

  @override
  State<_AddSongsToRepertoireSheet> createState() =>
      _AddSongsToRepertoireSheetState();
}

class _AddSongsToRepertoireSheetState
    extends State<_AddSongsToRepertoireSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedSongIds = {};
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Text(
            'Ajouter des chansons au répertoire',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Search bar
          _buildSearchBar(),
          const SizedBox(height: 16),

          // Selected count
          if (_selectedSongIds.isNotEmpty) ...[
            Text(
              '${_selectedSongIds.length} chanson${_selectedSongIds.length > 1 ? 's' : ''} sélectionnée${_selectedSongIds.length > 1 ? 's' : ''}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Songs list
          Expanded(
            child: Consumer<SongProvider>(
              builder: (context, songProvider, child) {
                final songs = songProvider.songs;
                final filteredSongs = _getFilteredSongs(songs);

                return ListView.builder(
                  itemCount: filteredSongs.length,
                  itemBuilder: (context, index) {
                    final song = filteredSongs[index];
                    final isSelected = _selectedSongIds.contains(song.id);

                    return ListTile(
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedSongIds.add(song.id!);
                            } else {
                              _selectedSongIds.remove(song.id);
                            }
                          });
                        },
                      ),
                      title: Text(song.title),
                      subtitle: Text(song.artist),
                      trailing: song.key.isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                song.key,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),

          // Add button
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedSongIds.isEmpty || _isAdding
                  ? null
                  : _addSelectedSongs,
              child: _isAdding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Ajouter ${_selectedSongIds.length} chanson${_selectedSongIds.length > 1 ? 's' : ''}',
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build search bar for the bottom sheet
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher des chansons...',
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) => setState(() {}),
              style: AppTextStyles.bodyMedium,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  size: 20,
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Filter songs based on search query
  List<Song> _getFilteredSongs(List<Song> songs) {
    if (_searchController.text.isEmpty) {
      return songs;
    }

    final query = _searchController.text.toLowerCase();
    return songs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query) ||
          song.key.toLowerCase().contains(query);
    }).toList();
  }

  /// Add selected songs to repertoire
  Future<void> _addSelectedSongs() async {
    setState(() {
      _isAdding = true;
    });

    try {
      final repertoireProvider = Provider.of<RepertoireProvider>(
        context,
        listen: false,
      );

      final success = await repertoireProvider.addSongsToRepertoire(
        widget.repertoireId,
        _selectedSongIds.toList(),
      );

      if (success) {
        widget.onSongsAdded();
        Navigator.of(context).pop();
      } else {
        _showError('Erreur lors de l\'ajout des chansons');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() {
        _isAdding = false;
      });
    }
  }

  /// Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
