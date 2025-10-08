import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_text_styles.dart';
import '../providers/song_provider.dart';
import '../providers/repertoire_provider.dart';
import '../providers/export_provider.dart';
import '../widgets/chord_grid/chord_sheet_template.dart';
import '../../data/models/song.dart';
import 'add_song_screen.dart';

/// Professional Song Detail Screen with pixel-perfect chord grid template
class SongDetailScreen extends StatefulWidget {
  final int songId;
  final String? heroTag;

  const SongDetailScreen({super.key, required this.songId, this.heroTag});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  late Song _song;
  bool _isLoading = true;
  final bool _showExportOptions = false;

  @override
  void initState() {
    super.initState();
    _loadSong();
  }

  Future<void> _loadSong() async {
    try {
      final song = await Provider.of<SongProvider>(
        context,
        listen: false,
      ).getSongById(widget.songId);
      if (song != null) {
        setState(() {
          _song = song;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar with Hero animation
          _buildAppBar(),

          // Song Header
          _buildSongHeader(),

          // Structure Card (if defined)
          _buildStructureCard(),

          // Chord Grid Template
          _buildChordGridTemplate(),

          // Repertoires Section
          _buildRepertoiresSection(),

          // Bottom spacing for action bar
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),

      // Bottom Action Bar
      bottomSheet: _buildBottomActionBar(),
    );
  }

  /// Build AppBar with Hero animation
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Favorite button with animation
        Hero(
          tag: 'favorite_${widget.heroTag ?? _song.id}',
          child: IconButton(
            icon: Icon(
              _song.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _song.isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ),
        // Edit button
        IconButton(icon: const Icon(Icons.edit), onPressed: _editSong),
        // More options
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, size: 20),
                  SizedBox(width: 8),
                  Text('Exporter'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'transpose',
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, size: 20),
                  SizedBox(width: 8),
                  Text('Transposer'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 20),
                  SizedBox(width: 8),
                  Text('Partager'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build elegant song header
  SliverToBoxAdapter _buildSongHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with Hero animation
                Hero(
                  tag: 'title_${widget.heroTag ?? _song.id}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: Text(
                      _song.title,
                      style: AppTextStyles.headline1.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Artist
                Text(
                  _song.artist,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),

                // Metadata row
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _MetadataItem(
                      icon: Icons.music_note,
                      label: 'Tonalité',
                      value: 'Key of ${_song.key}',
                    ),
                    _MetadataItem(
                      icon: Icons.schedule,
                      label: 'Mesure',
                      value: _song.timeSignature,
                    ),
                    if (_song.tempo != null)
                      _MetadataItem(
                        icon: Icons.speed,
                        label: 'Tempo',
                        value: '♩=${_song.tempo}',
                      ),
                    if (_song.style?.isNotEmpty == true)
                      _MetadataItem(
                        icon: Icons.style,
                        label: 'Style',
                        value: _song.style!,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  /// Build structure card if defined
  Widget _buildStructureCard() {
    if (_song.structure?.pattern == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Structure',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _song.structure!.pattern!,
                  style: AppTextStyles.body1.copyWith(
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_song.structure!.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    _song.structure!.description!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: 100.ms),
    );
  }

  /// Build chord grid template
  SliverToBoxAdapter _buildChordGridTemplate() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ChordSheetTemplate(song: _song),
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  /// Build repertoires section
  Widget _buildRepertoiresSection() {
    return SliverToBoxAdapter(
      child: Consumer<RepertoireProvider>(
        builder: (context, repertoireProvider, child) {
          final repertoires = repertoireProvider.repertoires
              .where((rep) => true) // TODO: Implement songIds check
              .toList();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dans les répertoires',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (repertoires.isEmpty)
                      Text(
                        'Cette chanson n\'est dans aucun répertoire',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: repertoires
                            .map(
                              (repertoire) => Chip(
                                label: Text(repertoire.name),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
          );
        },
      ),
    );
  }

  /// Build bottom action bar
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.download, size: 20),
              label: const Text('Export'),
              onPressed: _showExportBottomSheet,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.swap_horiz, size: 20),
              label: const Text('Transposer'),
              onPressed: _transposeSong,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.share, size: 20),
              label: const Text('Partager'),
              onPressed: _shareSong,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build export bottom sheet
  void _showExportBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String selectedFormat = 'PNG';

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exporter la grille',
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Format selection
                  Text('Format d\'export', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      _ExportOption(
                        value: 'PNG',
                        label: 'PNG (Haute qualité)',
                        selected: selectedFormat == 'PNG',
                        onChanged: (value) =>
                            setModalState(() => selectedFormat = value),
                      ),
                      _ExportOption(
                        value: 'JPG',
                        label: 'JPG (Compressé)',
                        selected: selectedFormat == 'JPG',
                        onChanged: (value) =>
                            setModalState(() => selectedFormat = value),
                      ),
                      _ExportOption(
                        value: 'PDF',
                        label: 'PDF A4 (Impression)',
                        selected: selectedFormat == 'PDF',
                        onChanged: (value) =>
                            setModalState(() => selectedFormat = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Preview (placeholder)
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Aperçu de la grille',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Export button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _exportSong(selectedFormat),
                      child: const Text('Exporter'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper methods
  void _toggleFavorite() async {
    final success = await Provider.of<SongProvider>(
      context,
      listen: false,
    ).toggleFavorite(_song.id!);
    if (success && mounted) {
      setState(() {
        _song = _song.copyWith(isFavorite: !_song.isFavorite);
      });
    }
  }

  void _editSong() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddSongScreen(song: _song)),
    ).then((_) {
      // Reload song data after editing
      _loadSong();
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _showExportBottomSheet();
        break;
      case 'transpose':
        _transposeSong();
        break;
      case 'share':
        _shareSong();
        break;
      case 'delete':
        _deleteSong();
        break;
    }
  }

  void _transposeSong() {
    // Implementation for transposing song
  }

  void _shareSong() {
    // Implementation for sharing song
  }

  void _deleteSong() {
    // Implementation for deleting song
  }

  void _exportSong(String format) {
    final exportProvider = Provider.of<ExportProvider>(context, listen: false);

    switch (format) {
      case 'PNG':
        exportProvider.exportSongAsImage(_song);
        break;
      case 'JPG':
        exportProvider.exportSongAsImage(_song);
        break;
      case 'PDF':
        exportProvider.exportSongAsPDF(_song);
        break;
    }

    Navigator.pop(context); // Close bottom sheet
  }
}

/// Metadata item widget
class _MetadataItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetadataItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// Export option widget
class _ExportOption extends StatelessWidget {
  final String value;
  final String label;
  final bool selected;
  final ValueChanged<String> onChanged;

  const _ExportOption({
    required this.value,
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Radio<String>(
                value: value,
                groupValue: selected ? value : null,
                onChanged: (v) => onChanged(v!),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
