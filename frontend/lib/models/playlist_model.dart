import 'song_model.dart';

class PlaylistModel {
  final int id;
  final String userId;
  final String name;
  final String? description;
  final String? coverUrl;
  final List<SongModel> songs;
  final String? createdAt;

  const PlaylistModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.coverUrl,
    this.songs = const [],
    this.createdAt,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) => PlaylistModel(
    id: json['id']?.toInt() ?? 0,
    userId: json['user_id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Untitled Playlist',
    description: json['description']?.toString(),
    coverUrl: json['cover_url']?.toString(),
    songs: (json['songs'] as List<dynamic>? ?? [])
        .map((s) => SongModel.fromJson(s as Map<String, dynamic>))
        .toList(),
    createdAt: json['created_at']?.toString(),
  );
}
