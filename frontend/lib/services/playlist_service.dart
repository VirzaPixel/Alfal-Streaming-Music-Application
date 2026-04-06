import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';

class PlaylistService {
  final _supabase = Supabase.instance.client;

  Future<List<PlaylistModel>> listPlaylists() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final res = await _supabase
        .from('playlists')
        .select('*, songs:playlist_songs(songs(id, title, artist, album, genre, duration_seconds, cover_url, audio_url, play_count))')
        .eq('user_id', userId) 
        .order('created_at', ascending: false);
    
    return res
        .map((e) => _mapPlaylistAndSongs(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getUserPlaylists(String userId) async {
    final res = await _supabase
        .from('playlists')
        .select('id, name, cover_url')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<PlaylistModel> getPlaylist(int id) async {
    final res = await _supabase
        .from('playlists')
        .select('*, songs:playlist_songs(songs(id, title, artist, album, genre, duration_seconds, cover_url, audio_url, play_count))')
        .eq('id', id)
        .single();
    
    return _mapPlaylistAndSongs(res);
  }

  Future<PlaylistModel> createPlaylist(String name, {String? desc}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in — please sign in first.');

    try {
      final res = await _supabase.from('playlists').insert({
        'user_id': userId,
        'name': name,
        if (desc != null && desc.isNotEmpty) 'description': desc,
      }).select().single();

      return PlaylistModel.fromJson(res);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create playlist: ${e.message}');
    }
  }

  Future<void> deletePlaylist(int id) async {
    try {
      await _supabase.from('playlists').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete playlist: ${e.message}');
    }
  }

  Future<void> addSong(int playlistId, int songId) async {
    try {
      await _supabase.from('playlist_songs').insert({
        'playlist_id': playlistId,
        'song_id': songId,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Song is already in this playlist.');
      }
      throw Exception('Failed to add song: ${e.message}');
    }
  }

  Future<void> removeSong(int playlistId, int songId) async {
    await _supabase
        .from('playlist_songs')
        .delete()
        .eq('playlist_id', playlistId)
        .eq('song_id', songId);
  }

  Future<PlaylistModel> updatePlaylist(int id,
      {String? name, String? desc, String? coverUrl}) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (desc != null) updates['description'] = desc;
      if (coverUrl != null) updates['cover_url'] = coverUrl;

      final res = await _supabase
          .from('playlists')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return PlaylistModel.fromJson(res);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update playlist: ${e.message}');
    }
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
    if (userId == null) throw Exception('Please login first.');
    try {
      await _supabase.from('liked_songs').upsert({
        'user_id': userId,
        'song_id': songId,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to like song: ${e.message}');
    }
  }

  Future<void> unlikeSong(int songId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Please login first.');
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
        .select('songs:song_id(id, title, artist, album, genre, duration_seconds, cover_url, audio_url, play_count)')
        .eq('user_id', userId);
    return res
        .map((e) => SongModel.fromJson(e['songs']))
        .toList();
  }

  // ── Helper ──────────────────────────────────────────────────
  PlaylistModel _mapPlaylistAndSongs(Map<String, dynamic> data) {
    final List<dynamic> junction = data['songs'] as List<dynamic>? ?? [];
    final songs = junction
        .where((e) => e['songs'] != null)
        .map((e) => SongModel.fromJson(e['songs'] as Map<String, dynamic>))
        .toList();
    
    return PlaylistModel(
      id: data['id'] as int,
      userId: data['user_id'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      coverUrl: data['cover_url'] as String?,
      songs: songs,
      createdAt: data['created_at'] as String?,
    );
  }
}
