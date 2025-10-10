import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/song.dart';
import '../../data/models/section.dart';
import '../../data/models/measure.dart';
import '../providers/song_provider.dart';
import '../providers/theme_provider.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/database_helper.dart';
import 'add_song_screen.dart';

/// Screen for viewing song details and chord sheets
class SongDetailScreen extends StatefulWidget {
  final int songId;

  const SongDetailScreen({super.key, required this.songId});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  Song? _song;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongData();
  }

  /// Load song data from database
  Future<void> _loadSongData() async {
    try {
      final databaseHelper = DatabaseHelper();
      _song = await databaseHelper.getSongById(widget.songId);

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

  /// Edit song
  void _editSong() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddSongScreen(song: _song)),
    ).then((_) {
      // Reload song data after editing
      _loadSongData();
    });
  }

  /// Delete song with confirmation
  void _deleteSong() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer la chanson'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer "${_song?.title}" ? Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performDelete();
              },
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Perform the actual song deletion
  Future<void> _performDelete() async {
    try {
      final songProvider = Provider.of<SongProvider>(context, listen: false);
      final success = await songProvider.deleteSong(widget.songId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chanson supprimée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        _showError('Erreur lors de la suppression de la chanson');
      }
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  /// Handle menu actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editSong();
        break;
      case 'delete':
        _deleteSong();
        break;
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
          _song?.title ?? 'Détails de la chanson',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          // Three-dot menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _song == null
          ? _buildErrorState()
          : _buildContent(),
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
          Text('Chanson non trouvée', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            'La chanson demandée n\'existe pas',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Song header info
          _buildSongHeader(),
          const SizedBox(height: 24),

          // Chord sheet template
          ChordSheetTemplate(song: _song!),
        ],
      ),
    );
  }

  /// Build song header with metadata
  Widget _buildSongHeader() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _song!.title,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _song!.artist,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_song!.key.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _song!.key,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (_song!.tempo != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.speed,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tempo: ${_song!.tempo} BPM',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
            if (_song!.isFavorite) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.favorite, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Favori',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Professional Chord Sheet Template - Nashville Number System Style
class ChordSheetTemplate extends StatelessWidget {
  final Song song;
  final double fontSize;
  final bool showBarLines;

  const ChordSheetTemplate({
    super.key,
    required this.song,
    this.fontSize = 16,
    this.showBarLines = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with song info
            _buildHeader(context),
            const SizedBox(height: 24),

            // Chord grid sections
            if (song.sections.isNotEmpty) ...[
              for (var section in song.sections)
                _buildSection(context, section),
            ] else
              _buildEmptyState(context),
          ],
        ),
      ),
    );
  }

  /// Build header with song metadata
  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Key and Title
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Key
              Text(
                'key of ${song.key}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              const SizedBox(height: 4),

              // Title
              Text(
                song.title.toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JetBrains Mono',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        // Right side - Tempo and Artist
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Tempo
            if (song.tempo != null)
              Text(
                '♩=${song.tempo}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            const SizedBox(height: 4),

            // Artist
            Text(
              song.artist.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build a section (Intro, Verse, Chorus, etc.)
  Widget _buildSection(BuildContext context, Section section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label with additional info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  section.sectionType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
              if (section.sectionLabel?.isNotEmpty == true) ...[
                const SizedBox(width: 12),
                Text(
                  section.sectionLabel!,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Chord bars
          if (section.measures.isNotEmpty)
            _buildBars(context, section.measures),
        ],
      ),
    );
  }

  /// Build bars (measures) with chords
  Widget _buildBars(BuildContext context, List<Measure> measures) {
    return Column(
      children: [
        for (int i = 0; i < measures.length; i += 4)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildBarRow(
              context,
              measures.sublist(
                i,
                (i + 4 > measures.length) ? measures.length : i + 4,
              ),
            ),
          ),
      ],
    );
  }

  /// Build a row of 4 bars
  Widget _buildBarRow(BuildContext context, List<Measure> measures) {
    return Row(
      children: [
        for (int i = 0; i < measures.length; i++) ...[
          Expanded(child: _buildBar(context, measures[i])),
          if (i < measures.length - 1) const SizedBox(width: 8),
        ],
        // Fill empty spaces if less than 4 bars
        for (int i = measures.length; i < 4; i++) ...[
          const Expanded(child: SizedBox()),
          if (i < 3) const SizedBox(width: 8),
        ],
      ],
    );
  }

  /// Build a single bar (measure)
  Widget _buildBar(BuildContext context, Measure measure) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // Time signature (4/4) at the beginning
          if (measure.timeSignature != null)
            Positioned(
              left: 4,
              top: 2,
              child: Text(
                measure.timeSignature!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ),

          // Chords
          Center(child: _buildChordContent(measure)),

          // Repeat signs - using specialSymbol for repeat markers
          if (measure.specialSymbol == '%')
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: Colors.black),
            ),
          if (measure.specialSymbol == 'D.S.' ||
              measure.specialSymbol == 'D.C.')
            Positioned(
              right: 2,
              top: 8,
              child: Text(
                measure.specialSymbol!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Ending brackets
          if (measure.hasFirstEnding)
            Positioned(
              right: 4,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  '1.',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          if (measure.hasSecondEnding)
            Positioned(
              right: 4,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  '2.',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build chord content inside a bar
  Widget _buildChordContent(Measure measure) {
    if (measure.chords.isEmpty) {
      return const Text(
        '/',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
      );
    }

    if (measure.chords.length == 1) {
      return Text(
        measure.chords[0],
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'JetBrains Mono',
        ),
      );
    }

    // Multiple chords in one bar
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: measure.chords
          .map(
            (chord) => Text(
              chord,
              style: TextStyle(
                fontSize: fontSize - 2,
                fontWeight: FontWeight.bold,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          )
          .toList(),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.music_note, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Aucune section définie',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Éditez cette chanson pour ajouter des accords',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
