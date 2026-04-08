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
    final normalizedEmail = email.trim().toLowerCase();
    
    final res = await _supabase.auth.signUp(
      email: normalizedEmail,
      password: password,
      data: {'username': username},
    );
    
    if (res.user == null) throw Exception('Registration failed');
    
    // CRITICAL FIX: After signUp, Supabase creates a temporary unconfirmed session
    // in device memory. This ghost session conflicts with OTP verification and makes
    // the token appear expired. We must sign out to clear it.
    // The OTP email is already sent at this point, so this does NOT affect delivery.
    final isConfirmed = res.user!.emailConfirmedAt != null;
    if (!isConfirmed) {
      await _supabase.auth.signOut();
    }
    
    return UserModel(
      id: res.user!.id,
      email: email,
      username: username,
      role: 'user',
    );
  }

  Future<UserModel> verifyOTP(String email, String token) async {
    final normalizedEmail = email.trim().toLowerCase();
    
    final res = await _supabase.auth.verifyOTP(
      email: normalizedEmail,
      token: token.trim(),
      type: OtpType.signup,
    );

    if (res.user == null) {
      throw Exception('Verification failed: No user returned');
    }

    try {
      return await getProfile(res.user!.id);
    } catch (_) {
      // If profile is not ready yet, return a basic user model
      return UserModel(
        id: res.user!.id,
        email: email,
        username: res.user!.userMetadata?['username'] ?? 'User',
        role: 'user',
      );
    }
  }

  Future<void> resendOTP(String email) async {
    await _supabase.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  bool get isSessionActive => _supabase.auth.currentSession != null;

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
      if (authUser != null) {
        return UserModel(
          id: id,
          email: authUser.email ?? '',
          username: authUser.userMetadata?['username'] ?? 'User',
          role: 'user',
        );
      }
      throw Exception('Profile not available: ${e.message}');
    }
  }
}
