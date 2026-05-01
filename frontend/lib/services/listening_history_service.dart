import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';

final listeningHistoryProvider = StateNotifierProvider<ListeningHistoryNotifier, List<SongModel>>((ref) {
  return ListeningHistoryNotifier();
});

class ListeningHistoryNotifier extends StateNotifier<List<SongModel>> {
  ListeningHistoryNotifier() : super([]) {
    _loadHistory();
  }

  static const _key = 'listening_history';

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_key);
      if (data != null) {
        final List decoded = json.decode(data);
        final list = decoded.map((e) => SongModel.fromMap(e)).toList();
        state = list.take(20).toList(); // Ensure limit even on load
      }
    } catch (_) {}
  }

  Future<void> addSong(SongModel song) async {
    // Remove if exists to move to top
    final newList = state.where((s) => s.id != song.id).toList();
    newList.insert(0, song);
    
    // Strictly keep only the latest 20
    state = newList.take(20).toList();
    _saveHistory();
  }

  Future<void> clear() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = json.encode(state.map((s) => s.toMap()).toList());
      await prefs.setString(_key, data);
    } catch (_) {}
  }
}
