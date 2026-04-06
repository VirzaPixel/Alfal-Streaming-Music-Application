import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/song_model.dart';
import '../models/user_model.dart';
import '../services/audio_service.dart';
import '../services/song_service.dart';
import '../services/connection_service.dart';

// ── Player State ──────────────────────────────────────────────
class PlayerState {
  final SongModel? currentSong;
  final String? sourceName;
  final bool isPlaying;
  final bool shuffle;
  final bool repeat;
  final Duration position;
  final Duration duration;
  final List<SongModel> queue;

  const PlayerState({
    this.currentSong,
    this.sourceName,
    this.isPlaying = false,
    this.shuffle = false,
    this.repeat = false,
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
    bool? repeat,
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
        repeat: repeat ?? this.repeat,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        queue: queue ?? this.queue,
      );
}

// ── Player Notifier ────────────────────────────────────────────
class PlayerNotifier extends StateNotifier<PlayerState> {
  final AudioService _audio = AudioService();

  PlayerNotifier() : super(const PlayerState()) {
    _listenStreams();
  }

  void _listenStreams() {
    _audio.playerStateStream.listen((ps) {
      state = state.copyWith(isPlaying: ps.playing);
    });
    _audio.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });
    _audio.durationStream.listen((dur) {
      if (dur != null) state = state.copyWith(duration: dur);
    });
    // Sync current song accurately
    _audio.currentSongStream.listen((song) {
      if (song == null) {
        state = state.copyWith(clearSong: true, isPlaying: false);
      } else {
        state = state.copyWith(currentSong: song, queue: _audio.queue);
      }
    });
  }

  void playSong(SongModel song, {List<SongModel>? queue, String? sourceName}) {
    final q = queue ?? [song];
    _audio.play(song, queue: q);
    // State will be updated by streams in _listenStreams
    // But we can set the song immediately for UI feel
    state = state.copyWith(
      currentSong: song,
      queue: q,
      sourceName: sourceName,
      clearSource: sourceName == null,
      position: Duration.zero,
    );
  }

  Future<void> togglePlayPause() async {
    // Use direct player state to avoid any lag from the stream-based state
    if (_audio.player.playing) {
      await _audio.pause();
    } else {
      await _audio.resume();
    }
  }

  Future<void> seekTo(Duration pos) => _audio.seekTo(pos);

  Future<void> next() async {
    await _audio.next();
    state = state.copyWith(currentSong: _audio.currentSong);
  }

  Future<void> previous() async {
    await _audio.previous();
    state = state.copyWith(currentSong: _audio.currentSong);
  }

  void toggleShuffle() {
    _audio.toggleShuffle();
    state = state.copyWith(shuffle: _audio.shuffle);
  }

  void toggleRepeat() {
    _audio.toggleRepeat();
    state = state.copyWith(repeat: _audio.repeat);
  }

  Future<void> setVolume(double v) => _audio.setVolume(v);

  void updateCurrentSong(SongModel updatedSong) {
    if (state.currentSong?.id == updatedSong.id) {
      state = state.copyWith(currentSong: updatedSong);
    }
  }

  Future<void> stop() async {
    await _audio.stop();
    state = state.copyWith(
      clearSong: true,
      isPlaying: false,
      position: Duration.zero,
    );
  }
}

// ── Providers ─────────────────────────────────────────────────

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>(
  (ref) => PlayerNotifier(),
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
