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
    // We join follows table to get counts
    final res = await _client
        .from('profiles')
        .select('''
          *,
          follower_count:follows!following_id(count),
          following_count:follows!follower_id(count)
        ''')
        .eq('id', userId)
        .single();
    
    // Supabase returns count as a list of dictionaries if using joins, 
    // but with maybeSingle and proper alias it's easier.
    // However, for simplicity in SQL logic, we can also use RPC or separate queries if counts are tricky.
    
    final data = Map<String, dynamic>.from(res);
    // Extract counts from the aggregate results
    data['follower_count'] = (res['follower_count'] as List).isNotEmpty ? res['follower_count'][0]['count'] : 0;
    data['following_count'] = (res['following_count'] as List).isNotEmpty ? res['following_count'][0]['count'] : 0;

    return UserModel.fromJson(data);
  }

  // 5. Search Users
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    final res = await _client
        .from('profiles')
        .select()
        .ilike('username', '%$query%')
        .limit(20);
    
    return (res as List).map((json) => UserModel.fromJson(json)).toList();
  }
}
