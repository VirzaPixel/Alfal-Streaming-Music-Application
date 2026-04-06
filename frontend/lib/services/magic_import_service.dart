import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// REFACTORED MAGIC IMPORT SERVICE
// CLEANER, ROBUST, ERROR-RESISTANT

class MagicImportService {
  final _yt = YoutubeExplode();
  final _client = Supabase.instance.client;

  // Configurations
  String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  String get _uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
  String get _ytmKey => dotenv.env['YTM_KEY'] ?? '';

  // 1. Search Music (Apple Music / ITunes as Base Meta)
  Future<List<Map<String, dynamic>>> searchMetadata(String query) async {
    final res = await http.get(Uri.parse('https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&entity=song&limit=10'));
    if (res.statusCode != 200) return [];
    
    final List results = json.decode(res.body)['results'] ?? [];
    return results.map((r) => {
      'title': r['trackName'] ?? 'Unknown',
      'artist': r['artistName'] ?? 'Unknown Artist',
      'album': r['collectionName'] ?? 'Single',
      'genre': r['primaryGenreName'] ?? 'Music',
      'cover_url': (r['artworkUrl100'] as String? ?? '').replaceAll('100x100bb', '600x600bb'),
      'itunes_url': r['trackViewUrl'] ?? '',
      'duration_ms': (r['trackTimeMillis'] ?? 0) as int,
    }).toList();
  }

  // 2. Discover Content ID (YouTube)
  Future<String?> findYouTubeId(String artist, String title) async {
    final searchQ = '$artist $title official audio';
    
    // Method 1: YouTube Search API Context
    try {
      final res = await http.post(
        Uri.parse('https://music.youtube.com/youtubei/v1/search?key=$_ytmKey'),
        headers: {'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'},
        body: json.encode({
          'context': {'client': {'clientName': 'WEB_REMIX', 'clientVersion': '1.20231204.01.00'}}, 
          'query': searchQ,
          'params': 'EgWKAQIIAWoEEAMQBw%3D%3D' 
        }),
      );
      final match = RegExp(r'"videoId"\s*:\s*"([a-zA-Z0-9_-]{11})"').firstMatch(res.body);
      if (match != null) return match.group(1);
    } catch (_) {}

    // Method 2: Native Search
    try {
      final searchRes = await _yt.search.search(searchQ).timeout(const Duration(seconds: 8));
      if (searchRes.isNotEmpty) return searchRes.first.id.value;
    } catch (_) {}

    return null;
  }

  // 3. Process Import (Pipeline)
  Future<void> importSong(Map<String, dynamic> metadata, {Function(String)? onProgress}) async {
    try {
      onProgress?.call('Pencarian ID YouTube...');
      final vId = await findYouTubeId(metadata['artist'], metadata['title']);
      if (vId == null) throw 'Gagal menemukan konten di server YouTube.';

      onProgress?.call('Ekstraksi Audio...');
      final manifest = await _yt.videos.streamsClient.getManifest(vId);
      final audioStream = manifest.audioOnly.where((s) => s.container.name == 'mp4').withHighestBitrate();
      final streamUrl = audioStream.url.toString();

      onProgress?.call('Sinkronisasi Server (Cloudinary)...');
      final pId = '${_cleanStr(metadata['artist'])}_${_cleanStr(metadata['title'])}_${DateTime.now().millisecondsSinceEpoch}';
      final uRes = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/video/upload'),
        body: {
          'file': streamUrl, 
          'upload_preset': _uploadPreset, 
          'folder': 'alfal', 
          'public_id': pId, 
          'resource_type': 'video'
        },
      ).timeout(const Duration(seconds: 120));

      if (uRes.statusCode != 200) throw 'Upload Error: ${uRes.body}';
      final finalAudioUrl = json.decode(uRes.body)['secure_url'] as String;

      onProgress?.call('Menyimpan Metadata...');
      await _client.from('songs').insert({
        'title': metadata['title'], 
        'artist': metadata['artist'], 
        'album': metadata['album'], 
        'genre': metadata['genre'], 
        'duration_seconds': (metadata['duration_ms'] / 1000).round(),
        'cover_url': metadata['cover_url'], 
        'audio_url': finalAudioUrl,
      });

    } catch (e) {
      rethrow;
    }
  }

  String _cleanStr(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

  void dispose() {
    _yt.close();
  }
}
