import '../theme/app_colors.dart';

/// Complete musical symbols and constants for chord grid application
/// Professional music notation symbols and terminology
class MusicConstants {
  // Accidentals (Altérations)
  static const String sharp = '♯'; // Dièse
  static const String flat = '♭'; // Bémol
  static const String natural = '♮'; // Bécarre
  static const String doubleSharp = '𝄪'; // Double dièse
  static const String doubleFlat = '𝄫'; // Double bémol

  // Repeat symbols (Symboles de répétition)
  static const String repeatStart = '𝄆'; // Début de répétition
  static const String repeatEnd = '𝄇'; // Fin de répétition
  static const String repeatSign = '%'; // Signe de répétition
  static const String simile = '𝄎'; // Simile (comme avant)
  static const String coda = '⊕'; // Coda
  static const String segno = '𝄋'; // Segno

  // Navigation symbols (Symboles de navigation)
  static const String daCapo = 'D.C.'; // Da Capo (depuis le début)
  static const String dalSegno = 'D.S.'; // Dal Segno (depuis le segno)
  static const String fine = 'Fine'; // Fin
  static const String toCoda = 'To Coda'; // Vers la coda

  // Endings (Terminaisons)
  static const String firstEnding = '1.'; // Première terminaison
  static const String secondEnding = '2.'; // Deuxième terminaison
  static const String thirdEnding = '3.'; // Troisième terminaison
  static const String fourthEnding = '4.'; // Quatrième terminaison

  // Bar lines and separators (Barres de mesure et séparateurs)
  static const String singleBar = '|'; // Barre simple
  static const String doubleBar = '||'; // Double barre
  static const String finalBar = '|]'; // Barre finale
  static const String repeatBar = '|:'; // Barre de répétition
  static const String endRepeatBar = ':|'; // Fin de répétition

  // Time signatures (Mesures)
  static const List<String> commonTimeSignatures = [
    '4/4',
    '3/4',
    '2/4',
    '6/8',
    '12/8',
    '2/2',
    '3/2',
    '5/4',
    '7/4',
  ];

  // Key signatures (Armures)
  static const List<String> majorKeys = [
    'C',
    'G',
    'D',
    'A',
    'E',
    'B',
    'F♯',
    'C♯',
    'F',
    'B♭',
    'E♭',
    'A♭',
    'D♭',
    'G♭',
    'C♭',
  ];

  static const List<String> minorKeys = [
    'Am',
    'Em',
    'Bm',
    'F♯m',
    'C♯m',
    'G♯m',
    'D♯m',
    'A♯m',
    'Dm',
    'Gm',
    'Cm',
    'Fm',
    'B♭m',
    'E♭m',
    'A♭m',
  ];

  // Chord qualities (Qualités d'accords)
  static const List<String> chordQualities = [
    '', // Majeur
    'm', // Mineur
    '7', // Septième de dominante
    'm7', // Septième mineure
    'maj7', // Septième majeure
    'dim', // Diminué
    'aug', // Augmenté
    'sus2', // Suspendu 2
    'sus4', // Suspendu 4
    '6', // Sixte
    'm6', // Sixte mineure
    '9', // Neuvième
    'm9', // Neuvième mineure
    '11', // Onzième
    '13', // Treizième
    '7♭9', // Septième bémol 9
    '7♯9', // Septième dièse 9
    '7♭5', // Septième bémol 5
    '7♯5', // Septième dièse 5
    'm7♭5', // Mineur septième bémol 5 (demi-diminué)
  ];

  // Note names (Noms de notes)
  static const List<String> noteNames = [
    'C',
    'C♯',
    'D',
    'D♯',
    'E',
    'F',
    'F♯',
    'G',
    'G♯',
    'A',
    'A♯',
    'B',
  ];

  static const List<String> flatNoteNames = [
    'C',
    'D♭',
    'D',
    'E♭',
    'E',
    'F',
    'G♭',
    'G',
    'A♭',
    'A',
    'B♭',
    'B',
  ];

  // Section types (Types de sections)
  static const List<String> sectionTypes = [
    'Intro',
    'Verse',
    'Chorus',
    'Bridge',
    'Solo',
    'Interlude',
    'Outro',
    'Pre-Chorus',
    'Post-Chorus',
    'Break',
    'Instrumental',
    'Coda',
  ];

