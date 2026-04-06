import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song_model.dart';

class SongService {
  final _supabase = Supabase.instance.client;

  Future<({List<SongModel> songs, int total, int page})> listSongs({
    int page = 1,
    int limit = 20,
  }) async {
    final from = (page - 1) * limit;
    final to = from + limit - 1;

    // We exclude lyrics column for list views to save bandwidth/memory
    final res = await _supabase
        .from('songs')
        .select('id, title, artist, album, genre, duration_seconds, cover_url, audio_url, play_count, created_at')
        .order('created_at', ascending: false)
        .range(from, to);
    
    final list = res
        .map((e) => SongModel.fromJson(e))
        .toList();

    return (
      songs: list,
      total: list.length, // Simpler for now
      page: page,
    );
  }

  Future<SongModel> getSong(int id) async {
    final data = await _supabase.from('songs').select().eq('id', id).single();
    return SongModel.fromJson(data);
  }

  Future<List<SongModel>> search(String query) async {
    // Exclude lyrics for search results as well
    final res = await _supabase
        .from('songs')
        .select('id, title, artist, album, genre, duration_seconds, cover_url, audio_url, play_count')
        .or('title.ilike.%$query%,artist.ilike.%$query%')
        .limit(30); // Add a sensible limit for search

    return res.map((e) => SongModel.fromJson(e)).toList();
  }

  Future<bool> isLiked(int songId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final res = await _supabase
        .from('liked_songs')
        .select()
        .eq('user_id', userId)
        .eq('song_id', songId)
        .maybeSingle();
    return res != null;
  }

  Future<void> likeSong(int songId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase.from('liked_songs').upsert({'user_id': userId, 'song_id': songId});
  }

  Future<void> unlikeSong(int songId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('liked_songs')
        .delete()
        .eq('user_id', userId)
        .eq('song_id', songId);
  }

  Future<List<SongModel>> getLikedSongs() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final res = await _supabase
        .from('liked_songs')
        .select('songs:song_id(*)')
        .eq('user_id', userId);

    return res.map((e) => SongModel.fromJson(e['songs'])).toList();
  }
}
