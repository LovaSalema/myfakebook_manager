import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:screenshot/screenshot.dart';
import '../../../data/models/song.dart';
import '../../../data/services/html_chord_sheet_service.dart';

/// WebView widget for displaying chord sheet HTML
class ChordSheetWebView extends StatefulWidget {
  final Song song;
  final bool forExport;

  const ChordSheetWebView({
    super.key,
    required this.song,
    this.forExport = false,
  });

  @override
  State<ChordSheetWebView> createState() => ChordSheetWebViewState();
}

class ChordSheetWebViewState extends State<ChordSheetWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  final ScreenshotController screenshotController = ScreenshotController();

  // Getter to expose the controller
  ScreenshotController get controller => screenshotController;

  // Method to advance to next page
  void nextPage() {
    _controller.runJavaScript('nextPage();');
  }

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    try {
      print(
        'DEBUG: Starting WebView initialization for song: ${widget.song.title}',
      );
      final htmlContent = HtmlChordSheetService.generateChordSheetHtml(
        widget.song,
        forExport: widget.forExport,
        paginate: !widget.forExport,
        measuresPerPage: 12,
      );
      print(
        'DEBUG: HTML content generated successfully, length: ${htmlContent.length}',
      );

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print('DEBUG: WebView page started loading: $url');
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            },
            onPageFinished: (String url) async {
              print(
                'DEBUG: WebView page finished loading: $url (forExport: ${widget.forExport})',
              );
              // Log the content height
              try {
                final height = await _controller.runJavaScriptReturningResult(
                  'document.body.scrollHeight',
                );
                print('DEBUG: WebView content scrollHeight: $height');
              } catch (e) {
                print('DEBUG: Error getting scrollHeight: $e');
              }
              setState(() {
                _isLoading = false;
              });
            },
            onWebResourceError: (WebResourceError error) {
              print(
                'DEBUG: WebView resource error: ${error.errorCode} - ${error.description}',
              );
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            },
            onNavigationRequest: (NavigationRequest request) {
              print('DEBUG: Navigation request: ${request.url}');
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadHtmlString(htmlContent);

      print('DEBUG: WebView controller created and configured successfully');
    } catch (e) {
      print('DEBUG: WebView initialization error: $e');
      print('DEBUG: Stack trace: ${e.toString()}');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      'DEBUG: ChordSheetWebView.build() called - _hasError: $_hasError, _isLoading: $_isLoading, forExport: ${widget.forExport}',
    );

    // For export, return just the WebView without Card/padding
    if (widget.forExport) {
      print(
        'DEBUG: Building export WebView widget - _isLoading: $_isLoading, _hasError: $_hasError',
      );
      return Container(
        width: double.infinity,
        height: 500,
        color: Colors.white,
        child: _hasError
            ? _buildErrorState()
            : ExcludeSemantics(child: WebViewWidget(controller: _controller)),
      );
    }

    // Normal display with Card and padding
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero, // Remove card margins for full width
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity, // Full width
        padding: const EdgeInsets.all(4), // Réduit de 20 à 8
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 2,
                bottom: 8,
              ), // Padding minimal pour le titre
              // child: Text(
              // 'Chord Sheet (WebView)',
              // style: TextStyle(
              //   fontSize: 14,
              //   fontWeight: FontWeight.bold,
              //   color: Colors.grey[700],
              // ),
              // ),
            ),
            // Wrap ONLY the WebView content with Screenshot
            Screenshot(
              controller: screenshotController,
              child: Container(
                width: double.infinity, // Full width
                height: 1000,
                color: Colors.white, // Ensure white background
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 1000,
                        child: _hasError
                            ? _buildErrorState()
                            : ExcludeSemantics(
                                child: WebViewWidget(controller: _controller),
                              ),
                      ),
                      if (_isLoading)
                        Container(
                          width: double.infinity,
                          height: 1000,
                          color: Colors.white,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Impossible d\'afficher la grille WebView',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeWebView,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
