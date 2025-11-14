import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
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
  bool _isProcessingUrl = false;

  @override
  void initState() {
    super.initState();
    // Add listener to URL controller to update button state
    _urlController.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    // Force rebuild to update button enabled state
    setState(() {});
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

  Future<void> _extractChordsFromUrl() async {
    print(
      'DEBUG: _extractChordsFromUrl called with URL: "${_urlController.text}"',
    );
    if (_urlController.text.isEmpty) {
      print('DEBUG: URL is empty, returning');
      return;
    }

    setState(() {
      _isProcessingUrl = true;
    });

    try {
      // Get temporary directory for storing the MP3
      final tempDir = await getTemporaryDirectory();
      final tempMp3Path = '${tempDir.path}/youtube_audio.mp3';
      print('DEBUG: Temp MP3 path: $tempMp3Path');

      // Show progress
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Téléchargement de la vidéo YouTube...'),
            duration: Duration(seconds: 5),
          ),
        );
      }

      // Download YouTube audio
      await _downloadYouTubeAudio(_urlController.text, tempMp3Path);

      // Use existing chord extraction logic
      await _extractChordsFromTempFile(tempMp3Path, 'youtube_song.mp3');
    } catch (e) {
      print('DEBUG: Error in _extractChordsFromUrl: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du traitement YouTube: $e'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingUrl = false;
        });
      }
    }
  }

  Future<void> _downloadYouTubeAudio(String url, String outputPath) async {
    print('DEBUG: _downloadYouTubeAudio called with URL: $url');
    final yt = YoutubeExplode();

    try {
      // Extract video ID from URL
      final videoId = _extractVideoId(url);
      print('DEBUG: Extracted video ID: $videoId');
      if (videoId == null) {
        throw Exception('URL YouTube invalide');
      }

      // Get video info
      final video = await yt.videos.get(videoId);
      print('Téléchargement de: ${video.title}');

      // Get the best audio stream with retry logic
      StreamManifest? manifest;
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          manifest = await yt.videos.streamsClient
              .getManifest(videoId)
              .timeout(const Duration(seconds: 120));
          break; // Success, exit retry loop
        } on TimeoutException {
          retryCount++;
          if (retryCount >= maxRetries) {
            throw Exception(
              'Timeout lors de la récupération des informations vidéo après $maxRetries tentatives',
            );
          }
          print('DEBUG: Timeout, retrying... ($retryCount/$maxRetries)');
          await Future.delayed(const Duration(seconds: 2)); // Wait before retry
        }
      }

      if (manifest == null) {
        throw Exception('Impossible de récupérer les informations vidéo');
      }
      final audioStream = manifest.audioOnly.withHighestBitrate();
      print('DEBUG: Audio stream bitrate: ${audioStream.bitrate}');

      // Download audio stream with progress tracking
      print('DEBUG: Downloading to: $outputPath');
      final stream = yt.videos.streamsClient.get(audioStream);

      final file = File(outputPath);
      final output = file.openWrite();

      int downloadedBytes = 0;
      final totalBytes = audioStream.size.totalBytes;

      await for (final data in stream) {
        output.add(data);
        downloadedBytes += data.length;

        // Show progress
        if (totalBytes != null) {
          final progress = (downloadedBytes / totalBytes) * 100;
          print('DEBUG: Download progress: ${progress.toStringAsFixed(1)}%');
        }
      }

      await output.flush();
      await output.close();

      final fileSize = await file.length();
      print('DEBUG: Download completed, file size: $fileSize bytes');
      print('Téléchargement audio terminé: $outputPath');
    } on TimeoutException {
      throw Exception('Timeout lors de la récupération des informations vidéo');
    } catch (e, stackTrace) {
      print('ERROR: Download failed: $e');
      print('STACK: $stackTrace');
      rethrow;
    } finally {
      yt.close();
    }
  }

  static String? _extractVideoId(String url) {
    print('DEBUG: _extractVideoId called with URL: $url');
    // Handle various YouTube URL formats
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    );
    final match = regExp.firstMatch(url);
    final videoId = match?.group(1);
    print('DEBUG: Extracted video ID: $videoId');
    return videoId;
  }

  Future<void> _extractChordsFromTempFile(
    String filePath,
    String fileName,
  ) async {
    // Get the global provider instance
    final songProvider = Provider.of<ExtractionSongProvider>(
      context,
      listen: false,
    );

    try {
      final service = ChordExtractionService();

      final audioFile = File(filePath);

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
              content: Text('Chanson extraite avec succès depuis YouTube'),
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Échec de l\'enregistrement de la chanson');
      }

      // Clean up temp MP3 file
      await audioFile.delete();
    } catch (e) {
      // Clean up temp file on error
      try {
        await File(filePath).delete();
      } catch (_) {}
      rethrow;
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
            onPressed: (_urlController.text.isNotEmpty && !_isProcessingUrl)
                ? () {
                    print(
                      'DEBUG: Button pressed, URL: "${_urlController.text}", isProcessingUrl: $_isProcessingUrl',
                    );
                    _extractChordsFromUrl();
                  }
                : null,
            child: _isProcessingUrl
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Extraire les accords'),
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
