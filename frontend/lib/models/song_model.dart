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
      id: json['id']?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Unknown Title',
      artist: json['artist']?.toString() ?? 'Unknown Artist',
      album: json['album']?.toString(),
      genre: json['genre']?.toString(),
      durationSeconds: json['duration_seconds']?.toInt() ?? 0,
      coverKey: json['cover_key']?.toString() ?? rawCover,
      coverUrl: finalCoverUrl,
      streamUrl: finalStreamUrl,
      playCount: json['play_count']?.toInt() ?? 0,
      lyrics: json['lyrics']?.toString(),
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'duration_seconds': durationSeconds,
      'cover_key': coverKey,
      'cover_url': coverUrl,
      'stream_url': streamUrl,
      'play_count': playCount,
      'lyrics': lyrics,
    };
  }

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id']?.toInt() ?? 0,
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      album: map['album'],
      genre: map['genre'],
      durationSeconds: map['duration_seconds']?.toInt() ?? 0,
      coverKey: map['cover_key'],
      coverUrl: map['cover_url'] ?? '',
      streamUrl: map['stream_url'] ?? '',
      playCount: map['play_count']?.toInt() ?? 0,
      lyrics: map['lyrics'],
    );
  }
}