  // Musical terms (Termes musicaux)
  static const Map<String, String> musicalTerms = {
    'tempo': 'Tempo',
    'dynamics': 'Dynamique',
    'crescendo': 'Crescendo',
    'decrescendo': 'Decrescendo',
    'ritardando': 'Ritardando',
    'accelerando': 'Accelerando',
    'a tempo': 'A tempo',
    'rubato': 'Rubato',
    'legato': 'Legato',
    'staccato': 'Staccato',
    'pizzicato': 'Pizzicato',
    'arco': 'Arco',
    'tremolo': 'Tremolo',
    'vibrato': 'Vibrato',
    'glissando': 'Glissando',
    'portamento': 'Portamento',
  };

  // Common chord progressions (Progressions d'accords courantes)
  static const Map<String, List<String>> commonProgressions = {
    'I-IV-V': ['I', 'IV', 'V'],
    'I-V-vi-IV': ['I', 'V', 'vi', 'IV'],
    'ii-V-I': ['ii', 'V', 'I'],
    'I-vi-IV-V': ['I', 'vi', 'IV', 'V'],
    'vi-IV-I-V': ['vi', 'IV', 'I', 'V'],
    'I-IV-vi-V': ['I', 'IV', 'vi', 'V'],
  };

  // Roman numeral chords (Accords en chiffres romains)
  static const List<String> romanNumerals = [
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
  ];

  // Chord voicing symbols (Symboles de renversements)
  static const Map<String, String> voicingSymbols = {
    'root': 'R', // Position fondamentale
    'first': '1st', // Premier renversement
    'second': '2nd', // Deuxième renversement
    'third': '3rd', // Troisième renversement
  };

  // Instrument abbreviations (Abréviations d'instruments)
  static const Map<String, String> instrumentAbbreviations = {
    'guitar': 'Gtr.',
    'bass': 'Bass',
    'drums': 'Dr.',
    'piano': 'Pno.',
    'keyboard': 'Keys',
    'vocals': 'Vox',
    'violin': 'Vln.',
    'viola': 'Vla.',
    'cello': 'Vc.',
    'trumpet': 'Tpt.',
    'saxophone': 'Sax.',
  };

  // Helper methods
  static String getNoteName(int index, {bool useFlats = false}) {
    final notes = useFlats ? flatNoteNames : noteNames;
    return notes[index % notes.length];
  }

  static String getChordQualitySymbol(String quality) {
    return chordQualities.contains(quality) ? quality : '';
  }

  static bool isValidTimeSignature(String timeSig) {
    return commonTimeSignatures.contains(timeSig);
  }

  static String getSectionDisplayName(String sectionType) {
    return sectionType;
  }

  static String getMusicalTerm(String term) {
    return musicalTerms[term] ?? term;
  }

  // Chord validation and transposition methods
  static bool isValidChord(String chord) {
    if (chord.isEmpty) return true;

    // Simple chord validation - check if it starts with a valid note
    final rootPattern = RegExp(r'^[A-G][#♯b♭]?');
    return rootPattern.hasMatch(chord);
  }

  static String transposeNote(String note, int semitones) {
    if (note.isEmpty) return note;

    final notes = noteNames;
    final currentIndex = notes.indexOf(note);
    if (currentIndex == -1) return note;

    final newIndex = (currentIndex + semitones) % 12;
    return notes[newIndex];
  }

  static int getNoteIndex(String note) {
    final notes = noteNames;
    return notes.indexOf(note);
  }

  static int getSemitonesBetween(String note1, String note2) {
    final index1 = getNoteIndex(note1);
    final index2 = getNoteIndex(note2);

    if (index1 == -1 || index2 == -1) return 0;

    return (index2 - index1) % 12;
  }

  // Section color mapping
  static int getSectionColor(String sectionType) {
    switch (sectionType.toLowerCase()) {
      case 'verse':
        return AppColors.verseColor;
      case 'chorus':
        return AppColors.chorusColor;
      case 'bridge':
        return AppColors.bridgeColor;
      case 'intro':
        return AppColors.introColor;
      case 'outro':
        return AppColors.outroColor;
      case 'solo':
        return AppColors.soloColor;
      default:
        return AppColors.primary;
    }
  }
}
