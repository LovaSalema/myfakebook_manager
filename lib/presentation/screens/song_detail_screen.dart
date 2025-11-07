import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:screenshot/screenshot.dart';
import '../../data/models/song.dart';
import '../../data/models/section.dart';
import '../../data/models/measure.dart';
import '../providers/song_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/repertoire_provider.dart';
import '../providers/export_provider.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/database_helper.dart';
import '../../data/services/image_export_service.dart';
import '../widgets/chord_grid/chord_sheet_template.dart';
import '../widgets/chord_grid/chord_sheet_webview.dart';
import 'add_song_screen.dart';

/// Enhanced Chord Sheet with CustomPaint for precise grid rendering
class CustomChordSheetTemplate extends StatelessWidget {
  final Song song;
  final double fontSize;
  final bool showBarLines;
  final int measuresPerLine;

  const CustomChordSheetTemplate({
    super.key,
    required this.song,
    this.fontSize = 14,
    this.showBarLines = true,
    this.measuresPerLine = 4,
  });

  @override
  Widget build(BuildContext context) {
    print(
      'DEBUG: CustomChordSheetTemplate.build() called - song: ${song.title}, sections: ${song.sections.length}',
    );
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // _buildHeader(context),
            const SizedBox(height: 20),
            if (song.sections.isNotEmpty) ...[
              _buildChordGridWithCustomPaint(),
            ] else
              _buildEmptyState(context),
          ],
        ),
      ),
    );
  }

  //  Build header with song metadata
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrains Mono',
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'by ${song.artist}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'JetBrains Mono',
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Key: ${song.key}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              if (song.tempo != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Tempo: ${song.tempo} BPM',
                  style: TextStyle(fontSize: 12, fontFamily: 'JetBrains Mono'),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                'Time: ${song.timeSignature}',
                style: TextStyle(fontSize: 12, fontFamily: 'JetBrains Mono'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build chord grid using CustomPaint for precise grid lines
  Widget _buildChordGridWithCustomPaint() {
    return Column(children: _buildSectionsWithCustomPaint());
  }

  /// Build all sections with CustomPaint grid
  List<Widget> _buildSectionsWithCustomPaint() {
    final widgets = <Widget>[];
    int globalMeasureNumber = 1;

    for (
      int sectionIndex = 0;
      sectionIndex < song.sections.length;
      sectionIndex++
    ) {
      final section = song.sections[sectionIndex];

      // Section header
      widgets.add(_buildSectionHeader(section));
      widgets.add(const SizedBox(height: 12));

      // Collect all measures for this section
      final sectionMeasures = <MeasureData>[];
      for (
        int measureIndex = 0;
        measureIndex < section.measures.length;
        measureIndex++
      ) {
        final measure = section.measures[measureIndex];
        sectionMeasures.add(
          MeasureData(
            measure: measure,
            measureNumber: globalMeasureNumber,
            isFirstInSection: measureIndex == 0,
            isLastInSection: measureIndex == section.measures.length - 1,
          ),
        );
        globalMeasureNumber++;
      }

      // Organize into rows and render with CustomPaint
      final measureRows = _organizeMeasuresIntoRows(sectionMeasures);
      for (final row in measureRows) {
        widgets.add(
          ChordGridRow(
            measures: row,
            measuresPerLine: measuresPerLine,
            fontSize: fontSize,
          ),
        );
      }

      if (sectionIndex < song.sections.length - 1) {
        widgets.add(const SizedBox(height: 16));
      }
    }

    return widgets;
  }

  /// Organize measures into rows
  List<List<MeasureData>> _organizeMeasuresIntoRows(
    List<MeasureData> measures,
  ) {
    final rows = <List<MeasureData>>[];
    for (int i = 0; i < measures.length; i += measuresPerLine) {
      final end = (i + measuresPerLine > measures.length)
          ? measures.length
          : i + measuresPerLine;
      rows.add(measures.sublist(i, end));
    }
    return rows;
  }

  /// Build section header
  Widget _buildSectionHeader(Section section) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final textColor = isDark ? Colors.white : Colors.black;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                section.displayName.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JetBrains Mono',
                  color: textColor,
                ),
              ),
              if (section.repeatCount > 1) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: textColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    'x${section.repeatCount}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'JetBrains Mono',
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
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

