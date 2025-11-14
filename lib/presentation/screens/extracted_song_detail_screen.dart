import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../../data/models/song.dart';
import '../providers/extraction_song_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/repertoire_provider.dart';
import '../providers/export_provider.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/image_export_service.dart';
import '../../core/services/metronome_service.dart';
import '../widgets/chord_grid/chord_sheet_webview.dart';

/// Professional Extracted Song Detail Screen with pixel-perfect chord grid template
class ExtractedSongDetailScreen extends StatefulWidget {
  final int songId;
  final String? heroTag;

  const ExtractedSongDetailScreen({
    super.key,
    required this.songId,
    this.heroTag,
  });

  @override
  State<ExtractedSongDetailScreen> createState() =>
      _ExtractedSongDetailScreenState();
}

class _ExtractedSongDetailScreenState extends State<ExtractedSongDetailScreen> {
  late Song _song;
  bool _isLoading = true;
  final bool _showExportOptions = false;
  final GlobalKey<ChordSheetWebViewState> _webViewKey =
      GlobalKey<ChordSheetWebViewState>();
  final MetronomeService _metronomeService = MetronomeService();
  bool _isMetronomePlaying = false;
  Timer? _pageAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _loadSong();
  }

  @override
  void dispose() {
    _metronomeService.dispose();
    _pageAdvanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSong() async {
    print('DEBUG: Loading extracted song with ID: ${widget.songId}');
    try {
      final song = await Provider.of<ExtractionSongProvider>(
        context,
        listen: false,
      ).getSongById(widget.songId);
      print('DEBUG: ExtractionSongProvider returned: $song');
      if (song != null) {
        final totalMeasures = song.sections.fold<int>(
          0,
          (sum, section) => sum + section.measures.length,
        );
        print(
          'DEBUG: Extracted song loaded successfully - Title: ${song.title}, Sections: ${song.sections.length}, Total Measures: $totalMeasures',
        );
        setState(() {
          _song = song;
          _isLoading = false;
        });
      } else {
        print('DEBUG: Extracted song not found for ID: ${widget.songId}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('DEBUG: Error loading extracted song: $e');
      setState(() => _isLoading = false);
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

          // Extracted Song Header with indicator
          _buildSongHeader(),

          // Structure Card (if defined)
          _buildStructureCard(),

          // Metronome control above chord sheet
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isMetronomePlaying
                                ? Colors.red
                                : Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isMetronomePlaying ? Icons.stop : Icons.play_arrow,
                            size: 20,
                            color: _isMetronomePlaying
                                ? Colors.red
                                : Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: _toggleMetronome,
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'métronome',
                        style: TextStyle(
                          color: _isMetronomePlaying
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Chord Grid Template
          _buildChordGridTemplate(),

          // Bottom spacing for action bar
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),

      // Bottom Action Bar (simplified for extracted songs)
      bottomSheet: _buildBottomActionBar(),
    );
  }

  /// Build AppBar with Hero animation
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: Theme.of(context).colorScheme.primary,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Favorite button with animation
        Hero(
          tag: 'favorite_${widget.heroTag ?? _song.id}',
          child: IconButton(
            icon: Icon(
              _song.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _song.isFavorite
                  ? Colors.red
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: _toggleFavorite,
          ),
        ),
        // More options (limited for extracted songs)
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: Theme.of(context).colorScheme.primary,
          ),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(
                    Icons.download,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Exporter',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(
                    Icons.share,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Partager',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
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
                Colors.orange.withOpacity(
                  0.1,
                ), // Different color for extracted songs
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build elegant song header with extracted song indicator
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
                // Extracted song indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Chanson extraite',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

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
                      value: ' ${_song.key}',
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
    print('DEBUG: _buildChordGridTemplate() called - Always using WebView');
    return SliverToBoxAdapter(
      child: ChordSheetWebView(
        key: _webViewKey,
        song: _song,
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  /// Build bottom action bar (simplified for extracted songs)
  Widget _buildBottomActionBar() {
    final primaryColor = Theme.of(context).colorScheme.primary;
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
              icon: Icon(Icons.download, size: 20, color: primaryColor),
              label: Text('Export', style: TextStyle(color: primaryColor)),
              onPressed: _showExportBottomSheet,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: primaryColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(Icons.share, size: 20, color: primaryColor),
              label: Text('Partager', style: TextStyle(color: primaryColor)),
              onPressed: _captureAndShareImage,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: primaryColor),
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
                    'Exporter la grille extraite',
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
                        'Aperçu de la grille extraite',
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
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
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
    final success = await Provider.of<ExtractionSongProvider>(
      context,
      listen: false,
    ).toggleFavorite(_song.id!);
    if (success && mounted) {
      setState(() {
        _song = _song.copyWith(isFavorite: !_song.isFavorite);
      });
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _showExportBottomSheet();
        break;
      case 'share':
        _captureAndShareImage(); // Partage direct en PNG
        break;
      case 'delete':
        _deleteSong();
        break;
    }
  }

  int _getBeatsPerMeasure(String timeSignature) {
    switch (timeSignature) {
      case '4/4':
        return 4;
      case '3/4':
        return 3;
      case '2/4':
        return 2;
      case '6/8':
        return 6;
      case '12/8':
        return 12;
      case '5/4':
        return 5;
      case '7/8':
        return 7;
      default:
        return 4; // Default to 4/4
    }
  }

  void _toggleMetronome() async {
    if (_song.tempo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun tempo défini pour cette chanson extraite'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isMetronomePlaying) {
      _metronomeService.stop();
      _pageAdvanceTimer?.cancel();
      _pageAdvanceTimer = null;
      setState(() => _isMetronomePlaying = false);
    } else {
      await _metronomeService.start(_song.tempo!);
      // Start page advance timer
      final timeSignature = _song.timeSignature ?? '4/4';
      final beatsPerMeasure = _getBeatsPerMeasure(timeSignature);
      final timePerMeasure = (60.0 / _song.tempo!) * beatsPerMeasure;
      final timePerPage = timePerMeasure * 12; // measuresPerPage
      _pageAdvanceTimer = Timer.periodic(
        Duration(milliseconds: (timePerPage * 1000).toInt()),
        (_) => _webViewKey.currentState?.nextPage(),
      );
      setState(() => _isMetronomePlaying = true);
    }
  }

  void _deleteSong() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer la chanson extraite'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer "${_song.title}" par ${_song.artist} ? Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await Provider.of<ExtractionSongProvider>(
                  context,
                  listen: false,
                ).deleteSong(_song.id!);

                if (success && mounted) {
                  // Show success message and navigate back
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${_song.title}" a été supprimé'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop();
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de la suppression'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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

  void _exportSong(String format) async {
    final exportProvider = Provider.of<ExportProvider>(context, listen: false);

    switch (format) {
      case 'PNG':
        await _captureAndExportImage('png');
        break;
      case 'JPG':
        await _captureAndExportImage('jpg');
        break;
      case 'PDF':
        exportProvider.exportSongAsPDF(_song);
        break;
    }

    Navigator.pop(context); // Close bottom sheet
  }

  /// Capture screenshot and export as image
  Future<void> _captureAndExportImage(String format) async {
    try {
      print('DEBUG: Capturing screenshot for format: $format');

      // Wait for WebView to be fully rendered
      await Future.delayed(Duration(milliseconds: 500));
      await WidgetsBinding.instance.endOfFrame;

      // Get the screenshot controller from the WebView
      final webViewState = _webViewKey.currentState;
      if (webViewState == null) {
        print('DEBUG: WebView state is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: WebView non initialisée')),
        );
        return;
      }

      // Capture the screenshot using WebView's controller
      final imageBytes = await webViewState.controller.capture(
        pixelRatio: 3.0, // High quality
      );

      if (imageBytes == null) {
        print('DEBUG: Failed to capture screenshot');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la capture de l\'écran'),
          ),
        );
        return;
      }

      print(
        'DEBUG: Screenshot captured successfully, size: ${imageBytes.length} bytes',
      );

      // Generate file name
      final fileName =
          '${_song.title.replaceAll(' ', '_')}_extracted_chord_sheet.$format';

      // Save the image to gallery
      final success = await ImageExportService.saveImageToGallery(
        imageBytes,
        fileName,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image sauvegardée dans la galerie avec succès'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sauvegarde dans la galerie'),
          ),
        );
      }
    } catch (e) {
      print('Error capturing and exporting image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  /// Capture screenshot and share as image
  Future<void> _captureAndShareImage() async {
    try {
      print('DEBUG: Capturing screenshot for sharing');

      // Wait for WebView to be fully rendered
      await Future.delayed(Duration(milliseconds: 500));
      await WidgetsBinding.instance.endOfFrame;

      // Get the screenshot controller from the WebView
      final webViewState = _webViewKey.currentState;
      if (webViewState == null) {
        print('DEBUG: WebView state is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: WebView non initialisée')),
        );
        return;
      }

      // Capture the screenshot using WebView's controller
      final imageBytes = await webViewState.controller.capture(
        pixelRatio: 3.0, // High quality
      );

      if (imageBytes == null) {
        print('DEBUG: Failed to capture screenshot - imageBytes is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la capture de l\'écran'),
          ),
        );
        return;
      }

      print('DEBUG: Screenshot captured successfully');
      print('DEBUG: Image bytes length: ${imageBytes.length}');
      print(
        'DEBUG: This image likely includes Card padding/borders and HTML body padding',
      );
      print(
        'DEBUG: Expected content area should be smaller than captured area',
      );

      // Generate file name
      final fileName =
          '${_song.title.replaceAll(' ', '_')}_extracted_chord_sheet.png';

      // Share the image
      await ImageExportService.shareImageBytes(imageBytes, fileName);

      // Note: No snackbar needed for sharing as the share sheet handles feedback
    } catch (e) {
      print('DEBUG: Error capturing and sharing image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors du partage: $e')));
    }
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
