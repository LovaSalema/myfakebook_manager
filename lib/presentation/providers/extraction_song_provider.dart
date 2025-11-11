import '../../data/services/extraction_database_helper.dart';
import 'song_provider.dart';

/// SongProvider specifically for extracted songs using separate database
class ExtractionSongProvider extends SongProvider {
  ExtractionSongProvider() : super(ExtractionDatabaseHelper());
}
