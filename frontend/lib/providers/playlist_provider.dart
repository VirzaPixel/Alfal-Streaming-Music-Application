import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../services/playlist_service.dart';
import 'auth_provider.dart';

final playlistServiceProvider = Provider((_) => PlaylistService());

final playlistsProvider = FutureProvider.autoDispose<List<PlaylistModel>>((ref) async {
  // Watch auth to ensure we re-fetch when session changes
  final auth = ref.watch(authProvider);
  if (auth.user == null || auth.user!.isGuest) return [];
  
  return ref.watch(playlistServiceProvider).listPlaylists();
});

final playlistDetailProvider = FutureProvider.family<PlaylistModel, int>((ref, id) async {
  return ref.read(playlistServiceProvider).getPlaylist(id);
});

final suggestedSongsProvider = FutureProvider<List<SongModel>>((ref) async {
  try {
    final supabase = Supabase.instance.client;
    final res = await supabase.from('songs')
        .select('id, title, artist, album, genre, duration_seconds, cover_url, audio_url, play_count')
        .limit(10);
    return (res as List).map((e) => SongModel.fromJson(e)).toList();
  } catch (e) {
    // Return empty list instead of crashing if database access is restricted
    return [];
  }
});

final likedSongsProvider = FutureProvider.autoDispose<List<SongModel>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.user == null || auth.user!.isGuest) return [];
  
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
