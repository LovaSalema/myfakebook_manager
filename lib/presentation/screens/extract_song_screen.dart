import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../providers/theme_provider.dart';
import '../providers/song_provider.dart';
import '../providers/extraction_song_provider.dart';
import '../../data/services/chord_extraction_service.dart';

class ExtractSongScreen extends StatefulWidget {
  const ExtractSongScreen({super.key});

  @override
  State<ExtractSongScreen> createState() => _ExtractSongScreenState();
}

class _ExtractSongScreenState extends State<ExtractSongScreen> {
  final TextEditingController _urlController = TextEditingController();
  String? _selectedFilePath;
  bool _isExtracting = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
      });
    }
  }

  Future<void> _extractChordsFromFile() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isExtracting = true;
    });

    // Get the global provider instance
    final songProvider = Provider.of<ExtractionSongProvider>(
      context,
      listen: false,
    );

    try {
      final service = ChordExtractionService();

      final audioFile = File(_selectedFilePath!);

      // Show progress for API calls
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Extraction des accords en cours... Cela peut prendre jusqu\'à 1 minute',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      final apiData = await service.extractChordsAndBeats(audioFile);

      final fileName = _selectedFilePath!.split('/').last;
      final song = service.createSongFromApiData(apiData, fileName);

      // Debug: print song details
      print(
        'Song created: title=${song.title}, artist=${song.artist}, key=${song.key}, timeSig=${song.timeSignature}, tempo=${song.tempo}',
      );
      print('Sections count: ${song.sections.length}');
      for (var section in song.sections) {
        print(
          'Section: type=${section.sectionType}, label=${section.sectionLabel}, measures=${section.measures.length}',
        );
        for (var measure in section.measures) {
          print(
            'Measure: order=${measure.measureOrder}, chords=${measure.chords}',
          );
        }
      }

      // Validate song before saving
      print('Validating song...');
      if (!song.validate()) {
        print('Song validation failed');
        // Check sections
        for (var section in song.sections) {
          print('Section validation: ${section.validate()}');
          if (!section.validate()) {
            print('Section failed: measures=${section.measures.length}');
            for (var measure in section.measures) {
              print(
                'Measure validation: ${measure.validate()}, chords=${measure.chords}',
              );
            }
          }
        }
        throw Exception('Données de chanson invalides');
      }
      print('Song validation passed');

      final success = await songProvider.addSong(song);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Chanson extraite avec succès depuis fichier audio',
              ),
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Échec de l\'enregistrement de la chanson');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'extraction: $e'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExtracting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark
            ? Color(AppColors.backgroundDark)
            : Color(AppColors.backgroundLight),
        appBar: AppBar(
          backgroundColor: isDark
              ? Color(AppColors.backgroundDark)
              : Color(AppColors.backgroundLight),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Extraire les accords',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'URL'),
              Tab(text: 'Fichier'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // URL Tab
            _buildUrlTab(),
            // File Tab
            _buildFileTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlTab() {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coller l\'URL de la chanson',
            style: AppTextStyles.headlineSmall,
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: 'https://...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              prefixIcon: const Icon(Icons.link),
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement URL extraction logic
              if (_urlController.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chanson extraite avec succès depuis URL'),
                  ),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Extraire les accords'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTab() {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Sélectionner un fichier audio',
            style: AppTextStyles.headlineSmall,
          ),
          SizedBox(height: 16.h),
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.audio_file,
                    size: 48.sp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    _selectedFilePath != null
                        ? 'Fichier sélectionné: ${_selectedFilePath!.split('/').last}'
                        : 'Aucun fichier sélectionné',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: _pickAudioFile,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Choisir un fichier MP3'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: (_selectedFilePath != null && !_isExtracting)
                  ? _extractChordsFromFile
                  : null,
              child: _isExtracting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Extraire les accords'),
            ),
          ),
        ],
      ),
    );
  }
}
