class UserModel {
  final String id;
  final String email;
  final String username;
  final String role;
  final String? avatarUrl;
  final String? createdAt;
  final int followerCount;
  final int followingCount;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    this.avatarUrl,
    this.createdAt,
    this.followerCount = 0,
    this.followingCount = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String? ?? '',
        username: json['username'] as String? ?? 'User',
        role: json['role'] as String? ?? 'user',
        avatarUrl: json['avatar_url'] as String?,
        createdAt: json['created_at'] as String?,
        followerCount: json['follower_count'] as int? ?? 0,
        followingCount: json['following_count'] as int? ?? 0,
      );

  bool get isAdmin => role == 'admin';
  bool get isCreator => role == 'creator' || role == 'admin';
  bool get isUser => role == 'user' || role == 'creator' || role == 'admin';
  bool get isGuest => role == 'guest';

  // Capabilities
  bool get canUpload => role == 'creator' || role == 'admin';
  bool get canManagePlaylists =>
      role == 'user' || role == 'creator' || role == 'admin';

  UserModel copyWith({
    String? username,
    String? avatarUrl,
    int? followerCount,
    int? followingCount,
  }) =>
      UserModel(
        id: id,
        email: email,
        username: username ?? this.username,
        role: role,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt,
        followerCount: followerCount ?? this.followerCount,
        followingCount: followingCount ?? this.followingCount,
      );
}
