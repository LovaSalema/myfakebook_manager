import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class ChordInputWidget extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onTextChanged;
  final String hintText;

  const ChordInputWidget({
    super.key,
    required this.initialText,
    required this.onTextChanged,
    this.hintText = 'Entrez les accords séparés par des espaces',
  });

  @override
  State<ChordInputWidget> createState() => _ChordInputWidgetState();
}

class _ChordInputWidgetState extends State<ChordInputWidget> {
  late String _currentText;
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _currentText = widget.initialText;

    // Initialize WebView controller
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: _onJavaScriptMessage,
      )
      ..loadHtmlString(_getHtmlContent());

    // Set initial text after loading
    _webViewController.runJavaScript(
      "setTimeout(function() { setInitialText('${widget.initialText.replaceAll("'", "\\'")}'); }, 100);",
    );
  }

  @override
  void didUpdateWidget(ChordInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText) {
      _currentText = widget.initialText;
    }
  }

  void _onJavaScriptMessage(JavaScriptMessage message) {
    try {
      final data = message.message;
      // The message is a JSON string from JavaScript
      final Map<String, dynamic> parsedData = json.decode(data);
      final String type = parsedData['type'];
      final String text = parsedData['text'] ?? '';

      if (type == 'textChanged') {
        setState(() {
          _currentText = text;
        });
        widget.onTextChanged(text);
      }
    } catch (e) {
      debugPrint('Error parsing JavaScript message: $e');
    }
  }

  String _getHtmlContent() {
    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Clavier d'Accords Jazz</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            -webkit-tap-highlight-color: transparent;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f5f5;
            min-height: 100vh;
            padding: 10px;
            overflow-x: hidden;
        }

        .container {
            max-width: 100%;
            margin: 0 auto;
        }

        .header {
            display: flex;
            justify-content: end;
            align-items: center;
            margin-bottom: 15px;
            padding: 0 10px;
        }

        .switch-container {
            display: flex;
            align-items: center;
            gap: 10px;
            background: white;
            padding: 8px 15px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }

        .switch-label {
            font-weight: 600;
            color: #555;
            font-size: 12px;
        }

        .switch {
            position: relative;
            display: inline-block;
            width: 50px;
            height: 28px;
        }

        @media (max-width: 480px) {
            .switch {
                width: 40px;
                height: 24px;
            }

              .slider:before {
                height: 16px;
                width: 16px;
                left: 3px;
                bottom: 4px;
            }
        }

        .switch input {
            opacity: 0;
            width: 0;
            height: 0;
        }

        .slider {
            position: absolute;
            cursor: pointer;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-color: #667eea;
            transition: .4s;
            border-radius: 34px;
        }

        .slider:before {
            position: absolute;
            content: "";
            height: 18px;
            width: 18px;
            left: 4px;
            background-color: white;
            transition: .4s;
            border-radius: 50%;
        }

        input:checked + .slider {
            background-color: #764ba2;
        }

        input:checked + .slider:before {
            transform: translateX(16px);
        }

        .mode-text {
            font-weight: 600;
            color: #667eea;
            font-size: 11px;
        }

        .main-layout {
            display: flex;
            flex-direction: column;
            gap: 15px;
        }

        .left-section {
            background: white;
            border-radius: 15px;
            padding: 15px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        }

        .right-section {
            background: white;
            border-radius: 15px;
            padding: 15px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        }

        .display {
            background: #f8f9fa;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            padding: 15px;
            min-height: 80px;
            font-size: 24px;
            font-weight: bold;
            color: #333;
            margin-bottom: 15px;
            word-wrap: break-word;
            font-family: 'Courier New', monospace;
            overflow-wrap: break-word;
        }

        .section-title {
            font-weight: 600;
            color: #888;
            margin-bottom: 10px;
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 1.5px;
            text-align: center;
        }

        .keyboard {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }

        .key-row {
            display: flex;
            gap: 5px;
            justify-content: center;
            flex-wrap: wrap;
        }

        .key {
            background: white;
            border: none;
            border-radius: 8px;
            padding: 0;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s;
            color: #333;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            min-width: 55px;
            height: 55px;
            display: flex;
            align-items: center;
            justify-content: center;
            touch-action: manipulation;
        }

        .key:active {
            transform: scale(0.95);
            box-shadow: 0 1px 3px rgba(0,0,0,0.2);
        }

        .key.symbol {
            background: #a8edea;
        }

        .key.note {
            background: #f0f0f0;
        }

        .key.space {
            min-width: 200px;
            flex-grow: 1;
            background: #95e1d3;
        }

        .right-grid {
            display: flex;
            flex-direction: column;
            gap: 15px;
        }

        .control-buttons {
            display: flex;
            gap: 10px;
        }

        .btn {
            flex: 1;
            padding: 12px;
            border: none;
            border-radius: 10px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            touch-action: manipulation;
        }

        .btn-clear {
            background: #ff6b6b;
            color: white;
        }

        .btn-backspace {
            background: #ffd93d;
            color: #333;
        }

        .btn:active {
            transform: scale(0.95);
        }

        .quality-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 8px;
        }

        .quality-key {
            background: #ffd89b;
            border: none;
            border-radius: 8px;
            padding: 12px 8px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s;
            color: #333;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            text-align: center;
            touch-action: manipulation;
        }

        .quality-key:active {
            transform: scale(0.95);
            box-shadow: 0 1px 3px rgba(0,0,0,0.2);
        }

        .section-label {
            font-size: 10px;
            color: #aaa;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-top: 5px;
            text-align: right;
        }

        @media (min-width: 768px) {
            .main-layout {
                flex-direction: row;
            }

            .left-section {
                flex: 1;
            }

            .right-section {
                width: 400px;
            }

            .key {
                min-width: 65px;
                height: 65px;
                font-size: 18px;
            }

            .key.space {
                min-width: 400px;
            }

            .display {
                font-size: 32px;
                min-height: 100px;
                padding: 20px;
            }
        }

        /* Mobile optimizations */
        @media (max-width: 480px) {
            .container {
                padding: 3px;
            }

            .header {
                margin-bottom: 8px;
            }

            .switch-container {
                padding: 5px 10px;
            }

            .switch-label {
                font-size: 9px;
            }

            .mode-text {
                font-size: 8px;
            }

            .main-layout {
                gap: 8px;
            }

            .left-section, .right-section {
                padding: 8px;
            }

            .display {
                padding: 8px;
                min-height: 50px;
                font-size: 18px;
                margin-bottom: 8px;
            }

            .section-title {
                font-size: 7px;
                margin-bottom: 6px;
            }

            .key-row {
                gap: 2px;
                margin-bottom: 6px;
            }

            .key {
                min-width: 35px;
                height: 35px;
                font-size: 12px;
            }

            .key.space {
                min-width: 120px;
                flex-grow: 1;
            }

            .control-buttons {
                gap: 4px;
                margin-bottom: 8px;
            }

            .btn {
                padding: 8px;
                font-size: 11px;
            }

            .quality-grid {
                grid-template-columns: repeat(3, 1fr);
                gap: 4px;
            }

            .quality-key {
                padding: 8px 4px;
                font-size: 10px;
            }

            .section-label {
                font-size: 7px;
                margin-top: 2px;
            }
        }

