import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/chord_parser.dart';

/// Measure widget for displaying individual chord measures
class MeasureWidget extends StatefulWidget {
  final int? number;
  final String chord;
  final bool isStartOfSection;
  final bool isEndOfSection;
  final bool editable;
  final ValueChanged<String>? onChordChanged;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MeasureWidget({
    super.key,
    this.number,
    required this.chord,
    this.isStartOfSection = false,
    this.isEndOfSection = false,
    this.editable = false,
    this.onChordChanged,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<MeasureWidget> createState() => _MeasureWidgetState();
}

class _MeasureWidgetState extends State<MeasureWidget> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.chord);
  }

  @override
  void didUpdateWidget(MeasureWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chord != oldWidget.chord && !_isEditing) {
      _controller.text = widget.chord;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        width: 80,
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          border: Border.all(
            color: _getBorderColor(),
            width: _getBorderWidth(),
          ),
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(4),
        ),
        child: _isEditing && widget.editable
            ? _buildEditableMeasure()
            : _buildDisplayMeasure(),
      ),
    );
  }

  /// Build display mode measure
  Widget _buildDisplayMeasure() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.number != null) ...[
          Text(widget.number.toString(), style: AppTextStyles.measureNumber),
          const SizedBox(height: 2),
        ],
        Text(
          ChordParser.getDisplayName(widget.chord),
          style: _getChordTextStyle(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.isStartOfSection || widget.isEndOfSection) ...[
          const SizedBox(height: 2),
          Text(
            widget.isStartOfSection ? '▶' : '◀',
            style: AppTextStyles.measureNumber,
          ),
        ],
      ],
    );
  }

  /// Build editable mode measure
  Widget _buildEditableMeasure() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        style: AppTextStyles.chordText,
        textAlign: TextAlign.center,
        maxLength: 10,
        onChanged: (value) {
          setState(() {
            _isEditing = true;
          });
        },
        onSubmitted: (value) {
          _finishEditing(value);
        },
        onEditingComplete: () {
          _finishEditing(_controller.text);
        },
      ),
    );
  }

  /// Finish editing and notify parent
  void _finishEditing(String value) {
    setState(() {
      _isEditing = false;
    });
    widget.onChordChanged?.call(value);
  }

  /// Get border color based on state
  Color _getBorderColor() {
    if (widget.isStartOfSection || widget.isEndOfSection) {
      return Color(AppColors.primary);
    }
    if (_isEditing) {
      return Color(AppColors.secondary);
    }
    return Color(AppColors.measureBorder);
  }

  /// Get border width based on state
  double _getBorderWidth() {
    if (widget.isStartOfSection || widget.isEndOfSection) {
      return 2.0;
    }
    if (_isEditing) {
      return 2.0;
    }
    return 1.0;
  }

  /// Get background color based on chord content
  Color _getBackgroundColor() {
    if (_isEditing) {
      return Color(AppColors.chordHighlight);
    }
    if (widget.chord.isEmpty) {
      return Colors.transparent;
    }
    return Color(AppColors.chordHighlight);
  }

  /// Get chord text style based on chord content
  TextStyle _getChordTextStyle() {
    if (widget.chord.isEmpty) {
      return AppTextStyles.bodyMedium.copyWith(color: Colors.grey);
    }
    return AppTextStyles.chordText;
  }
}

/// Measure grid for displaying multiple measures in a row
class MeasureGrid extends StatelessWidget {
  final List<MeasureWidget> measures;
  final int measuresPerLine;
  final bool showGridLines;

  const MeasureGrid({
    super.key,
    required this.measures,
    this.measuresPerLine = 4,
    this.showGridLines = true,
  });

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
            // Add empty space to fill the row
            for (int j = rowMeasures.length; j < measuresPerLine; j++)
              const SizedBox(width: 84), // 80 + 2*2 margin
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

/// Section header widget
class SectionHeader extends StatelessWidget {
  final String title;
  final int repeatCount;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SectionHeader({
    super.key,
    required this.title,
    this.repeatCount = 1,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Color(AppColors.sectionHeader),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(title, style: AppTextStyles.sectionHeader),
                if (repeatCount > 1) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'x$repeatCount',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Color(AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onEdit != null || onDelete != null) ...[
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, size: 16),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ],
      ),
    );
  }
}

/// Empty measure placeholder
class EmptyMeasure extends StatelessWidget {
  final VoidCallback? onTap;

  const EmptyMeasure({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Color(AppColors.borderLight)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.add, color: Colors.grey, size: 20),
      ),
    );
  }
}

/// Measure number widget for grid headers
class MeasureNumber extends StatelessWidget {
  final int number;
  final bool isSectionStart;
  final bool isSectionEnd;

  const MeasureNumber({
    super.key,
    required this.number,
    this.isSectionStart = false,
    this.isSectionEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isSectionStart)
            const Text('▶', style: TextStyle(fontSize: 10, color: Colors.grey)),
          Text(number.toString(), style: AppTextStyles.measureNumber),
          if (isSectionEnd)
            const Text('◀', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
