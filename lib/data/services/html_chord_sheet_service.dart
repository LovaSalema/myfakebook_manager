import '../../data/models/song.dart';
import '../../data/models/section.dart';
import '../../data/models/measure.dart';

/// Service to generate HTML chord sheet from Song data
class HtmlChordSheetService {
  /// Generates a complete HTML chord sheet from Song data
  static String generateChordSheetHtml(
    Song song, {
    bool forExport = false,
    bool paginate = false,
    int measuresPerPage = 12,
  }) {
    final htmlContent = _buildHtmlTemplate(
      song,
      forExport: forExport,
      paginate: paginate,
      measuresPerPage: measuresPerPage,
    );
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

  static String _buildHtmlTemplate(
    Song song, {
    bool forExport = false,
    bool paginate = false,
    int measuresPerPage = 12,
  }) {
    final timeSignature = song.timeSignature ?? '4/4';
    final beatsPerMeasure = _getBeatsPerMeasure(timeSignature);
    final gridLayout = _getGridLayout(timeSignature);

    final totalMeasures = song.sections.fold<int>(
      0,
      (sum, section) => sum + section.measures.length,
    );
    final totalPages = paginate
        ? ((totalMeasures + measuresPerPage - 1) ~/ measuresPerPage)
        : 1;

    final paginationHtml = paginate
        ? '''
        <div class="pagination">
          <button onclick="prevPage()" id="prev-btn">&#x2039;</button>
          <span id="page-info">Page 1 of $totalPages</span>
          <button onclick="nextPage()" id="next-btn">&#x203A;</button>
        </div>
        '''
        : '';

    // Auto-scroll controls
    // final autoScrollHtml = '''
    //     <div class="autoscroll-controls">
    //       <button onclick="toggleAutoScroll()" id="autoscroll-btn">▶ Auto-scroll</button>
    //       <label for="speed-slider">Vitesse:</label>
    //       <input type="range" id="speed-slider" min="1" max="10" value="3" step="0.5" onchange="updateScrollSpeed()">
    //       <span id="speed-display">3</span>
    //     </div>
    // ''';

    final scriptHtml =
        '''
    <script>
    var currentPage = 0;
    var totalPages = $totalPages;
    var isAutoScrolling = false;
    var scrollSpeed = 3;
    var scrollInterval = null;
    
    ${paginate ? '''
    function showPage(page) {
      console.log('Showing page: ' + page);
      for (var i = 0; i < totalPages; i++) {
        var el = document.getElementById('page-' + i);
        if (el) el.style.display = i == page ? 'block' : 'none';
      }
      var info = document.getElementById('page-info');
      if (info) info.textContent = 'Page ' + (page + 1) + ' of ' + totalPages;
      var prev = document.getElementById('prev-btn');
      if (prev) prev.disabled = page == 0;
      var next = document.getElementById('next-btn');
      if (next) next.disabled = page == totalPages - 1;
    }
    function nextPage() {
      if (currentPage < totalPages - 1) {
        currentPage++;
        showPage(currentPage);
      }
    }
    function prevPage() {
      if (currentPage > 0) {
        currentPage--;
        showPage(currentPage);
      }
    }
    ''' : ''}
    
    function toggleAutoScroll() {
      isAutoScrolling = !isAutoScrolling;
      var btn = document.getElementById('autoscroll-btn');
      
      if (isAutoScrolling) {
        btn.textContent = '⏸ Pause';
        btn.classList.add('active');
        startAutoScroll();
      } else {
        btn.textContent = '▶ Auto-scroll';
        btn.classList.remove('active');
        stopAutoScroll();
      }
    }
    
    function startAutoScroll() {
      stopAutoScroll(); // Clear any existing interval
      scrollInterval = setInterval(function() {
        var container = document.querySelector('.container');
        var maxScroll = container.scrollHeight - container.clientHeight;
        
        if (window.scrollY >= maxScroll) {
          // Reached bottom, restart
          window.scrollTo(0, 0);
        } else {
          window.scrollBy(0, scrollSpeed);
        }
      }, 50); // Update every 50ms
    }
    
    function stopAutoScroll() {
      if (scrollInterval) {
        clearInterval(scrollInterval);
        scrollInterval = null;
      }
    }
    
    function updateScrollSpeed() {
      var slider = document.getElementById('speed-slider');
      var display = document.getElementById('speed-display');
      scrollSpeed = parseFloat(slider.value);
      display.textContent = scrollSpeed.toFixed(1);
      
      // Restart auto-scroll with new speed if active
      if (isAutoScrolling) {
        startAutoScroll();
      }
    }
    
    // Stop auto-scroll on manual scroll
    var manualScrollTimer;
    window.addEventListener('wheel', function() {
      if (isAutoScrolling) {
        stopAutoScroll();
        clearTimeout(manualScrollTimer);
        manualScrollTimer = setTimeout(function() {
          if (isAutoScrolling) {
            startAutoScroll();
          }
        }, 2000);
      }
    });
    
    // Keyboard shortcuts
    document.addEventListener('keydown', function(e) {
      if (e.code === 'Space') {
        e.preventDefault();
        toggleAutoScroll();
      }
    });
    
    window.onload = function() {
      ${paginate ? 'showPage(0);' : ''}
      document.getElementById('speed-display').textContent = scrollSpeed.toFixed(1);
    };
    </script>
    ''';

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

        /* Auto-scroll controls */
        .autoscroll-controls {
          position: sticky;
          top: 0;
          z-index: 1000;
          display: flex;
          justify-content: center;
          align-items: center;
          gap: 15px;
          padding: 12px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          border-radius: 8px;
          margin-bottom: 20px;
          box-shadow: 0 4px 12px rgba(0,0,0,0.15);
          flex-wrap: wrap;
        }
        
        .autoscroll-controls button {
          padding: 10px 20px;
          background-color: white;
          color: #667eea;
          border: none;
          border-radius: 6px;
          cursor: pointer;
          font-size: 14px;
          font-weight: bold;
          transition: all 0.3s ease;
          box-shadow: 0 2px 6px rgba(0,0,0,0.1);
        }
        
        .autoscroll-controls button:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        }
        
        .autoscroll-controls button.active {
          background-color: #ff6b6b;
          color: white;
        }
        
        .autoscroll-controls label {
          color: white;
          font-weight: bold;
          font-size: 14px;
        }
        
        .autoscroll-controls input[type="range"] {
          width: 120px;
          height: 6px;
          border-radius: 3px;
          outline: none;
          background: rgba(255,255,255,0.3);
        }
        
        .autoscroll-controls input[type="range"]::-webkit-slider-thumb {
          appearance: none;
          width: 18px;
          height: 18px;
          border-radius: 50%;
          background: white;
          cursor: pointer;
          box-shadow: 0 2px 6px rgba(0,0,0,0.2);
        }
        
        .autoscroll-controls input[type="range"]::-moz-range-thumb {
          width: 18px;
          height: 18px;
          border-radius: 50%;
          background: white;
          cursor: pointer;
          border: none;
          box-shadow: 0 2px 6px rgba(0,0,0,0.2);
        }
        
        .autoscroll-controls span {
          color: white;
          font-weight: bold;
          font-size: 14px;
          min-width: 30px;
          text-align: center;
        }

        /* Pagination */
        .pagination {
          display: flex;
          justify-content: center;
          align-items: center;
          gap: 10px;
          margin: 20px 0;
          padding: 10px;
          background-color: #f8f9fa;
          border-radius: 8px;
        }
        .pagination button {
          padding: 8px 16px;
          background-color: #007bff;
          color: white;
          border: none;
          border-radius: 4px;
          cursor: pointer;
          font-size: 24px;
        }
        .pagination button:disabled {
          background-color: #ccc;
          cursor: not-allowed;
        }
        .pagination span {
          font-size: 14px;
          font-weight: bold;
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
            
            .autoscroll-controls {
              padding: 10px;
              gap: 10px;
            }
            
            .autoscroll-controls button {
              padding: 8px 16px;
              font-size: 12px;
            }
            
            .autoscroll-controls input[type="range"] {
              width: 80px;
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
            
            .autoscroll-controls {
              font-size: 12px;
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
            
            .autoscroll-controls {
              display: none;
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
            
            .autoscroll-controls {
              display: none !important;
            }
        }
        ''' : ''}
    </style>
</head>
<body>
    <div class="container">
        <!-- Auto-scroll controls -->
         <!--  autoScrollHtml -->
        
        
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

        ${_buildSectionsHtml(song, timeSignature, beatsPerMeasure, paginate: paginate, measuresPerPage: measuresPerPage)}

        $paginationHtml

        <!-- Footer -->
        <div class="footer">
          <p>page 1 of 1 | last edited ${song.updatedAt.toLocal().toString().split(' ')[0]}</p>
        </div>
    </div>

    $scriptHtml
</body>
</html>
''';
  }

  static String _buildSectionsHtml(
    Song song,
    String timeSignature,
    int beatsPerMeasure, {
    bool paginate = false,
    int measuresPerPage = 12,
  }) {
    if (song.sections.isEmpty) {
      return '<div class="section"><div class="section-title">No Sections</div></div>';
    }

    if (!paginate) {
      final sectionsHtml = StringBuffer();
      for (final section in song.sections) {
        sectionsHtml.write(
          _buildSectionHtml(section, timeSignature, beatsPerMeasure),
        );
      }
      return sectionsHtml.toString();
    }

    // Paginated
    final allMeasures = <(Section, Measure, int)>[];
    for (final section in song.sections) {
      for (var i = 0; i < section.measures.length; i++) {
        allMeasures.add((section, section.measures[i], i));
      }
    }

    final pages = <List<(Section, Measure, int)>>[];
    for (var i = 0; i < allMeasures.length; i += measuresPerPage) {
      final end = i + measuresPerPage > allMeasures.length
          ? allMeasures.length
          : i + measuresPerPage;
      pages.add(allMeasures.sublist(i, end));
    }

    final sectionsHtml = StringBuffer();
    for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final pageMeasures = pages[pageIndex];
      sectionsHtml.write(
        '<div class="page" id="page-$pageIndex" style="${pageIndex == 0 ? '' : 'display:none;'}">',
      );
      // Group by section
      final sectionMap = <Section, List<Measure>>{};
      for (final (section, measure, _) in pageMeasures) {
        sectionMap[section] ??= [];
        sectionMap[section]!.add(measure);
      }
      for (final entry in sectionMap.entries) {
        final section = entry.key;
        final measures = entry.value;
        sectionsHtml.write(
          _buildSectionHtmlFromMeasures(
            section,
            measures,
            timeSignature,
            beatsPerMeasure,
          ),
        );
      }
      sectionsHtml.write('</div>');
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

  static String _buildSectionHtmlFromMeasures(
    Section section,
    List<Measure> measures,
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

    for (final measure in measures) {
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
