import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class ConnectionService {
  final _client = Supabase.instance.client;

  // 1. Follow a user
  Future<void> followUser(String followerId, String targetUserId) async {
    await _client.from('follows').insert({
      'follower_id': followerId,
      'following_id': targetUserId,
    });
  }

  // 2. Unfollow a user
  Future<void> unfollowUser(String followerId, String targetUserId) async {
    await _client
        .from('follows')
        .delete()
        .match({'follower_id': followerId, 'following_id': targetUserId});
  }

  // 3. Check if following
  Future<bool> isFollowing(String followerId, String targetUserId) async {
    final res = await _client
        .from('follows')
        .select()
        .match({'follower_id': followerId, 'following_id': targetUserId})
        .maybeSingle();
    return res != null;
  }

  // 4. Get User Profile with follower counts
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final res = await _client
          .from('profiles')
          .select('''
            *,
            follower_count:follows!following_id(count),
            following_count:follows!follower_id(count),
            playlist_count:playlists(count)
          ''')
          .eq('id', userId)
          .single();
      
      final data = Map<String, dynamic>.from(res);
      data['follower_count'] = (res['follower_count'] as List).isNotEmpty ? res['follower_count'][0]['count'] : 0;
      data['following_count'] = (res['following_count'] as List).isNotEmpty ? res['following_count'][0]['count'] : 0;
      data['playlist_count'] = (res['playlist_count'] as List).isNotEmpty ? res['playlist_count'][0]['count'] : 0;

      return UserModel.fromJson(data);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST200') {
        // Fallback if relationships don't exist yet
        final res = await _client.from('profiles').select().eq('id', userId).single();
        final data = Map<String, dynamic>.from(res);
        data['follower_count'] = 0;
        data['following_count'] = 0;
        data['playlist_count'] = 0;
        return UserModel.fromJson(data);
      }
      rethrow;
    }
  }

  // 5. Get Followers List
  Future<List<UserModel>> getFollowers(String userId) async {
    final res = await _client
        .from('follows')
        .select('''
          follower_id,
          profiles!follower_id(*)
        ''')
        .eq('following_id', userId);
    
    return (res as List).map((json) => UserModel.fromJson(json['profiles'])).toList();
  }

  // 6. Get Following List
  Future<List<UserModel>> getFollowing(String userId) async {
    final res = await _client
        .from('follows')
        .select('''
          following_id,
          profiles!following_id(*)
        ''')
        .eq('follower_id', userId);
    
    return (res as List).map((json) => UserModel.fromJson(json['profiles'])).toList();
  }

  // 7. Search Users
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    // Admins are hidden from search results for security
    final res = await _client
        .from('profiles')
        .select()
        .ilike('username', '%$query%')
        .neq('role', 'admin')
        .limit(20);
    
    return (res as List).map((json) => UserModel.fromJson(json)).toList();
  }
}
