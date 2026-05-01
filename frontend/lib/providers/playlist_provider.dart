import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../services/playlist_service.dart';
import 'auth_provider.dart';

final playlistServiceProvider = Provider((_) => PlaylistService());

final playlistsProvider = FutureProvider.autoDispose<List<PlaylistModel>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.user == null) return [];
  
  return ref.watch(playlistServiceProvider).listPlaylists();
});

final playlistDetailProvider = FutureProvider.family<PlaylistModel, int>((ref, id) async {
  return ref.read(playlistServiceProvider).getPlaylist(id);
});

// Timer provider that updates every 1 minute to refresh suggested songs
final _suggestedSongsTimerProvider = StreamProvider<void>((ref) {
  return Stream.periodic(const Duration(minutes: 3));
});

final suggestedSongsProvider = FutureProvider<List<SongModel>>((ref) async {
  // Watch the timer to auto-refresh every minute
  ref.watch(_suggestedSongsTimerProvider);
  
  try {
    final supabase = Supabase.instance.client;
    // Get large pool of songs for randomization
    final res = await supabase.from('songs')
        .select('id, title, artist, album, genre, duration_seconds, cover_url, audio_url, play_count')
        .limit(100);
    
    final songs = (res as List).map((e) => SongModel.fromJson(e)).toList();
    // Shuffle the large pool to get truly random songs each time
    songs.shuffle();
    return songs.take(10).toList();
  } catch (e) {
    // Return empty list instead of crashing if database access is restricted
    return [];
  }
});

final likedSongsProvider = FutureProvider.autoDispose<List<SongModel>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.user == null) return [];
  
  return ref.watch(playlistServiceProvider).getLikedSongs();
});

final profileStatsProvider = FutureProvider.autoDispose((ref) async {
  final playlists = await ref.watch(playlistsProvider.future);
  final liked = await ref.watch(likedSongsProvider.future);
  return {
    'playlists': playlists.length,
    'liked': liked.length,
    'songs': '∞',
  };
});

final isLikedProvider = Provider.family.autoDispose<bool, int>((ref, songId) {
  final likedSongsAsync = ref.watch(likedSongsProvider);
  return likedSongsAsync.maybeWhen(
    data: (songs) => songs.any((s) => s.id == songId),
    orElse: () => false,
  );
});
