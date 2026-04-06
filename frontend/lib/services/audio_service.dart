import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';

/// Wraps just_audio and exposes a simple API for the rest of the app.
class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._() {
    _player.sequenceStateStream.listen((state) {
      if (state == null) return;
      final index = state.currentIndex;
      if (index >= 0 && index < _queue.length) {
        _currentSong = _queue[index];
        _songController.add(_currentSong);
      }
    });

    _player.playerStateStream.listen((ps) {
      // When the entire playlist finishes
      if (ps.processingState == ProcessingState.completed) {
        stop();
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  final _songController = StreamController<SongModel?>.broadcast();
  ConcatenatingAudioSource? _playlist;

  AudioPlayer get player => _player;

  SongModel? _currentSong;
  SongModel? get currentSong => _currentSong;

  List<SongModel> _queue = [];
  bool _shuffle = false;
  bool _repeat = false;

  bool get isPlaying => _player.playing;
  bool get shuffle => _shuffle;
  bool get repeat => _repeat;
  List<SongModel> get queue => List.unmodifiable(_queue);

  Stream<SongModel?> get currentSongStream async* {
    yield _currentSong;
    yield* _songController.stream;
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlaybackEvent> get playbackEventStream => _player.playbackEventStream;

  /// Plays a song (optionally setting a new queue).
  Future<void> play(
    SongModel song, {
    List<SongModel>? queue,
  }) async {
    if (queue != null) {
      _queue = queue;
      _playlist = ConcatenatingAudioSource(
        useLazyPreparation: true,
        children: _queue.map((s) {
          return AudioSource.uri(Uri.parse(s.streamUrl));
        }).toList(),
      );

      final index = _queue.indexWhere((s) => s.id == song.id);
      await _player.setAudioSource(_playlist!,
          initialIndex: index >= 0 ? index : 0);
    } else if (_currentSong?.id == song.id) {
      if (!_player.playing) {
        await _player.play();
      }
      return;
    } else if (_queue.isNotEmpty) {
      final index = _queue.indexWhere((s) => s.id == song.id);
      if (index >= 0) {
        await _player.seek(Duration.zero, index: index);
      }
    }

    _currentSong = song;
    _songController.add(song);
    _player.play();
  }

  Future<void> resume() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> seekTo(Duration pos) => _player.seek(pos);

  Future<void> next() => _player.seekToNext();
  Future<void> previous() => _player.seekToPrevious();

  void toggleShuffle() {
    _shuffle = !_shuffle;
    _player.setShuffleModeEnabled(_shuffle);
  }

  void toggleRepeat() {
    _repeat = !_repeat;
    _player.setLoopMode(_repeat ? LoopMode.one : LoopMode.off);
  }

  Future<void> setVolume(double volume) =>
      _player.setVolume(volume.clamp(0.0, 1.0));

  Future<void> stop() async {
    await _player.stop();
    _currentSong = null;
    _songController.add(null);
  }

  Future<void> dispose() => _player.dispose();
}
