import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// Service for playing metronome clicks at specified BPM
class MetronomeService {
  AudioPlayer? _audioPlayer;
  Timer? _timer;
  bool _isPlaying = false;

  /// Start playing metronome at given BPM
  Future<void> start(int bpm) async {
    if (_isPlaying) {
      stop();
    }

    _isPlaying = true;
    print('Starting metronome at $bpm BPM');

    // Calculate interval in milliseconds (60 seconds / BPM)
    final intervalMs = (60000 / bpm).round();
    print('Interval: $intervalMs ms');

    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) async {
      if (_isPlaying) {
        await _playClick();
      }
    });
  }

  /// Stop playing metronome
  void stop() {
    print('Stopping metronome');
    _isPlaying = false;
    _timer?.cancel();
    _timer = null;
    _audioPlayer?.stop();
  }

  /// Play single click sound
  Future<void> _playClick() async {
    try {
      _audioPlayer ??= AudioPlayer();
      print('Playing click sound...');
      await _audioPlayer!.play(AssetSource('sounds/click.mp3'));
      print('Click sound played');
    } catch (e) {
      print('Error playing click sound: $e');
    }
  }

  /// Check if metronome is currently playing
  bool get isPlaying => _isPlaying;

  /// Dispose resources
  void dispose() {
    stop();
    _audioPlayer?.dispose();
    _audioPlayer = null;
  }
}
