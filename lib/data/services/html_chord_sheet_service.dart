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

  static String _buildHtmlTemplate(Song song, {bool forExport = false}) {
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
        
        .key {
            font-size: clamp(10px, 2vw, 12px);
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
            grid-template-columns: 1fr 1fr;
            grid-template-rows: 1fr 1fr;
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
