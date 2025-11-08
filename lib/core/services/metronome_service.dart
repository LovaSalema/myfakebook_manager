import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// Service for playing metronome clicks at specified BPM
class MetronomeService {
  // Pool de lecteurs pour éviter la latence
  final List<AudioPlayer> _playerPool = [];
  int _currentPlayerIndex = 0;
  static const int _poolSize = 4; // Nombre de lecteurs dans le pool

  Timer? _timer;
  bool _isPlaying = false;
  int? _currentBpm;

  MetronomeService() {
    _initializePlayerPool();
  }

  /// Initialise le pool de lecteurs audio
  Future<void> _initializePlayerPool() async {
    for (int i = 0; i < _poolSize; i++) {
      final player = AudioPlayer();

      // Configuration pour réduire la latence
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(1.0);

      // Précharger le son
      await player.setSource(AssetSource('sounds/click.mp3'));

      _playerPool.add(player);
    }
    print('Player pool initialized with $_poolSize players');
  }

  /// Start playing metronome at given BPM
  Future<void> start(int bpm) async {
    // Si déjà en cours avec le même BPM, ne rien faire
    if (_isPlaying && _currentBpm == bpm) {
      print('Metronome already playing at $bpm BPM');
      return;
    }

    // Si en cours avec un BPM différent, arrêter d'abord
    if (_isPlaying) {
      stop();
      // Petit délai pour assurer l'arrêt complet
      await Future.delayed(const Duration(milliseconds: 50));
    }

    _isPlaying = true;
    _currentBpm = bpm;
    print('Starting metronome at $bpm BPM');

    // Assurer que les lecteurs sont initialisés
    if (_playerPool.isEmpty) {
      await _initializePlayerPool();
    }

    // Calculate interval in milliseconds (60 seconds / BPM)
    final intervalMs = (60000 / bpm).round();
    print('Interval: $intervalMs ms');

    // Jouer le premier clic immédiatement
    _playClick();

    // Puis continuer avec le timer
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (_isPlaying) {
        _playClick();
      }
    });
  }

  /// Stop playing metronome
  void stop() {
    print('Stopping metronome');
    _isPlaying = false;
    _currentBpm = null;
    _timer?.cancel();
    _timer = null;

    // Arrêter tous les lecteurs
    for (var player in _playerPool) {
      player.stop();
    }
  }

  /// Play single click sound using player pool
  void _playClick() {
    if (_playerPool.isEmpty) return;

    try {
      // Utiliser le prochain lecteur dans le pool
      final player = _playerPool[_currentPlayerIndex];

      // Arrêter et repositionner le lecteur
      player.stop();
      player.seek(Duration.zero);
      player.resume();

      // Passer au prochain lecteur
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _poolSize;
    } catch (e) {
      print('Error playing click sound: $e');
    }
  }

  /// Update BPM while playing
  Future<void> updateBpm(int bpm) async {
    if (_isPlaying) {
      await start(bpm); // Redémarre avec le nouveau BPM
    }
  }

  /// Check if metronome is currently playing
  bool get isPlaying => _isPlaying;

  /// Get current BPM
  int? get currentBpm => _currentBpm;

  /// Dispose resources
  void dispose() {
    stop();
    for (var player in _playerPool) {
      player.dispose();
    }
    _playerPool.clear();
  }
}
