import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';

/// Simple Audio Handler tanpa AudioService (notifikasi dinonaktifkan)
/// Music tetap bisa diputar tapi tanpa notifikasi background
class AlfalAudioHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);

  // Streams untuk UI
  final _currentSongController = StreamController<SongModel?>.broadcast();
  final _isPlayingController = StreamController<bool>.broadcast();
  final _queueController = StreamController<List<SongModel>>.broadcast();
  
  List<SongModel> _queue = [];
  int _currentIndex = 0;

  Stream<SongModel?> get currentSongStream => _currentSongController.stream;
  Stream<bool> get isPlayingStream => _isPlayingController.stream;
  Stream<List<SongModel>> get queueStream => _queueController.stream;
  
  AlfalAudioHandler() {
    _loadEmptyPlaylist();
    _listenToPlayerChanges();
  }

  void _loadEmptyPlaylist() async {
    try {
      await _player.setAudioSource(_playlist);
    } catch (e) {
      print("Error loading empty playlist: $e");
    }
  }

  void _listenToPlayerChanges() {
    _player.playingStream.listen((playing) {
      _isPlayingController.add(playing);
    });

    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _queue.length) {
        _currentIndex = index;
        _currentSongController.add(_queue[index]);
      }
    });
  }

  // ── Public API (Used by PlayerNotifier) ─────────────────────

  Future<void> setSongs(List<SongModel> songs, {int initialIndex = 0}) async {
    _queue = songs;
    _currentIndex = initialIndex;
    
    _queueController.add(_queue);
    if (_queue.isNotEmpty && initialIndex < _queue.length) {
      _currentSongController.add(_queue[initialIndex]);
    }

    _playlist.clear();
    await _playlist.addAll(songs.map((s) => 
      AudioSource.uri(Uri.parse(s.streamUrl))
    ).toList());

    await _player.setAudioSource(_playlist, initialIndex: initialIndex);
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> seek(Duration position) => _player.seek(position);
  
  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> skipToNext() => _player.seekToNext();
  Future<void> skipToPrevious() => _player.seekToPrevious();

  Future<void> setShuffleMode(bool enabled) async {
    _player.setShuffleModeEnabled(enabled);
    if (enabled) {
      await _player.shuffle();
    }
  }

  Future<void> setRepeatMode(bool all, bool one) async {
    _player.setLoopMode(one 
        ? LoopMode.one 
        : all ? LoopMode.all : LoopMode.off);
  }

  // Expose streams untuk UI
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  AudioPlayer get player => _player;
  bool get playing => _player.playing;
  
  // Cleanup
  void dispose() {
    _player.dispose();
    _currentSongController.close();
    _isPlayingController.close();
    _queueController.close();
  }
}
