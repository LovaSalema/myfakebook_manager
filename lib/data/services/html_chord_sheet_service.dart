import '../../data/models/song.dart';
import '../../data/models/section.dart';
import '../../data/models/measure.dart';

/// Service to generate HTML chord sheet from Song data
class HtmlChordSheetService {
  /// Generates a complete HTML chord sheet from Song data
  static String generateChordSheetHtml(Song song, {bool forExport = false}) {
    final htmlContent = _buildHtmlTemplate(song, forExport: forExport);
    return htmlContent;
  }

  /// Get the number of beats per measure based on time signature
  static int _getBeatsPerMeasure(String timeSignature) {
    switch (timeSignature) {
      case '4/4':
        return 4;
      case '3/4':
        return 3;
      case '2/4':
        return 2;
      case '6/8':
        return 6;
      case '12/8':
        return 12;
      case '5/4':
        return 5;
      case '7/8':
        return 7;
      default:
        return 4; // Default to 4/4
    }
  }

  /// Get grid layout based on time signature
  static String _getGridLayout(String timeSignature) {
    switch (timeSignature) {
      case '4/4':
        return '1fr 1fr / 1fr 1fr'; // 2x2 grid
      case '3/4':
        return '1fr 1fr 1fr / 1fr'; // 3x1 grid (3 horizontal)
      case '2/4':
        return '1fr 1fr / 1fr'; // 2x1 grid (2 horizontal)
      case '6/8':
        return '1fr 1fr 1fr / 1fr 1fr 1fr'; // 3x2 grid
      case '12/8':
        return '1fr 1fr 1fr 1fr / 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr'; // 4x3 grid
      case '5/4':
        return '1fr 1fr 1fr 1fr 1fr / 1fr'; // 5x1 grid
      case '7/8':
        return '1fr 1fr 1fr 1fr / 1fr 1fr 1fr'; // 4 + 3 layout
      default:
        return '1fr 1fr / 1fr 1fr'; // Default 2x2
    }
  }

  /// Get time signature description
  static String _getTimeSignatureDescription(String timeSignature) {
    switch (timeSignature) {
      case '4/4':
        return 'Common time - Pop, rock, jazz, classique';
      case '3/4':
        return 'Valse, menuet';
      case '2/4':
        return 'Marche, polka';
      case '6/8':
        return 'Ternaire composé - Ballades, celtique';
      case '12/8':
        return 'Blues lent, swing, soul';
      case '5/4':
        return 'Rythme impair - Jazz progressif';
      case '7/8':
        return 'Rythme impair - Balkanique';
      default:
        return '';
    }
  }

  static String _buildHtmlTemplate(Song song, {bool forExport = false}) {
    final timeSignature = song.timeSignature ?? '4/4';
    final beatsPerMeasure = _getBeatsPerMeasure(timeSignature);
    final gridLayout = _getGridLayout(timeSignature);

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${song.title} - Chord Sheet</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Courier New', monospace;
            background-color: ${forExport ? '#ffffff' : '#f5f5f5'};
            padding: ${forExport ? '0px' : '10px'};
        }
        
        .container {
            max-width: 900px;
            margin: 0 auto;
            background-color: white;
            padding: ${forExport ? '0px' : '20px'};
            box-shadow: ${forExport ? 'none' : '0 2px 10px rgba(0,0,0,0.1)'};
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 20px;
            padding-bottom: 10px;
            flex-wrap: wrap;
            gap: 10px;
        }
        
        .header-left {
            flex: 1;
            min-width: 200px;
        }
        
        .header-left h1 {
            font-size: clamp(20px, 4vw, 28px);
            font-weight: bold;
            margin-bottom: 5px;
            word-wrap: break-word;
        }
        
        .header-left .meta {
            font-size: clamp(10px, 2vw, 12px);
            color: #666;
        }
        
        .header-right {
            text-align: right;
            font-size: clamp(12px, 2.5vw, 14px);
        }
        
        .tempo {
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .time-signature {
            font-weight: bold;
            font-size: clamp(14px, 3vw, 18px);
            margin-bottom: 3px;
            color: #333;
        }
        
        .time-sig-description {
            font-size: clamp(9px, 1.8vw, 11px);
            color: #777;
            font-style: italic;
        }
        
        .key {
            font-size: clamp(10px, 2vw, 12px);
            margin-top: 5px;
        }
        
        .section {
            margin: 15px 0;
        }
        
        .section-group {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(min(100%, 150px), 1fr));
            width: 100%;
            gap: 5px;
            border-left: 2px solid #000;
        }
        
        .section-title {
            font-weight: bold;
            font-size: clamp(10px, 2vw, 12px);
            margin-bottom: 10px;
            border: 2px solid #000;
            padding: 5px 8px;
            display: inline-block;
            background-color: #fff;
            word-wrap: break-word;
        }
        
        .chord-block {
            display: grid;
            grid-template: $gridLayout;
            gap: 4px;
            align-items: center;
            justify-items: center;
            padding: 8px;
            border-right: 2px solid #000;
            min-height: 60px;
            font-size: clamp(11px, 2.2vw, 13px);
            font-weight: bold;
            font-family: 'Courier New', monospace;
        }
        
        /* Specific layouts for different time signatures */
        .chord-block[data-time-sig="3/4"],
        .chord-block[data-time-sig="2/4"],
        .chord-block[data-time-sig="5/4"] {
            min-height: 40px;
        }
        
        .chord-block[data-time-sig="6/8"] {
            min-height: 70px;
        }
        
        .chord-block[data-time-sig="12/8"] {
            min-height: 90px;
        }
        
