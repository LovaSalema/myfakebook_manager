import '../models/song.dart';
import '../models/section.dart';
import '../models/measure.dart';
import '../models/structure.dart';
import '../models/repertoire.dart';
import '../models/repertoire_song.dart';
import 'database_helper.dart';

/// Service pour générer des données de test pour l'application
class TestDataService {
  /// Génère des chansons d'exemple avec des structures musicales complètes
  static List<Song> generateSampleSongs() {
    return [
      _createAutumnLeaves(),
      _createBlueBossa(),
      _createAllOfMe(),
      _createTakeTheATrain(),
    ];
  }

  /// Génère des répertoires d'exemple
  static List<Repertoire> generateSampleRepertoires() {
    return [
      Repertoire(
        id: null,
        name: 'Jazz Standards',
        description: 'Les standards de jazz classiques',
        coverColor: '#8B4513',
        icon: 'music_note',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Repertoire(
        id: null,
        name: 'Répertoire Gigs',
        description: 'Pour les concerts réguliers',
        coverColor: '#2E8B57',
        icon: 'star',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Repertoire(
        id: null,
        name: 'Étude personnelle',
        description: 'Chansons en cours d\'apprentissage',
        coverColor: '#4169E1',
        icon: 'school',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  /// Génère des associations chanson-répertoire
  static List<RepertoireSong> generateSampleRepertoireSongs() {
    final now = DateTime.now();
    return [
      RepertoireSong(repertoireId: 1, songId: 1, orderIndex: 0, addedAt: now),
      RepertoireSong(repertoireId: 1, songId: 2, orderIndex: 1, addedAt: now),
      RepertoireSong(repertoireId: 1, songId: 3, orderIndex: 2, addedAt: now),
      RepertoireSong(repertoireId: 2, songId: 1, orderIndex: 0, addedAt: now),
      RepertoireSong(repertoireId: 2, songId: 4, orderIndex: 1, addedAt: now),
      RepertoireSong(repertoireId: 3, songId: 2, orderIndex: 0, addedAt: now),
    ];
  }

  /// Crée "Autumn Leaves" - standard de jazz
  static Song _createAutumnLeaves() {
    return Song(
      id: null,
      title: 'Autumn Leaves',
      artist: 'Joseph Kosma',
      key: 'Gm',
      timeSignature: '4/4',
      tempo: 120,
      style: 'Jazz Ballad',
      isFavorite: true,
      notationType: 'Standard',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      structure: Structure(
        songId: 1,
        pattern: 'A A B A',
        description: 'Forme AABA classique',
      ),
      sections: [
        Section(
          id: null,
          songId: 1,
          sectionType: 'verse',
          sectionLabel: 'A',
          sectionOrder: 1,
          measures: [
            Measure(
              id: null,
              sectionId: 1,
              measureOrder: 1,
              timeSignature: '4/4',
              chords: ['Cm7', 'F7', 'Bbmaj7', 'Ebmaj7'],
            ),
            Measure(
              id: null,
              sectionId: 1,
              measureOrder: 2,
              timeSignature: '4/4',
              chords: ['Am7b5', 'D7', 'Gm', 'Gm'],
            ),
          ],
        ),
        Section(
          id: null,
          songId: 1,
          sectionType: 'verse',
          sectionLabel: 'A',
          sectionOrder: 2,
          measures: [
            Measure(
              id: null,
              sectionId: 2,
              measureOrder: 1,
              timeSignature: '4/4',
              chords: ['Cm7', 'F7', 'Bbmaj7', 'Ebmaj7'],
            ),
            Measure(
              id: null,
              sectionId: 2,
              measureOrder: 2,
              timeSignature: '4/4',
              chords: ['Am7b5', 'D7', 'Gm', 'Gm'],
            ),
          ],
        ),
        Section(
          id: null,
          songId: 1,
          sectionType: 'bridge',
          sectionLabel: 'B',
          sectionOrder: 3,
          measures: [
            Measure(
              id: null,
              sectionId: 3,
              measureOrder: 1,
              timeSignature: '4/4',
              chords: ['C7', 'C7', 'F7', 'F7'],
            ),
            Measure(
              id: null,
              sectionId: 3,
              measureOrder: 2,
              timeSignature: '4/4',
              chords: ['Bbmaj7', 'Am7', 'D7', 'D7'],
            ),
          ],
        ),
        Section(
          id: null,
          songId: 1,
          sectionType: 'verse',
          sectionLabel: 'A',
          sectionOrder: 4,
          measures: [
            Measure(
              id: null,
              sectionId: 4,
              measureOrder: 1,
              timeSignature: '4/4',
              chords: ['Cm7', 'F7', 'Bbmaj7', 'Ebmaj7'],
            ),
            Measure(
              id: null,
              sectionId: 4,
              measureOrder: 2,
              timeSignature: '4/4',
              chords: ['Am7b5', 'D7', 'Gm', 'Gm'],
            ),
          ],
        ),
      ],
    );
  }

  /// Crée "Blue Bossa" - standard de bossa nova
  static Song _createBlueBossa() {
    return Song(
      id: null,
      title: 'Blue Bossa',
      artist: 'Kenny Dorham',
      key: 'Cm',
      timeSignature: '4/4',
      tempo: 132,
      style: 'Bossa Nova',
      isFavorite: false,
      notationType: 'Standard',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      structure: Structure(
        songId: 2,
        pattern: 'A A B A',
        description: 'Forme AABA avec section B modulante',
      ),
      sections: [
        Section(
          id: null,
          songId: 2,
          sectionType: 'verse',
          sectionLabel: 'A',
          sectionOrder: 1,
          measures: [
            Measure(
              id: null,
              sectionId: 5,
              measureOrder: 1,
              timeSignature: '4/4',
              chords: ['Cm7', 'Fm7', 'Dm7b5', 'G7'],
            ),
            Measure(
              id: null,
              sectionId: 5,
              measureOrder: 2,
              timeSignature: '4/4',
              chords: ['Cm7', 'Fm7', 'Dm7b5', 'G7'],
            ),
          ],
        ),
        Section(
          id: null,
          songId: 2,
          sectionType: 'verse',
          sectionLabel: 'A',
          sectionOrder: 2,
          measures: [
            Measure(
              id: null,
              sectionId: 6,
              measureOrder: 1,
              timeSignature: '4/4',
              chords: ['Cm7', 'Fm7', 'Dm7b5', 'G7'],
            ),
            Measure(
              id: null,
              sectionId: 6,
              measureOrder: 2,
              timeSignature: '4/4',
              chords: ['Cm7', 'Fm7', 'Dm7b5', 'G7'],
            ),
          ],
        ),
        Section(
          id: null,
          songId: 2,
          sectionType: 'bridge',
          sectionLabel: 'B',
          sectionOrder: 3,
          measures: [
            Measure(
              id: null,
              sectionId: 7,
              measureOrder: 1,
              timeSignature: '4/4',
              chords: ['Ebm7', 'Ab7', 'Dbmaj7', 'Dbmaj7'],
            ),
            Measure(
              id: null,
              sectionId: 7,
              measureOrder: 2,
              timeSignature: '4/4',
              chords: ['Dm7b5', 'G7', 'Cm7', 'Cm7'],
            ),
          ],
        ),
        Section(
          id: null,
          songId: 2,
          sectionType: 'verse',
          sectionLabel: 'A',
          sectionOrder: 4,
          measures: [
            Measure(
              id: null,
              sectionId: 8,
              measureOrder: 1,
              timeSignature: '4/4',
              chords: ['Cm7', 'Fm7', 'Dm7b5', 'G7'],
            ),
            Measure(
              id: null,
              sectionId: 8,
              measureOrder: 2,
              timeSignature: '4/4',
              chords: ['Cm7', 'Fm7', 'Dm7b5', 'G7'],
            ),
          ],
        ),
      ],
    );
  }

  /// Crée "All of Me" - standard populaire
  static Song _createAllOfMe() {
    return Song(
      id: null,
      title: 'All of Me',
      artist: 'Gerald Marks',
      key: 'C',
      timeSignature: '4/4',
      tempo: 112,
      style: 'Swing',
      isFavorite: true,
      notationType: 'Standard',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      structure: Structure(
        songId: 3,
        pattern: 'A B A C',
        description: 'Forme ABAC avec pont',
      ),
      sections: [
        Section(
          id: null,
          songId: 3,
          sectionType: 'verse',
          sectionLabel: 'A',
          sectionOrder: 1,
          measures: [
            Measure(
              id: null,
              sectionId: 9,
              measureOrder: 1,
              timeSignature: '4/4',
              chords: ['C', 'E7', 'A7', 'Dm7'],
            ),
            Measure(
              id: null,
              sectionId: 9,
              measureOrder: 2,
              timeSignature: '4/4',
              chords: ['G7', 'G7', 'C', 'C'],
            ),
          ],
        ),
        Section(
          id: null,
          songId: 3,
          sectionType: 'chorus',
          sectionLabel: 'B',
          sectionOrder: 2,
          measures: [
            Measure(
              id: null,
              sectionId: 10,
              measureOrder: 1,
              timeSignature: '4/4',
              chords: ['C7', 'C7', 'F', 'F'],
            ),
            Measure(
              id: null,
              sectionId: 10,
              measureOrder: 2,
              timeSignature: '4/4',
              chords: ['Fm', 'Fm', 'C', 'A7'],
            ),
          ],
        ),
        Section(
          id: null,
          songId: 3,
          sectionType: 'verse',
          sectionLabel: 'A',
          sectionOrder: 3,
          measures: [
            Measure(
              id: null,
              sectionId: 11,
              measureOrder: 1,
              timeSignature: '4/4',
              chords: ['Dm7', 'G7', 'C', 'E7'],
            ),
            Measure(
              id: null,
              sectionId: 11,
              measureOrder: 2,
              timeSignature: '4/4',
              chords: ['A7', 'Dm7', 'G7', 'G7'],
            ),
          ],
        ),
        Section(
          id: null,
          songId: 3,
          sectionType: 'outro',
          sectionLabel: 'C',
          sectionOrder: 4,
          measures: [
            Measure(
              id: null,
              sectionId: 12,
              measureOrder: 1,
              timeSignature: '4/4',
              chords: ['C', 'A7', 'Dm7', 'G7'],
            ),
            Measure(
              id: null,
              sectionId: 12,
              measureOrder: 2,
              timeSignature: '4/4',
              chords: ['C', 'C', 'C', 'C'],
            ),
          ],
        ),
      ],
    );
  }

  /// Crée "Take the 'A' Train" - standard de big band
  static Song _createTakeTheATrain() {
    return Song(
      id: null,
      title: 'Take the \'A\' Train',
      artist: 'Billy Strayhorn',
      key: 'C',
      timeSignature: '4/4',
      tempo: 140,
      style: 'Swing',
      isFavorite: false,
      notationType: 'Standard',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      structure: Structure(
        songId: 4,
        pattern: 'A A B A',
        description: 'Forme AABA avec intro',
      ),
      sections: [
        Section(
          id: null,
          songId: 4,
          sectionType: 'intro',
          sectionLabel: 'Intro',
          sectionOrder: 0,
          measures: [
            Measure(
              id: null,
              sectionId: 13,
              measureOrder: 1,
              timeSignature: '4/4',
              chords: ['C6', 'C6', 'C6', 'C6'],
            ),
          ],
        ),
        Section(
          id: null,
          songId: 4,
          sectionType: 'verse',
          sectionLabel: 'A',
          sectionOrder: 1,
          measures: [
            Measure(
              id: null,
              sectionId: 14,
              measureOrder: 1,
              timeSignature: '4/4',
              chords: ['C', 'C', 'C', 'C'],
            ),
            Measure(
              id: null,
              sectionId: 14,
              measureOrder: 2,
              timeSignature: '4/4',
              chords: ['C', 'C', 'C', 'C'],
            ),
            Measure(
              id: null,
              sectionId: 14,
              measureOrder: 3,
              timeSignature: '4/4',
              chords: ['D7', 'D7', 'D7', 'D7'],
            ),
            Measure(
              id: null,
              sectionId: 14,
              measureOrder: 4,
              timeSignature: '4/4',
              chords: ['D7', 'D7', 'D7', 'D7'],
            ),
          ],
        ),
        Section(
          id: null,
          songId: 4,
          sectionType: 'verse',
          sectionLabel: 'A',
          sectionOrder: 2,
          measures: [
            Measure(
              id: null,
              sectionId: 15,
              measureOrder: 1,
              timeSignature: '4/4',
              chords: ['C', 'C', 'C', 'C'],
            ),
            Measure(
              id: null,
              sectionId: 15,
              measureOrder: 2,
              timeSignature: '4/4',
              chords: ['C', 'C', 'C', 'C'],
            ),
            Measure(
              id: null,
              sectionId: 15,
              measureOrder: 3,
              timeSignature: '4/4',
              chords: ['D7', 'D7', 'D7', 'D7'],
            ),
            Measure(
              id: null,
              sectionId: 15,
              measureOrder: 4,
              timeSignature: '4/4',
              chords: ['D7', 'D7', 'D7', 'D7'],
            ),
          ],
        ),
        Section(
          id: null,
          songId: 4,
          sectionType: 'bridge',
          sectionLabel: 'B',
          sectionOrder: 3,
          measures: [
            Measure(
              id: null,
              sectionId: 16,
              measureOrder: 1,
              timeSignature: '4/4',
              chords: ['Dm7', 'Dm7', 'G7', 'G7'],
            ),
            Measure(
              id: null,
              sectionId: 16,
              measureOrder: 2,
              timeSignature: '4/4',
              chords: ['Dm7', 'Dm7', 'G7', 'G7'],
            ),
            Measure(
              id: null,
              sectionId: 16,
              measureOrder: 3,
              timeSignature: '4/4',
              chords: ['Em7', 'Em7', 'A7', 'A7'],
            ),
            Measure(
              id: null,
              sectionId: 16,
              measureOrder: 4,
              timeSignature: '4/4',
              chords: ['Em7', 'Em7', 'A7', 'A7'],
            ),
          ],
        ),
        Section(
          id: null,
          songId: 4,
          sectionType: 'verse',
          sectionLabel: 'A',
          sectionOrder: 4,
          measures: [
            Measure(
              id: null,
              sectionId: 17,
              measureOrder: 1,
              timeSignature: '4/4',
              chords: ['C', 'C', 'C', 'C'],
            ),
            Measure(
              id: null,
              sectionId: 17,
              measureOrder: 2,
              timeSignature: '4/4',
              chords: ['C', 'C', 'C', 'C'],
            ),
            Measure(
              id: null,
              sectionId: 17,
              measureOrder: 3,
              timeSignature: '4/4',
              chords: ['C', 'C', 'C', 'C'],
            ),
            Measure(
              id: null,
              sectionId: 17,
              measureOrder: 4,
              timeSignature: '4/4',
              chords: ['D7', 'D7', 'D7', 'D7'],
            ),
            Measure(
              id: null,
              sectionId: 17,
              measureOrder: 5,
              timeSignature: '4/4',
              chords: ['D7', 'D7', 'D7', 'D7'],
            ),
          ],
        ),
      ],
    );
  }

  /// Vide la base de données et insère les données de test
  static Future<void> initializeTestData(DatabaseHelper databaseHelper) async {
    try {
      // Supprimer toutes les données existantes
      await databaseHelper.deleteDatabase();

      // Réinitialiser la base de données
      await databaseHelper.database;

      // Insérer les chansons
      final songs = generateSampleSongs();
      for (final song in songs) {
        await databaseHelper.insertSong(song);
      }

      // Insérer les répertoires
      final repertoires = generateSampleRepertoires();
      for (final repertoire in repertoires) {
        await databaseHelper.insertRepertoire(repertoire);
      }

      // Insérer les associations
      final repertoireSongs = generateSampleRepertoireSongs();
      for (final rs in repertoireSongs) {
        await databaseHelper.addSongsToRepertoire(rs.repertoireId, [rs.songId]);
      }

      print('✅ Données de test initialisées avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des données de test: $e');
    }
  }
}
