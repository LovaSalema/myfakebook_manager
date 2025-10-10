import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/song.dart';
import '../../data/models/section.dart';
import '../../data/models/measure.dart';
import '../../data/services/database_helper.dart';
import '../providers/song_provider.dart';
import '../providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';

/// Screen for adding or editing a song
class AddSongScreen extends StatefulWidget {
  final Song? song;

  const AddSongScreen({super.key, this.song});

  @override
  State<AddSongScreen> createState() => _AddSongScreenState();
}

class _AddSongScreenState extends State<AddSongScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController();
  late final _artistController = TextEditingController();
  late final _keyController = TextEditingController(text: 'C');
  late final _tempoController = TextEditingController(text: '120');
  late final _timeSignatureController = TextEditingController(text: '4/4');

  bool _isSaving = false;
  String _selectedNotationType = 'ROMAN_NUMERALS';

  // Song structure data
  List<SongSection> _sections = [
    SongSection(
      name: 'A',
      measures: [
        SongMeasure(chords: ['I', 'V', 'VI', 'IV']),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  /// Initialize form with existing song data if editing
  void _initializeForm() {
    if (widget.song != null) {
      final song = widget.song!;
      _titleController.text = song.title;
      _artistController.text = song.artist;
      _keyController.text = song.key;
      _tempoController.text = song.tempo?.toString() ?? '120';
      _timeSignatureController.text = song.timeSignature;
      _selectedNotationType = song.notationType;
      // Note: Song structure sections would need to be loaded separately
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _keyController.dispose();
    _tempoController.dispose();
    _timeSignatureController.dispose();
    super.dispose();
  }

  /// Save the song to database (create or update)
  Future<void> _saveSong() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final databaseHelper = DatabaseHelper();

      // Convert local sections to database sections
      final sections = _sections.asMap().entries.map((entry) {
        final sectionIndex = entry.key;
        final section = entry.value;
        return Section.create(
          songId: 0, // Will be set after song creation
          sectionType: 'VERSE',
          sectionLabel: section.name,
          sectionName: section.name,
          sectionOrder: sectionIndex,
          measureCount: section.measures.length,
        ).copyWith(
          measures: section.measures.asMap().entries.map((measureEntry) {
            final measureIndex = measureEntry.key;
            final measure = measureEntry.value;
            return Measure(
              sectionId: 0, // Will be set after section creation
              measureOrder: measureIndex,
              timeSignature: _timeSignatureController.text.trim(),
              chords: measure.chords,
              specialSymbol: null,
              hasFirstEnding: false,
              hasSecondEnding: false,
            );
          }).toList(),
        );
      }).toList();

      if (widget.song != null) {
        // Update existing song
        final updatedSong = widget.song!.copyWith(
          title: _titleController.text.trim(),
          artist: _artistController.text.trim(),
          key: _keyController.text.trim(),
          timeSignature: _timeSignatureController.text.trim(),
          tempo: int.tryParse(_tempoController.text) ?? 120,
          style: null,
          notationType: _selectedNotationType,
          updatedAt: DateTime.now(),
          sections: sections,
        );

        if (!updatedSong.validate()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Données de chanson invalides'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final rowsAffected = await databaseHelper.updateSong(updatedSong);

        if (rowsAffected > 0) {
          final songProvider = Provider.of<SongProvider>(
            context,
            listen: false,
          );
          await songProvider.loadSongs();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Chanson modifiée avec succès'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        } else {
          throw Exception('Failed to update song in database');
        }
      } else {
        // Create new song
        final song = Song.create(
          title: _titleController.text.trim(),
          artist: _artistController.text.trim(),
          key: _keyController.text.trim(),
          timeSignature: _timeSignatureController.text.trim(),
          tempo: int.tryParse(_tempoController.text) ?? 120,
          style: null,
          notationType: _selectedNotationType,
        ).copyWith(sections: sections);

        if (!song.validate()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Données de chanson invalides'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final songId = await databaseHelper.insertSong(song);

        if (songId != null) {
          final songProvider = Provider.of<SongProvider>(
            context,
            listen: false,
          );
          await songProvider.loadSongs();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Chanson créée avec succès'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        } else {
          throw Exception('Failed to save song to database');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Add a new section
  void _addSection() {
    final sectionNames = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    final usedNames = _sections.map((s) => s.name).toSet();
    final nextName = sectionNames.firstWhere(
      (name) => !usedNames.contains(name),
      orElse: () => 'Section ${_sections.length + 1}',
    );

    setState(() {
      _sections.add(
        SongSection(
          name: nextName,
          measures: [
            SongMeasure(chords: ['I', 'V', 'VI', 'IV']),
          ],
        ),
      );
    });
  }

  /// Delete a section
  void _deleteSection(int index) {
    setState(() {
      _sections.removeAt(index);
    });
  }

  /// Add a measure to a section
  void _addMeasure(int sectionIndex) {
    setState(() {
      _sections[sectionIndex].measures.add(
        SongMeasure(chords: ['I', 'V', 'VI', 'IV']),
      );
    });
  }

  /// Delete a measure from a section
  void _deleteMeasure(int sectionIndex, int measureIndex) {
    setState(() {
      if (_sections[sectionIndex].measures.length > 1) {
        _sections[sectionIndex].measures.removeAt(measureIndex);
      }
    });
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
          widget.song != null ? 'Modifier la chanson' : 'Créer une chanson',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            color: Colors.orange,
            onPressed: _isSaving ? null : _saveSong,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              Text(
                'Titre *',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Entrez le titre de la chanson',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le titre est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Champ artiste
              Text(
                'Artiste *',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _artistController,
                decoration: const InputDecoration(
                  hintText: 'Entrez le nom de l\'artiste',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom de l\'artiste est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Ligne Ton et Tempo
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ton',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _keyController,
                          decoration: const InputDecoration(
                            hintText: 'C',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tempo (BPM)',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _tempoController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '120',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Time Signature
              Text(
                'Signature rythmique',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _timeSignatureController,
                decoration: const InputDecoration(
                  hintText: '4/4',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Song Structure section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Structure',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addSection,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter une section'),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sections list
              ..._sections.asMap().entries.map((entry) {
                final sectionIndex = entry.key;
                final section = entry.value;
                return _buildSectionCard(sectionIndex, section);
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a section card with measures
  Widget _buildSectionCard(int sectionIndex, SongSection section) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    section.name,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red.shade400,
                  onPressed: () => _deleteSection(sectionIndex),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Measures
            ...section.measures.asMap().entries.map((measureEntry) {
              final measureIndex = measureEntry.key;
              final measure = measureEntry.value;
              return _buildMeasureRow(sectionIndex, measureIndex, measure);
            }).toList(),

            // Add measure button
            TextButton.icon(
              onPressed: () => _addMeasure(sectionIndex),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter une mesure'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a measure row with chord inputs
  Widget _buildMeasureRow(
    int sectionIndex,
    int measureIndex,
    SongMeasure measure,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mesure ${measureIndex + 1}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.red.shade400,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _deleteMeasure(sectionIndex, measureIndex),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: measure.chords.asMap().entries.map((chordEntry) {
              final chordIndex = chordEntry.key;
              final chord = chordEntry.value;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextField(
                    controller: TextEditingController(text: chord),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                    ),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _sections[sectionIndex]
                                .measures[measureIndex]
                                .chords[chordIndex] =
                            value;
                      });
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Model for a song section
class SongSection {
  String name;
  List<SongMeasure> measures;

  SongSection({required this.name, required this.measures});
}

/// Model for a measure
class SongMeasure {
  List<String> chords;

  SongMeasure({required this.chords});
}