        .chord {
            line-height: 1.2;
            white-space: nowrap;
            text-align: center;
            padding: 2px;
            background-color: #f8f9fa;
            border-radius: 3px;
            border: 1px solid #e9ecef;
            font-size: clamp(11px, 2.2vw, 13px);
            max-width: 100%;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        
        .volta-numbers {
            font-size: clamp(10px, 2vw, 12px);
            display: flex;
            gap: 30px;
            margin-top: -5px;
            margin-bottom: 5px;
            margin-left: 10px;
            flex-wrap: wrap;
        }
        
        .volta {
            border: 1px solid #000;
            border-bottom: none;
            padding: 2px 6px;
            display: inline-block;
        }
        
        .coda-symbol {
            font-size: clamp(16px, 3.5vw, 20px);
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .footer {
            margin-top: 30px;
            font-size: clamp(8px, 1.8vw, 10px);
            color: #999;
            text-align: center;
            border-top: 1px solid #ddd;
            padding-top: 10px;
            word-wrap: break-word;
        }

        /* Repeat marks */
        .repeat-open::before {
            content: '𝄐';
            display: inline-block;
            margin-right: 10px;
            font-size: clamp(14px, 3vw, 18px);
        }

        .repeat-close::after {
            content: '𝄑';
            display: inline-block;
            margin-left: 10px;
            font-size: clamp(14px, 3vw, 18px);
        }

        /* Responsive adjustments */
        @media screen and (max-width: 768px) {
            body {
                padding: 5px;
            }
            
            .container {
                padding: 15px;
            }
            
            .section-group {
                grid-template-columns: repeat(auto-fit, minmax(min(100%, 120px), 1fr));
            }
            
            .chord-block {
                min-height: 50px;
                padding: 6px;
            }
        }
        
        @media screen and (max-width: 480px) {
            body {
                padding: 3px;
            }
            
            .container {
                padding: 12px;
            }
            
            .header {
                margin-bottom: 15px;
            }
            
            .section {
                margin: 12px 0;
            }
            
            .section-group {
                grid-template-columns: repeat(auto-fit, minmax(min(100%, 100px), 1fr));
            }
            
            .chord-block {
                min-height: 45px;
                padding: 5px;
                gap: 3px;
            }
            
            .footer {
                margin-top: 20px;
            }
        }

        /* Print styles */
        @media print {
            body {
                padding: 0;
                background-color: white;
            }

            .container {
                box-shadow: none;
                padding: 20px;
            }
        }

        /* Export styles */
        ${forExport ? '''
        @media screen {
            body {
                padding: 0 !important;
                background-color: white !important;
            }

            .container {
                box-shadow: none !important;
                padding: 0 !important;
            }
        }
        ''' : ''}
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div class="header-left">
                <h1>${song.title}</h1>
                <div class="meta">Tonalité: ${song.key}</div>
                ${song.style != null ? '<div class="meta">${song.style}</div>' : ''}
                ${song.structure?.description != null ? '<div class="meta">${song.structure!.description!}</div>' : ''}
            </div>
            <div class="header-right">
                <div class="time-signature">$timeSignature</div>
                <div class="time-sig-description">${_getTimeSignatureDescription(timeSignature)}</div>
                ${song.tempo != null ? '<div class="tempo">♩=${song.tempo}</div>' : ''}
                <div class="key">${song.artist}</div>
            </div>
        </div>

        ${_buildSectionsHtml(song, timeSignature, beatsPerMeasure)}
        
        <!-- Footer -->
        <div class="footer">
            <p>page 1 of 1 | last edited ${song.updatedAt.toLocal().toString().split(' ')[0]}</p>
        </div>
    </div>
</body>
</html>
''';
  }

  static String _buildSectionsHtml(
    Song song,
    String timeSignature,
    int beatsPerMeasure,
  ) {
    if (song.sections.isEmpty) {
      return '<div class="section"><div class="section-title">No Sections</div></div>';
    }

    final sectionsHtml = StringBuffer();

    for (final section in song.sections) {
      sectionsHtml.write(
        _buildSectionHtml(section, timeSignature, beatsPerMeasure),
      );
    }

    return sectionsHtml.toString();
  }

  static String _buildSectionHtml(
    Section section,
    String timeSignature,
    int beatsPerMeasure,
  ) {
    final sectionHtml = StringBuffer();

    sectionHtml.write('<div class="section">');

    // Section header
    if (section.sectionType == 'CODA') {
      sectionHtml.write('<div class="coda-symbol">𝄌</div>');
    }

    sectionHtml.write(
      '<div class="section-title">${section.displayName}</div>',
    );

    // Section content
    sectionHtml.write('<div class="section-group">');

    for (final measure in section.measures) {
      // Get all non-empty chords
      final validChords = measure.chords
          .where((chord) => chord.isNotEmpty)
          .toList();

      // Build chord block with time signature attribute
      sectionHtml.write(
        '<div class="chord-block" data-time-sig="$timeSignature">',
      );

      // Fill up to beatsPerMeasure positions
      for (int i = 0; i < beatsPerMeasure; i++) {
        if (i < validChords.length) {
          sectionHtml.write('<div class="chord">${validChords[i]}</div>');
        } else {
          // Empty cell if less than beatsPerMeasure chords
          sectionHtml.write('<div class="chord"></div>');
        }
      }

      sectionHtml.write('</div>');
    }

    sectionHtml.write('</div>');

    // Repeat marks
    if (section.hasRepeatSign) {
      sectionHtml.write('<div class="repeat-open"></div>');
    }

    sectionHtml.write('</div>');

    return sectionHtml.toString();
  }
}
