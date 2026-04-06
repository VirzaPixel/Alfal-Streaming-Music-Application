import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  Future<UserModel> login(String email, String password) async {
    final res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (res.user == null) throw Exception('Login failed');
    return await getProfile(res.user!.id);
  }

  Future<UserModel> register(String email, String username, String password) async {
    final res = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
    
    if (res.user == null) throw Exception('Registration failed');
    
    // For unconfirmed users, return a temporary model
    // Profile will be created by a Supabase trigger or after email confirm
    return UserModel(
      id: res.user!.id,
      email: email,
      username: username,
      role: 'user',
    );
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  UserModel? get currentUser {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      username: user.userMetadata?['username'] ?? 'User',
      role: 'user',
    );
  }

  Future<UserModel> updateProfile({String? username, String? avatarUrl}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in.');

    try {
      // 1. Update the profiles table
      final Map<String, dynamic> updates = {
        'id': user.id,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (username != null && username.isNotEmpty) updates['username'] = username;
      if (avatarUrl != null && avatarUrl.isNotEmpty) updates['avatar_url'] = avatarUrl;

      await _supabase.from('profiles').upsert(updates);

      // 2. Also update auth user metadata so it's consistent
      if (username != null && username.isNotEmpty) {
        await _supabase.auth.updateUser(
          UserAttributes(data: {'username': username}),
        );
      }

      return await getProfile(user.id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update profile: ${e.message}');
    }
  }

  Future<UserModel> getProfile(String id) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .single();
      
      final authUser = _supabase.auth.currentUser;
      final json = Map<String, dynamic>.from(data);
      json['email'] = authUser?.email ?? '';
      
      return UserModel.fromJson(json);
    } on PostgrestException catch (e) {
      // Profile might not exist yet (e.g., after register without confirm)
      // Build a basic model from auth data
      final authUser = _supabase.auth.currentUser;
      throw Exception('Profile not available: ${e.message}. Email: ${authUser?.email}');
    }
  }
}
