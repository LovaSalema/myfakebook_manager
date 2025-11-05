import '../../data/models/song.dart';
import '../../data/models/section.dart';
import '../../data/models/measure.dart';

/// Service to generate HTML chord sheet from Song data
class HtmlChordSheetService {
  /// Generates a complete HTML chord sheet from Song data
  static String generateChordSheetHtml(Song song) {
    final htmlContent = _buildHtmlTemplate(song);
    return htmlContent;
  }

  static String _buildHtmlTemplate(Song song) {
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
            background-color: #f5f5f5;
            padding: 20px;
        }
        
        .container {
            max-width: 900px;
            margin: 0 auto;
            background-color: white;
            padding: 40px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 30px;
            padding-bottom: 10px;
        }
        
        .header-left h1 {
            font-size: 28px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .header-left .meta {
            font-size: 12px;
            color: #666;
        }
        
        .header-right {
            text-align: right;
            font-size: 14px;
        }
        
        .tempo {
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .key {
            font-size: 12px;
        }
        
        .section {
            margin: 25px 0;
        }
        
        .section-group {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            width: 100%;
            gap: 10px;
            border-left: 2px solid #000;
        }
        
        .section-title {
            font-weight: bold;
            font-size: 12px;
            margin-bottom: 10px;
            border: 2px solid #000;
            padding: 5px 8px;
            display: inline-block;
            background-color: #fff;
        }
        
        .chord-block {
            display: grid;
            grid-template-columns: 1fr 1fr;
            grid-template-rows: 1fr 1fr;
            gap: 0;
            align-items: center;
            justify-items: center;
            padding: 8px;
            border-right: 2px solid #000;
            min-height: 60px;
            font-size: 13px;
            font-weight: bold;
            font-family: 'Courier New', monospace;
        }
        
        .chord-block:nth-child(4n) {
            border-right: 2px solid #000;
        }
        
        .chord {
            line-height: 1.3;
            white-space: nowrap;
            text-align: center;
        }
        
        .volta-numbers {
            font-size: 12px;
            display: flex;
            gap: 60px;
            margin-top: -5px;
            margin-bottom: 5px;
            margin-left: 15px;
        }
        
        .volta {
            border: 1px solid #000;
            border-bottom: none;
            padding: 2px 6px;
            display: inline-block;
        }
        
        .coda-symbol {
            font-size: 20px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .footer {
            margin-top: 40px;
            font-size: 10px;
            color: #999;
            text-align: center;
            border-top: 1px solid #ddd;
            padding-top: 10px;
        }

        /* Repeat marks */
        .repeat-open::before {
            content: '𝄐';
            display: inline-block;
            margin-right: 10px;
        }

        .repeat-close::after {
            content: '𝄑';
            display: inline-block;
            margin-left: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div class="header-left">
                <h1>${song.title}</h1>
                <div class="meta">key of ${song.key}</div>
                ${song.style != null ? '<div class="meta">${song.style}</div>' : ''}
                ${song.structure?.description != null ? '<div class="meta">${song.structure!.description!}</div>' : ''}
            </div>
            <div class="header-right">
                ${song.tempo != null ? '<div class="tempo">♩=${song.tempo}</div>' : ''}
                <div class="key">${song.artist}</div>
            </div>
        </div>

        ${_buildSectionsHtml(song)}
        
        <!-- Footer -->
        <div class="footer">
            <p>page 1 of 1 | last edited ${song.updatedAt.toLocal().toString().split(' ')[0]}</p>
        </div>
    </div>
</body>
</html>
''';
  }

  static String _buildSectionsHtml(Song song) {
    if (song.sections.isEmpty) {
      return '<div class="section"><div class="section-title">No Sections</div></div>';
    }

    final sectionsHtml = StringBuffer();

    for (final section in song.sections) {
      sectionsHtml.write(_buildSectionHtml(section));
    }

    return sectionsHtml.toString();
  }

  static String _buildSectionHtml(Section section) {
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

      // Build chord block in 2x2 grid
      sectionHtml.write('<div class="chord-block">');

      // Fill up to 4 positions (2x2 grid)
      for (int i = 0; i < 4; i++) {
        if (i < validChords.length) {
          sectionHtml.write('<div class="chord">${validChords[i]}</div>');
        } else {
          // Empty cell if less than 4 chords
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