/// Data class to hold measure information
class MeasureData {
  final Measure measure;
  final int measureNumber;
  final bool isFirstInSection;
  final bool isLastInSection;

  MeasureData({
    required this.measure,
    required this.measureNumber,
    required this.isFirstInSection,
    required this.isLastInSection,
  });
}

/// Custom widget for rendering a row of measures with CustomPaint grid
class ChordGridRow extends StatelessWidget {
  final List<MeasureData> measures;
  final int measuresPerLine;
  final double fontSize;

  const ChordGridRow({
    super.key,
    required this.measures,
    required this.measuresPerLine,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ChordGridPainter(
        measures: measures,
        measuresPerLine: measuresPerLine,
        fontSize: fontSize,
      ),
      child: Container(height: 90, color: Colors.transparent),
    );
  }
}

/// CustomPaint for rendering chord grid with precise lines
class ChordGridPainter extends CustomPainter {
  final List<MeasureData> measures;
  final int measuresPerLine;
  final double fontSize;

  ChordGridPainter({
    required this.measures,
    required this.measuresPerLine,
    required this.fontSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    print(
      'DEBUG: ChordGridPainter.paint() called - measures: ${measures.length}, size: $size',
    );

    final measureWidth = size.width / measuresPerLine;
    final measureHeight = size.height;

    print('DEBUG: measureWidth: $measureWidth, measureHeight: $measureHeight');

    // Paint styles
    final gridPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 0.5;

    final thickPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw vertical grid lines and measures
    for (int i = 0; i <= measuresPerLine; i++) {
      final x = i * measureWidth;

      if (i < measures.length) {
        // Thick border for section boundaries
        if (measures[i].isFirstInSection) {
          canvas.drawLine(Offset(x, 0), Offset(x, measureHeight), thickPaint);
        }
        if (measures[i].isLastInSection && i == measures.length - 1) {
          canvas.drawLine(
            Offset(x + measureWidth, 0),
            Offset(x + measureWidth, measureHeight),
            thickPaint,
          );
        } else if (i < measures.length - 1) {
          canvas.drawLine(
            Offset(x + measureWidth, 0),
            Offset(x + measureWidth, measureHeight),
            gridPaint,
          );
        }
      } else {
        // Empty measures fill
        canvas.drawLine(Offset(x, 0), Offset(x, measureHeight), gridPaint);
      }
    }

    // Draw horizontal line at bottom
    canvas.drawLine(
      Offset(0, measureHeight - 1),
      Offset(size.width, measureHeight - 1),
      gridPaint,
    );

    // Draw measure content
    for (int i = 0; i < measures.length; i++) {
      final measureData = measures[i];
      final x = i * measureWidth;
      final measureRect = Rect.fromLTWH(x, 0, measureWidth, measureHeight);

      _drawMeasureContent(canvas, measureRect, measureData, textPainter);
    }
  }

  /// Draw content inside a measure
  void _drawMeasureContent(
    Canvas canvas,
    Rect measureRect,
    MeasureData measureData,
    TextPainter textPainter,
  ) {
    final measure = measureData.measure;
    final x = measureRect.left;
    final y = measureRect.top;
    final width = measureRect.width;
    final height = measureRect.height;

    // Draw measure number (top-left)
    textPainter.text = TextSpan(
      text: '${measureData.measureNumber}.',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        fontFamily: 'JetBrains Mono',
        color: Colors.grey[600],
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x + 4, y + 2));

    // Draw chords (centered in measure)
    final validChords = measure.chords
        .where((chord) => chord.isNotEmpty)
        .toList();

    if (validChords.isNotEmpty) {
      final chordText = _formatChordForDisplay(validChords);
      textPainter.text = TextSpan(
        text: chordText,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'JetBrains Mono',
          color: Colors.black,
        ),
      );
      textPainter.layout();
      final dx = x + (width - textPainter.width) / 2;
      final dy = y + (height - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(dx, dy));
    } else {
      // Draw empty measure slash
      textPainter.text = TextSpan(
        text: '/',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w300,
          fontFamily: 'JetBrains Mono',
          color: Colors.grey,
        ),
      );
      textPainter.layout();
      final dx = x + (width - textPainter.width) / 2;
      final dy = y + (height - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(dx, dy));
    }

    // Draw special symbols (top-right)
    if (measure.specialSymbol != null) {
      textPainter.text = TextSpan(
        text: measure.specialSymbol,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'JetBrains Mono',
          color: Colors.red[700],
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + width - textPainter.width - 4, y + 2),
      );
    }

    // Draw ending brackets (bottom-right)
    if (measure.hasFirstEnding) {
      _drawEndingBracket(canvas, Offset(x + width - 20, y + height - 16), '1.');
    }
    if (measure.hasSecondEnding) {
      _drawEndingBracket(canvas, Offset(x + width - 20, y + height - 16), '2.');
    }
  }

  /// Format chord for display (handle slash chords)
  String _formatChordForDisplay(List<String> chords) {
    if (chords.length == 1) {
      return chords[0];
    }
    return chords.join(' ');
  }

  /// Draw ending bracket
  void _drawEndingBracket(Canvas canvas, Offset position, String text) {
    final bracketPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final bracketRect = Rect.fromLTWH(position.dx, position.dy, 16, 12);
    canvas.drawRect(bracketRect, bracketPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          fontFamily: 'JetBrains Mono',
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final dx = position.dx + (bracketRect.width - textPainter.width) / 2;
    final dy = position.dy + (bracketRect.height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(ChordGridPainter oldDelegate) {
    return oldDelegate.measures != measures ||
        oldDelegate.measuresPerLine != measuresPerLine ||
        oldDelegate.fontSize != fontSize;
  }
}

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
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _loadSong();
  }

  Future<void> _loadSong() async {
    print('DEBUG: Loading song with ID: ${widget.songId}');
    try {
      final song = await Provider.of<SongProvider>(
        context,
        listen: false,
      ).getSongById(widget.songId);
      print('DEBUG: SongProvider returned: $song');
      if (song != null) {
        print(
          'DEBUG: Song loaded successfully - Title: ${song.title}, Sections: ${song.sections.length}',
        );
        setState(() {
          _song = song;
          _isLoading = false;
        });
      } else {
        print('DEBUG: Song not found for ID: ${widget.songId}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('DEBUG: Error loading song: $e');
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
          // _buildRepertoiresSection(),

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
        // Edit button
        IconButton(
          icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
          onPressed: _editSong,
        ),
        // More options
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
              value: 'transpose',
              child: Row(
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Transposer',
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
    print('DEBUG: _buildChordGridTemplate() called - Always using WebView');
    return SliverToBoxAdapter(
      child: Screenshot(
        controller: _screenshotController,
        child: ChordSheetWebView(
          key: ValueKey('webview_${_song.id}'),
          song: _song,
        ),
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
              ).animate().fadeIn(delay: 300.ms),
            ),
          );
        },
      ),
    );
  }

  /// Build bottom action bar
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
              icon: Icon(Icons.swap_horiz, size: 20, color: primaryColor),
              label: Text('Transposer', style: TextStyle(color: primaryColor)),
              onPressed: _transposeSong,
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
        _captureAndShareImage(); // Partage direct en PNG
        break;
      case 'delete':
        _deleteSong();
        break;
    }
  }

  void _transposeSong() {
    // Implementation for transposing song
  }

  void _deleteSong() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer la chanson'),
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
                final success = await Provider.of<SongProvider>(
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
      print('Capturing screenshot for format: $format');

      // Capture the screenshot
      final imageBytes = await _screenshotController.capture();

      if (imageBytes == null) {
        print('Failed to capture screenshot');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la capture de l\'écran'),
          ),
        );
        return;
      }

      // Generate file name
      final fileName =
          '${_song.title.replaceAll(' ', '_')}_chord_sheet.$format';

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
      print('Capturing screenshot for sharing');

      // Capture the screenshot
      final imageBytes = await _screenshotController.capture();

      if (imageBytes == null) {
        print('Failed to capture screenshot');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la capture de l\'écran'),
          ),
        );
        return;
      }

      // Generate file name
      final fileName = '${_song.title.replaceAll(' ', '_')}_chord_sheet.png';

      // Share the image
      await ImageExportService.shareImageBytes(imageBytes, fileName);

      // Note: No snackbar needed for sharing as the share sheet handles feedback
    } catch (e) {
      print('Error capturing and sharing image: $e');
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
