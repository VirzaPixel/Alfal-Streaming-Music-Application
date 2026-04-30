import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AdminService {
  final _supabase = Supabase.instance.client;

  Future<List<UserModel>> listUsers() async {
    final res = await _supabase
        .from('profiles')
        .select()
        .order('username');
    
    return res.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    await _supabase
        .from('profiles')
        .update({'role': newRole})
        .eq('id', userId);
  }
}
