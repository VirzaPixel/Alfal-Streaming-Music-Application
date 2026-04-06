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
    id: json['id'] as int,
    userId: json['user_id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    coverUrl: json['cover_url'] as String?,
    songs: (json['songs'] as List<dynamic>? ?? [])
        .map((s) => SongModel.fromJson(s as Map<String, dynamic>))
        .toList(),
    createdAt: json['created_at'] as String?,
  );
}
