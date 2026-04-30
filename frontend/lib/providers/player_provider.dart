import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song_model.dart';
import '../models/user_model.dart';
import '../services/song_service.dart';
import '../services/connection_service.dart';
import '../services/listening_history_service.dart';
import '../app.dart'; // To access global audioHandler

enum RepeatMode { off, all, one }

// ── Player State ──────────────────────────────────────────────
class PlayerState {
  final SongModel? currentSong;
  final String? sourceName;
  final bool isPlaying;
  final bool shuffle;
  final RepeatMode repeatMode;
  final Duration position;
  final Duration duration;
  final List<SongModel> queue;

  const PlayerState({
    this.currentSong,
    this.sourceName,
    this.isPlaying = false,
    this.shuffle = false,
    this.repeatMode = RepeatMode.off,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
  });

  bool get hasSong => currentSong != null;

  PlayerState copyWith({
    SongModel? currentSong,
    String? sourceName,
    bool? isPlaying,
    bool? shuffle,
    RepeatMode? repeatMode,
    Duration? position,
    Duration? duration,
    List<SongModel>? queue,
    bool clearSong = false,
    bool clearSource = false,
  }) =>
      PlayerState(
        currentSong: clearSong ? null : currentSong ?? this.currentSong,
        sourceName: clearSource ? null : sourceName ?? this.sourceName,
        isPlaying: isPlaying ?? this.isPlaying,
        shuffle: shuffle ?? this.shuffle,
        repeatMode: repeatMode ?? this.repeatMode,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        queue: queue ?? this.queue,
      );
}

// ── Player Notifier ────────────────────────────────────────────
class PlayerNotifier extends StateNotifier<PlayerState> {
  final Ref ref;
  // Use the global handler casted to our implementation
  AlfalAudioHandler get _handler => audioHandler;

  PlayerNotifier(this.ref) : super(const PlayerState()) {
    _listenStreams();
  }

  void _listenStreams() {
    // Listen to playback state dari handler (tanpa AudioService)
    _handler.isPlayingStream.listen((playing) {
      if (!mounted) return;
      state = state.copyWith(isPlaying: playing);
    });

    // Listen to current song
    _handler.currentSongStream.listen((song) {
      if (!mounted) return;
      state = state.copyWith(currentSong: song);
      if (song != null) {
        ref.read(listeningHistoryProvider.notifier).addSong(song);
      }
    });

    // Listen to position
    _handler.positionStream.listen((pos) {
      if (!mounted) return;
      state = state.copyWith(position: pos);
    });

    // Listen to duration
    _handler.durationStream.listen((dur) {
      if (!mounted) return;
      if (dur != null) state = state.copyWith(duration: dur);
    });

    // Listen to queue changes
    _handler.queueStream.listen((q) {
      if (!mounted) return;
      state = state.copyWith(queue: q);
    });
  }

  Future<void> playSong(SongModel song, {List<SongModel>? queue, String? sourceName}) async {
    final q = queue ?? [song];
    final index = q.indexWhere((s) => s.id == song.id);
    
    await _handler.setSongs(q, initialIndex: index >= 0 ? index : 0);
    _handler.play();

    state = state.copyWith(
      sourceName: sourceName,
      clearSource: sourceName == null,
    );
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await _handler.pause();
    } else {
      await _handler.play();
    }
  }

  Future<void> seekTo(Duration pos) => _handler.seek(pos);
  Future<void> next() => _handler.skipToNext();
  Future<void> previous() => _handler.skipToPrevious();

  void setShuffle(bool value) {
    if (state.shuffle == value) return;
    state = state.copyWith(shuffle: value);
    _handler.setShuffleMode(value);
  }

  void toggleShuffle() {
    final newValue = !state.shuffle;
    setShuffle(newValue);
  }

  void toggleRepeat() {
    final nextMode = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    
    state = state.copyWith(repeatMode: nextMode);
    _handler.setRepeatMode(
      nextMode == RepeatMode.all, 
      nextMode == RepeatMode.one
    );
  }

  Future<void> setVolume(double v) => _handler.player.setVolume(v);

  Future<void> stop() async {
    await _handler.stop();
    state = state.copyWith(
      clearSong: true,
      isPlaying: false,
      position: Duration.zero,
    );
  }
}

// ── Providers ─────────────────────────────────────────────────

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>(
  (ref) => PlayerNotifier(ref),
);

final songServiceProvider = Provider((_) => SongService());
final connectionServiceProvider = Provider((_) => ConnectionService());

final songsProvider = FutureProvider.autoDispose<List<SongModel>>((ref) async {
  final svc = ref.watch(songServiceProvider);
  final result = await svc.listSongs(limit: 50);
  return result.songs;
});

final searchQueryProvider = StateProvider<String>((_) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final q = ref.watch(searchQueryProvider);
  if (q.trim().isEmpty) return [];
  
  final songSvc = ref.watch(songServiceProvider);
  final userSvc = ref.watch(connectionServiceProvider);

  // Run searches in parallel
  final results = await Future.wait([
    songSvc.search(q),
    userSvc.searchUsers(q),
  ]);

  final songs = results[0] as List<SongModel>;
  final users = results[1] as List<UserModel>;

  return [...users, ...songs];
});

final artistsProvider =
    FutureProvider.autoDispose<Map<String, List<SongModel>>>((ref) async {
  final songsAsync = await ref.watch(songsProvider.future);
  final Map<String, List<SongModel>> grouped = {};
  for (final s in songsAsync) {
    grouped.putIfAbsent(s.artist, () => []).add(s);
  }
  return grouped;
});
