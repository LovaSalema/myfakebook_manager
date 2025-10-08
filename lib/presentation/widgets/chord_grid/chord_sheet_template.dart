import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/chord_parser.dart';
import '../../../data/models/song.dart';
import '../../../data/models/section.dart';

/// Chord sheet template widget for displaying chord grids
class ChordSheetTemplate extends StatelessWidget {
  final Song song;
  final bool showMeasureNumbers;
  final bool showSectionHeaders;
  final int measuresPerLine;

  const ChordSheetTemplate({
    super.key,
    required this.song,
    this.showMeasureNumbers = true,
    this.showSectionHeaders = true,
    this.measuresPerLine = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color(AppColors.borderMedium)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Song header
          _buildSongHeader(),

          // Chord grid
          _buildChordGrid(),

          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  /// Build song header
  Widget _buildSongHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(AppColors.sectionHeader),
        border: Border(
          bottom: BorderSide(color: Color(AppColors.borderMedium)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(song.title, style: AppTextStyles.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'by ${song.artist}',
            style: AppTextStyles.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          _buildSongInfo(),
        ],
      ),
    );
  }

  /// Build song information
  Widget _buildSongInfo() {
    return Row(
      children: [
        _InfoChip(label: 'Key', value: song.key),
        const SizedBox(width: 8),
        _InfoChip(label: 'Time', value: song.timeSignature),
        const SizedBox(width: 8),
        _InfoChip(label: 'Tempo', value: '${song.tempo} BPM'),
        if (song.style != null && song.style!.isNotEmpty) ...[
          const SizedBox(width: 8),
          _InfoChip(label: 'Style', value: song.style!),
        ],
      ],
    );
  }

  /// Build chord grid
  Widget _buildChordGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildSections(),
      ),
    );
  }

  /// Build sections
  List<Widget> _buildSections() {
    final widgets = <Widget>[];
    int measureNumber = 1;

    for (final section in song.sections) {
      for (int repeat = 0; repeat < section.repeatCount; repeat++) {
        // Section header
        if (showSectionHeaders && repeat == 0) {
          widgets.add(_buildSectionHeader(section));
        }

        // Measures
        final measures = <Widget>[];
        for (int i = 0; i < section.measures.length; i++) {
          final measure = section.measures[i];
          final chordText = measure.displayText;

          measures.add(
            _MeasureWidget(
              number: showMeasureNumbers ? measureNumber : null,
              chord: chordText,
              isStartOfSection: i == 0 && repeat == 0,
              isEndOfSection:
                  i == section.measures.length - 1 &&
                  repeat == section.repeatCount - 1,
            ),
          );
          measureNumber++;
        }

        if (measures.isNotEmpty) {
          widgets.add(
            _MeasureRow(measures: measures, measuresPerLine: measuresPerLine),
          );
        }
      }
    }

    return widgets;
  }

  /// Build section header
  Widget _buildSectionHeader(Section section) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Color(AppColors.sectionHeader),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(section.displayName, style: AppTextStyles.sectionHeader),
          if (section.repeatCount > 1) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'x${section.repeatCount}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Color(AppColors.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build footer
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(AppColors.background),
        border: Border(top: BorderSide(color: Color(AppColors.borderMedium))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Generated by MyFakeBook Manager',
            style: AppTextStyles.labelSmall.copyWith(
              color: Color(AppColors.textSecondary),
            ),
          ),
          Text(
            'Page 1',
            style: AppTextStyles.labelSmall.copyWith(
              color: Color(AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Measure row widget
class _MeasureRow extends StatelessWidget {
  final List<Widget> measures;
  final int measuresPerLine;

  const _MeasureRow({required this.measures, required this.measuresPerLine});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (int i = 0; i < measures.length; i += measuresPerLine) {
      final rowMeasures = measures.sublist(
        i,
        i + measuresPerLine > measures.length
            ? measures.length
            : i + measuresPerLine,
      );

      rows.add(
        Row(
          children: [
            ...rowMeasures,
            // Add empty measures to fill the row
            for (int j = rowMeasures.length; j < measuresPerLine; j++)
              const Expanded(child: SizedBox()),
          ],
        ),
      );

      if (i + measuresPerLine < measures.length) {
        rows.add(const SizedBox(height: 8));
      }
    }

    return Column(children: rows);
  }
}

/// Measure widget
class _MeasureWidget extends StatelessWidget {
  final int? number;
  final String chord;
  final bool isStartOfSection;
  final bool isEndOfSection;

  const _MeasureWidget({
    this.number,
    required this.chord,
    this.isStartOfSection = false,
    this.isEndOfSection = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          border: Border.all(
            color: _getBorderColor(),
            width: _getBorderWidth(),
          ),
          color: chord.isEmpty
              ? Colors.transparent
              : Color(AppColors.chordHighlight),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (number != null) ...[
              Text(number.toString(), style: AppTextStyles.measureNumber),
              const SizedBox(height: 2),
            ],
            Text(
              ChordParser.getDisplayName(chord),
              style: chord.isEmpty
                  ? AppTextStyles.bodyMedium
                  : AppTextStyles.chordText,
              textAlign: TextAlign.center,
            ),
            if (isStartOfSection || isEndOfSection) ...[
              const SizedBox(height: 2),
              Text(
                isStartOfSection ? '▶' : '◀',
                style: AppTextStyles.measureNumber,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Get border color based on section boundaries
  Color _getBorderColor() {
    if (isStartOfSection || isEndOfSection) {
      return Color(AppColors.primary);
    }
    return Color(AppColors.measureBorder);
  }

  /// Get border width based on section boundaries
  double _getBorderWidth() {
    if (isStartOfSection || isEndOfSection) {
      return 2.0;
    }
    return 1.0;
  }
}

/// Info chip widget
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(AppColors.borderLight)),
      ),
      child: Text('$label: $value', style: AppTextStyles.labelSmall),
    );
  }
}

/// Empty chord sheet template for creating new songs
class EmptyChordSheetTemplate extends StatelessWidget {
  final int measuresPerLine;
  final int totalMeasures;

  const EmptyChordSheetTemplate({
    super.key,
    this.measuresPerLine = 4,
    this.totalMeasures = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color(AppColors.borderMedium)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Empty header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(AppColors.sectionHeader),
              border: Border(
                bottom: BorderSide(color: Color(AppColors.borderMedium)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 200,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),

          // Empty measures
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildEmptyMeasures(),
          ),
        ],
      ),
    );
  }

  /// Build empty measures
  Widget _buildEmptyMeasures() {
    final rows = <Widget>[];
    final totalRows = (totalMeasures / measuresPerLine).ceil();

    for (int row = 0; row < totalRows; row++) {
      final measuresInRow = row == totalRows - 1
          ? totalMeasures - (row * measuresPerLine)
          : measuresPerLine;

      rows.add(
        Row(
          children: [
            for (int i = 0; i < measuresInRow; i++)
              Expanded(
                child: Container(
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(AppColors.measureBorder)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text('', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ),
            // Fill remaining space with empty containers
            for (int i = measuresInRow; i < measuresPerLine; i++)
              const Expanded(child: SizedBox()),
          ],
        ),
      );

      if (row < totalRows - 1) {
        rows.add(const SizedBox(height: 8));
      }
    }

    return Column(children: rows);
  }
}
