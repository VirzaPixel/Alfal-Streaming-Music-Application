import '../config/api_config.dart';

class SongModel {
  final int id;
  final String title;
  final String artist;
  final String? album;
  final String? genre;
  final int durationSeconds;
  final String? coverKey;
  final String coverUrl;
  final String streamUrl;
  final int playCount;
  final String? lyrics;

  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.genre,
    required this.durationSeconds,
    this.coverKey,
    required this.coverUrl,
    required this.streamUrl,
    required this.playCount,
    this.lyrics,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    // Supabase returns 'audio_url' and 'cover_url'
    // If they are just keys, we wrap them in our storage URL helper
    final rawAudio = json['audio_url'] as String? ?? '';
    final finalStreamUrl = rawAudio.startsWith('http') 
        ? rawAudio 
        : getStorageUrl(kSongsBucket, rawAudio);

    final rawCover = json['cover_url'] as String? ?? '';
    final finalCoverUrl = rawCover.startsWith('http') 
        ? rawCover 
        : (rawCover.isNotEmpty ? getStorageUrl(kCoversBucket, rawCover) : '');

    return SongModel(
      id: json['id'] as int,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String?,
      genre: json['genre'] as String?,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      coverKey: json['cover_key'] as String? ?? rawCover,
      coverUrl: finalCoverUrl,
      streamUrl: finalStreamUrl,
      playCount: json['play_count'] as int? ?? 0,
      lyrics: json['lyrics'] as String?,
    );
  }

  /// Duration formatted as m:ss
  String get durationLabel {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  SongModel copyWith({String? coverUrl, String? streamUrl, String? lyrics}) =>
      SongModel(
        id: id,
        title: title,
        artist: artist,
        album: album,
        genre: genre,
        durationSeconds: durationSeconds,
        coverKey: coverKey,
        coverUrl: coverUrl ?? this.coverUrl,
        streamUrl: streamUrl ?? this.streamUrl,
        playCount: playCount,
        lyrics: lyrics ?? this.lyrics,
      );
}
