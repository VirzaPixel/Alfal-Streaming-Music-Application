import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

// MAGIC IMPORT SERVICE - POWERED BY PYTHON MUSIC AGENT
// Flutter → agent_server.py (localhost:8080) → music_agent.py → Cloudinary + Supabase
//
// CARA PAKAI:
//   1. Jalankan server: python scripts/agent_server.py
//   2. Buka Flutter app → Magic Import

class MagicImportService {
  final _client = Supabase.instance.client;

  // GANTI INI dengan URL dari dashboard Render kamu!
  static const String _serverBase = 'https://alfal-music-agent.onrender.com';
  
  // Timeout lebih lama (2 menit) buat jaga-jaga kalau server Render lagi "bangun" dari tidur

  // ── 1. CHECK SERVER ───────────────────────────────────────────────────

  Future<bool> isServerOnline() async {
    try {
      final res = await http
          .get(Uri.parse('$_serverBase/health'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── 2. SEARCH METADATA via Python Agent Server (Deezer) ───────────────

  Future<List<Map<String, dynamic>>> searchMetadata(String query) async {
    try {
      final res = await http
          .get(Uri.parse('$_serverBase/search?q=${Uri.encodeComponent(query)}'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List results = json.decode(res.body)['results'] ?? [];
        return results.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      throw 'Gagal terhubung ke Agent Server. Pastikan server berjalan!\nJalankan: python scripts/agent_server.py';
    }
    return [];
  }

  // ── 3. DUPLICATE CHECK ────────────────────────────────────────────────

  Future<bool> checkIfExists(String title, String artist) async {
    final res = await _client
        .from('songs')
        .select('id')
        .eq('title', title)
        .eq('artist', artist)
        .maybeSingle();
    return res != null;
  }

  /// Batch-check multiple songs sekaligus → 1 query Supabase.
  /// Returns Set of "title|||artist" (lowercase) yang sudah ada di DB.
  Future<Set<String>> batchCheckExists(List<Map<String, dynamic>> songs) async {
    if (songs.isEmpty) return {};
    try {
      final titles = songs
          .map((s) => (s['title'] as String? ?? '').trim())
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList();

      final res = await _client
          .from('songs')
          .select('title, artist')
          .inFilter('title', titles);

      final existing = <String>{};
      for (final row in (res as List)) {
        final key = '${row['title']}|||${row['artist']}';
        existing.add(key.toLowerCase());
      }
      return existing;
    } catch (_) {
      return {};
    }
  }

  // ── 4. IMPORT via Python Agent (Full Pipeline) ────────────────────────
  // Server runs: Deezer → yt-dlp → Cloudinary → Supabase
  // Flutter polls job status every 2 seconds

  Future<void> importSong(
    Map<String, dynamic> metadata, {
    Function(String)? onProgress,
  }) async {
    // Build query string from metadata
    final query = '${metadata['artist']} ${metadata['title']}';

    // Step 1: Start job
    onProgress?.call('Mengirim ke Music Agent...');
    late String jobId;
    try {
      final res = await http
          .post(
            Uri.parse('$_serverBase/import'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'query': query}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw 'Agent Server error: ${res.body}';
      }
      jobId = json.decode(res.body)['job_id'] as String;
    } catch (e) {
      throw 'Gagal memulai import. Pastikan server berjalan!\nJalankan: python scripts/agent_server.py\n\nError: $e';
    }

    // Step 2: Poll job status
    onProgress?.call('Menunggu Agent...');
    const maxWait = Duration(minutes: 5);
    const pollInterval = Duration(seconds: 2);
    final deadline = DateTime.now().add(maxWait);

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(pollInterval);

      try {
        final statusRes = await http
            .get(Uri.parse('$_serverBase/import/$jobId'))
            .timeout(const Duration(seconds: 5));

        if (statusRes.statusCode == 200) {
          final body = json.decode(statusRes.body) as Map<String, dynamic>;
          final status = body['status'] as String? ?? '';
          final progress = body['progress'] as String? ?? '';
          final error = body['error'] as String?;

          // Update UI with live progress
          if (progress.isNotEmpty) {
            onProgress?.call(progress);
          }

          if (status == 'done') return; // ✅ Success!
          if (status == 'error') throw error ?? 'Import gagal.';
        }
      } catch (e) {
        if (e is String) rethrow;
        // Network hiccup, retry
      }
    }

    throw 'Import timeout (>5 menit). Cek terminal server untuk detail.';
  }

  void dispose() {}
}
