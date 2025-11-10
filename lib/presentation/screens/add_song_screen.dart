import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/song.dart';
import '../../data/models/section.dart';
import '../../data/models/measure.dart';
import '../../data/services/database_helper.dart';
import '../providers/song_provider.dart';
import '../providers/repertoire_provider.dart';
import '../providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';

/// Screen for adding or editing a song
class AddSongScreen extends StatefulWidget {
  final Song? song;
  final int? repertoireId;

  const AddSongScreen({super.key, this.song, this.repertoireId});

  @override
  State<AddSongScreen> createState() => _AddSongScreenState();
}

class _AddSongScreenState extends State<AddSongScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController();
  late final _artistController = TextEditingController();
  double _tempoValue = 120.0;
  late final _timeSignatureController = TextEditingController(text: '4/4');

  // Musical keys for dropdown
  final List<String> _musicalKeys = [
    'C',
    'C#',
    'D',
    'Eb',
    'E',
    'F',
    'F#',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];
  String _selectedKey = 'C';

  bool _isSaving = false;
  String _selectedNotationType = 'ROMAN_NUMERALS';

  // Song structure data
  List<SongSection> _sections = [
    SongSection(
      name: 'A',
      sectionType: 'VERSE',
      measures: [
        SongMeasure(chords: ['I', 'V', 'VI', 'IV']),
      ],
    ),
  ];

  // Map to hold text controllers for each measure
  final Map<String, TextEditingController> _measureControllers = {};

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
      _selectedKey = song.key;
      _tempoValue = song.tempo?.toDouble() ?? 120.0;
      _timeSignatureController.text = song.timeSignature;
      _selectedNotationType = song.notationType;

      // Load song structure sections and measures if they exist
      if (song.sections.isNotEmpty) {
        _sections = song.sections.map((section) {
          return SongSection(
            name: section.sectionLabel,
            sectionType:
                section.sectionType, // Preserve the original section type
            measures: section.measures.map((measure) {
              // Store chords as individual items for the single input field
              return SongMeasure(chords: measure.chords);
            }).toList(),
          );
        }).toList();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _timeSignatureController.dispose();

    // Dispose all measure controllers
    for (final controller in _measureControllers.values) {
      controller.dispose();
    }
    _measureControllers.clear();

    super.dispose();
  }

  /// Save the song to database (create or update)
  Future<void> _saveSong() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate song structure before saving
    if (!_validateSongStructure()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final databaseHelper = DatabaseHelper();

      if (widget.song != null) {
        // Update existing song with data integrity checks
        await _updateExistingSong(databaseHelper);
      } else {
        // Create new song with validation
        await _createNewSong(databaseHelper);
      }
    } catch (e) {
      _handleSaveError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Validate song structure before saving
  bool _validateSongStructure() {
    // Ensure at least one section exists
    if (_sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ La chanson doit avoir au moins une section'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Ensure each section has at least one measure
    for (int i = 0; i < _sections.length; i++) {
      final section = _sections[i];
      if (section.measures.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ La section ${section.name} doit avoir au moins une mesure',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      // Validate each measure has valid chords
      for (int j = 0; j < section.measures.length; j++) {
        final measure = section.measures[j];
        if (measure.chords.isEmpty ||
            measure.chords.every((chord) => chord.trim().isEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '❌ La mesure ${j + 1} de la section ${section.name} doit contenir au moins un accord valide',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
      }
    }

    return true;
  }

  /// Convert local sections to database format with error handling
  List<Section> _convertSectionsToDatabaseFormat({int? songId}) {
    try {
      return _sections.asMap().entries.map((entry) {
        final sectionIndex = entry.key;
        final section = entry.value;

        // Create measures with actual chord data from local model
        final measures = section.measures.asMap().entries.map((measureEntry) {
          final measureIndex = measureEntry.key;
          final measure = measureEntry.value;

          // Ensure chords are not null and handle empty chords
          final chords = measure.chords
              .where((chord) => chord.trim().isNotEmpty)
              .toList();
          if (chords.isEmpty) {
            chords.add(''); // Ensure at least one chord slot exists
          }

          return Measure(
            id: null, // Will be set by database
            sectionId: 0, // Will be set after section creation
            measureOrder: measureIndex,
            timeSignature: _timeSignatureController.text.trim(),
            chords: chords,
            specialSymbol: null,
            hasFirstEnding: false,
            hasSecondEnding: false,
          );
        }).toList();

        // Create section with proper measures
        return Section(
          id: null, // Will be set by database
          songId: songId ?? 0, // Use provided songId or 0 for new songs
          sectionType: section.sectionType,
          sectionLabel: section.name,
          sectionName: section.name,
          sectionOrder: sectionIndex,
          measures: measures,
          repeatCount: 1,
          hasRepeatSign: false,
        );
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la conversion des sections: $e');
    }
  }

  /// Update existing song with transaction safety
  Future<void> _updateExistingSong(DatabaseHelper databaseHelper) async {
    // Convert sections with the actual song ID
    final sections = _convertSectionsToDatabaseFormat(songId: widget.song!.id);

    final updatedSong = widget.song!.copyWith(
      title: _titleController.text.trim(),
      artist: _artistController.text.trim(),
      key: _selectedKey,
      timeSignature: _timeSignatureController.text.trim(),
      tempo: _tempoValue.toInt(),
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
      final songProvider = Provider.of<SongProvider>(context, listen: false);
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
      throw Exception(
        'Échec de la mise à jour de la chanson dans la base de données',
      );
    }
  }

  /// Create new song with validation
  Future<void> _createNewSong(DatabaseHelper databaseHelper) async {
    // Convert sections with songId=0 for new song
    final sections = _convertSectionsToDatabaseFormat();

    final song = Song.create(
      title: _titleController.text.trim(),
      artist: _artistController.text.trim(),
      key: _selectedKey,
      timeSignature: _timeSignatureController.text.trim(),
      tempo: _tempoValue.toInt(),
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
      final songProvider = Provider.of<SongProvider>(context, listen: false);
      await songProvider.loadSongs();

      // If repertoireId is provided, add the song to the repertoire
      if (widget.repertoireId != null) {
        final repertoireProvider = Provider.of<RepertoireProvider>(
          context,
          listen: false,
        );
        await repertoireProvider.addSongsToRepertoire(widget.repertoireId!, [
          songId,
        ]);
      }

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
      throw Exception(
        'Échec de la sauvegarde de la chanson dans la base de données',
      );
    }
  }

  /// Handle save errors with user-friendly messages
  void _handleSaveError(dynamic error) {
    if (mounted) {
      String errorMessage = 'Erreur inconnue';

      if (error is DatabaseException) {
        errorMessage = 'Erreur de base de données: ${error.message}';
      } else if (error is Exception) {
        errorMessage = 'Erreur: ${error.toString()}';
      } else if (error is String) {
        errorMessage = error;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
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
          sectionType: 'VERSE',
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

  /// Get or create a controller for a specific measure
  TextEditingController _getMeasureController(
    int sectionIndex,
    int measureIndex,
  ) {
    final key = '$sectionIndex-$measureIndex';
    final measure = _sections[sectionIndex].measures[measureIndex];
    final currentChordText = measure.chords.join(' ');

    if (!_measureControllers.containsKey(key)) {
      _measureControllers[key] = TextEditingController(text: currentChordText);
    } else {
      // Always update the controller's text to match the current chords
      if (_measureControllers[key]!.text != currentChordText) {
        _measureControllers[key]!.text = currentChordText;
      }
    }
    return _measureControllers[key]!;
  }

  /// Parse chord text into individual chords
  List<String> _parseChords(String chordText) {
    if (chordText.trim().isEmpty) return [''];
    return chordText
        .split(' ')
        .map((chord) => chord.trim())
        .where((chord) => chord.isNotEmpty)
        .toList();
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
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.song != null ? 'Modifier la chanson' : 'Créer une chanson',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
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

              // Ton
              Text(
                'Ton',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedKey,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: _musicalKeys.map((String key) {
                  return DropdownMenuItem<String>(value: key, child: Text(key));
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedKey = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner une tonalité';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tempo (BPM)
              Text(
                'Tempo (BPM)',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  Slider(
                    value: _tempoValue,
                    min: 20,
                    max: 300,
                    divisions: 280,
                    label: '${_tempoValue.toInt()} BPM',
                    onChanged: (value) {
                      setState(() {
                        _tempoValue = value;
                      });
                    },
                  ),
                  Text(
                    '${_tempoValue.toInt()} BPM',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
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

  /// Build a measure row with a single chord input field
  Widget _buildMeasureRow(
    int sectionIndex,
    int measureIndex,
    SongMeasure measure,
  ) {
    final controller = _getMeasureController(sectionIndex, measureIndex);

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
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText:
                  'Entrez les accords séparés par des espaces (ex: I V VI IV)',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
            ),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
            onChanged: (value) {
              // Update the chords without triggering rebuild
              final parsedChords = _parseChords(value);
              _sections[sectionIndex].measures[measureIndex].chords =
                  parsedChords;
            },
          ),
        ],
      ),
    );
  }
}

/// Model for a song section
class SongSection {
  String name;
  String sectionType;
  List<SongMeasure> measures;

  SongSection({
    required this.name,
    this.sectionType = 'VERSE',
    required this.measures,
  });
}

/// Model for a measure
class SongMeasure {
  List<String> chords;

  SongMeasure({required this.chords});
}
