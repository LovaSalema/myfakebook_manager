import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../providers/theme_provider.dart';

class ExtractSongScreen extends StatefulWidget {
  const ExtractSongScreen({super.key});

  @override
  State<ExtractSongScreen> createState() => _ExtractSongScreenState();
}

class _ExtractSongScreenState extends State<ExtractSongScreen> {
  final TextEditingController _urlController = TextEditingController();
  String? _selectedFilePath;

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
        crossAxisAlignment: CrossAxisAlignment.start,
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
              onPressed: _selectedFilePath != null
                  ? () {
                      // TODO: Implement audio file extraction logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Chanson extraite avec succès depuis fichier audio',
                          ),
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  : null,
              child: const Text('Extraire les accords'),
            ),
          ),
        ],
      ),
    );
  }
}
