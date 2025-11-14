import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

class CloudConvertService {
  static String get apiKey => AppConstants.cloudConvertApiKey;

  static Future<String?> convertAudio({
    required File inputFile,
    required String filename,
  }) async {
    try {
      // 1. Créer la tâche avec upload
      final response = await http.post(
        Uri.parse('https://api.cloudconvert.com/v2/jobs'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'tasks': {
            'import-file': {'operation': 'import/upload'},
            'convert-audio': {
              'operation': 'convert',
              'input': ['import-file'],
              'output_format': 'mp3',
              'audio_codec': 'mp3',
              'audio_bitrate': 128,
            },
            'export-file': {
              'operation': 'export/url',
              'input': ['convert-audio'],
            },
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create job: ${response.body}');
      }

      final data = json.decode(response.body);
      final jobId = data['data']['id'];

      // 2. Upload the file
      final uploadUrl =
          data['data']['tasks'][0]['result']['files'][0]['upload_url'];
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': 'application/octet-stream'},
        body: inputFile.readAsBytesSync(),
      );

      if (uploadResponse.statusCode != 201) {
        throw Exception('Failed to upload file: ${uploadResponse.body}');
      }

      // 3. Wait for conversion to complete
      String? downloadUrl;
      int attempts = 0;
      const maxAttempts = 30; // 5 minutes max

      while (attempts < maxAttempts) {
        await Future.delayed(const Duration(seconds: 10));
        attempts++;

        final statusResponse = await http.get(
          Uri.parse('https://api.cloudconvert.com/v2/jobs/$jobId'),
          headers: {'Authorization': 'Bearer $apiKey'},
        );

        if (statusResponse.statusCode == 200) {
          final statusData = json.decode(statusResponse.body);
          final jobStatus = statusData['data']['status'];

          if (jobStatus == 'finished') {
            // Find the export task
            final tasks = statusData['data']['tasks'] as List;
            for (var task in tasks) {
              if (task['operation'] == 'export/url' &&
                  task['status'] == 'finished') {
                downloadUrl = task['result']['files'][0]['url'];
                break;
              }
            }
            break;
          } else if (jobStatus == 'error') {
            throw Exception(
              'Conversion failed: ${statusData['data']['message']}',
            );
          }
        }
      }

      if (downloadUrl == null) {
        throw Exception('Conversion timed out');
      }

      return downloadUrl;
    } catch (e) {
      print('Erreur CloudConvert: $e');
      return null;
    }
  }
}