#rootNotesNatural {
gap: 4px
}
        /* Tablet optimizations */
        @media (min-width: 481px) and (max-width: 767px) {
            .container {
                padding: 8px;
            }

            .key {
                min-width: 50px;
                height: 50px;
                font-size: 15px;
            }

            .key.space {
                min-width: 180px;
            }

            .quality-grid {
                grid-template-columns: repeat(4, 1fr);
                gap: 7px;
            }

            .quality-key {
                padding: 11px 7px;
                font-size: 13px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="switch-container">
               
                <label class="switch">
                    <input type="checkbox" id="modeSwitch">
                    <span class="slider"></span>
                </label>
                
                <span class="mode-text" id="modeText">Mode: Alphabet</span>
            </div>
        </div>

        <div class="main-layout">
            <div class="left-section">
                <div class="keyboard">
                    <div class="display" id="display"></div>
                    
                    <div>
                       <div class="control-buttons">
                        <button class="btn btn-clear" id="clear">Effacer</button>
                        <button class="btn btn-backspace" id="backspace">← Retour</button>
                    </div>
                        <div class="key-row">
                            <button class="key symbol" data-value="♯">♯</button>
                            <button class="key symbol" data-value="♭">♭</button>
                            <button class="key symbol" data-value="♮">♮</button>
                            <button class="key symbol" data-value="+">(+)</button>
                            <button class="key symbol" data-value="(">(</button>
                            <button class="key symbol" data-value=")">)</button>
                            <button class="key symbol" data-value="/">/</button>
                            <button class="key symbol" data-value="alt">alt</button>
                        </div>
                    </div>

                    <div class="key-row" id="rootNotesNatural">
                        <button class="key note" data-alphabet="C" data-roman="I">C</button>
                        <button class="key note" data-alphabet="D" data-roman="II">D</button>
                        <button class="key note" data-alphabet="E" data-roman="III">E</button>
                        <button class="key note" data-alphabet="F" data-roman="IV">F</button>
                        <button class="key note" data-alphabet="G" data-roman="V">G</button>
                        <button class="key note" data-alphabet="A" data-roman="VI">A</button>
                        <button class="key note" data-alphabet="B" data-roman="VII">B</button>
                    </div>

                    <div class="key-row">
                        <button class="key space" id="space">Espace</button>
                    </div>
                </div>
            </div>

            <div class="right-section">
                <div class="right-grid">
                    

                    <div>
                        <div class="quality-grid">
                            <button class="quality-key" data-value="maj7">maj7</button>
                            <button class="quality-key" data-value="7">7</button>
                            <button class="quality-key" data-value="m7">m7</button>
                            <button class="quality-key" data-value="m7♭5">m7♭5</button>
                            <button class="quality-key" data-value="m9">m9</button>
                            <button class="quality-key" data-value="11">11</button>
                            <button class="quality-key" data-value="13">13</button>
                            <button class="quality-key" data-value="sus4">sus4</button>
                            <button class="quality-key" data-value="6">6</button>
                            <button class="quality-key" data-value="m6">m6</button>
                            <button class="quality-key" data-value="9">9</button>
                            <button class="quality-key" data-value="maj9">maj9</button>
                            <button class="quality-key" data-value="°7">°7</button>
                            <button class="quality-key" data-value="Δ">Δ</button>
                            <button class="quality-key" data-value="−">−</button>
                            <button class="quality-key" data-value="ø">ø</button>
                        </div>
                        <div class="section-label">Extensions</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        const display = document.getElementById('display');
        const modeSwitch = document.getElementById('modeSwitch');
        const modeText = document.getElementById('modeText');
        const rootNotesFlat = document.querySelectorAll('#rootNotesFlat .key');
        const rootNotesNatural = document.querySelectorAll('#rootNotesNatural .key');
        let currentText = '';
        let isRomanMode = false;

        // Communication avec Flutter (optionnel)
        function sendToFlutter(message) {
            if (window.FlutterChannel) {
                window.FlutterChannel.postMessage(JSON.stringify(message));
            }
        }

        modeSwitch.addEventListener('change', function() {
            isRomanMode = this.checked;
            modeText.textContent = isRomanMode ? 'Mode: Romains' : 'Mode: Alphabet';
            updateRootNotes();
            sendToFlutter({ type: 'modeChanged', mode: isRomanMode ? 'roman' : 'alphabet' });
        });

        function updateRootNotes() {
            rootNotesFlat.forEach(note => {
                note.textContent = isRomanMode ? note.dataset.roman : note.dataset.alphabet;
            });
            rootNotesNatural.forEach(note => {
                note.textContent = isRomanMode ? note.dataset.roman : note.dataset.alphabet;
            });
        }

        document.querySelectorAll('.key, .quality-key').forEach(key => {
            key.addEventListener('click', function(e) {
                e.preventDefault();
                let value;
                if (this.classList.contains('note')) {
                    value = isRomanMode ? this.dataset.roman : this.dataset.alphabet;
                } else {
                    value = this.dataset.value;
                }
                if (value) {
                    currentText += value;
                    display.textContent = currentText;
                    sendToFlutter({ type: 'textChanged', text: currentText });
                }
            });
        });

        document.getElementById('space').addEventListener('click', function(e) {
            e.preventDefault();
            currentText += ' ';
            display.textContent = currentText;
            sendToFlutter({ type: 'textChanged', text: currentText });
        });

        document.getElementById('backspace').addEventListener('click', function(e) {
            e.preventDefault();
            currentText = currentText.slice(0, -1);
            display.textContent = currentText;
            sendToFlutter({ type: 'textChanged', text: currentText });
        });

        document.getElementById('clear').addEventListener('click', function(e) {
            e.preventDefault();
            currentText = '';
            display.textContent = '';
            sendToFlutter({ type: 'textChanged', text: currentText });
        });

        // Fonction pour définir le texte initial
        function setInitialText(text) {
            currentText = text;
            display.textContent = currentText;
        }

        // Fonction pour recevoir des messages depuis Flutter (optionnel)
        window.addEventListener('message', function(event) {
            try {
                const data = JSON.parse(event.data);
                if (data.action === 'setText') {
                    currentText = data.text;
                    display.textContent = currentText;
                } else if (data.action === 'clear') {
                    currentText = '';
                    display.textContent = '';
                }
            } catch (e) {
                console.error('Error parsing message:', e);
            }
        });
    </script>
</body>
</html>
''';
  }

  void _showChordKeyboard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header with done button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Saisir les accords',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Terminé'),
                    ),
                  ],
                ),
              ),
              // WebView
              Expanded(child: WebViewWidget(controller: _webViewController)),
            ],
          ),
        );
      },
    ).then((_) {
      // When modal is closed, update the text if needed
      widget.onTextChanged(_currentText);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showChordKeyboard,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _currentText.isEmpty ? widget.hintText : _currentText,
                style: TextStyle(
                  color: _currentText.isEmpty
                      ? Theme.of(context).hintColor
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.keyboard,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
