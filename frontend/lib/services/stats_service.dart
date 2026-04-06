import 'package:supabase_flutter/supabase_flutter.dart';

class StatsService {
  final _client = Supabase.instance.client;

  // 1. Log a play
  Future<void> logPlay({required String userId, required int song_id, required int durationSeconds}) async {
    await _client.from('listening_history').insert({
      'user_id': userId,
      'song_id': song_id,
      'duration_seconds': durationSeconds,
    });
    
    // Also increment song play count (optional, can be done via database trigger)
    await _client.rpc('increment_song_play_count', params: {'row_id': song_id});
  }

  // 2. Fetch User Stats
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final res = await _client.rpc('get_user_stats', params: {'p_user_id': userId});
    return (res as Map<String, dynamic>);
  }
}
