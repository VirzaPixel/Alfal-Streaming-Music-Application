import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/a_text_field.dart';
import '../../models/user_model.dart';
import '../../services/connection_service.dart';
import '../../services/stats_service.dart';
import '../../services/playlist_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? targetUserId; // NULL if viewing own profile
  const ProfileScreen({super.key, this.targetUserId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _connectionService = ConnectionService();
  final _statsService = StatsService();
  final _playlistService = PlaylistService();

  UserModel? _displayUser;
  Map<String, dynamic>? _stats;
  bool _isFollowing = false;
  bool _isLoading = true;
  List<dynamic> _playlists = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final currentUser = ref.read(authProvider).user;
    final targetId = widget.targetUserId ?? currentUser?.id;

    if (targetId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Load Profile
      final user = await _connectionService.getUserProfile(targetId);
      
      // 2. Load Stats
      final stats = await _statsService.getUserStats(targetId);

      // 3. Load Playlists
      final playlists = await _playlistService.getUserPlaylists(targetId);

      // 4. Check Follow status if viewing others
      bool isFollowing = false;
      if (widget.targetUserId != null && currentUser != null) {
        isFollowing = await _connectionService.isFollowing(currentUser.id, targetId);
      }

      if (mounted) {
        setState(() {
          _displayUser = user;
          _stats = stats;
          _isFollowing = isFollowing;
          _playlists = playlists;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null || _displayUser == null) return;

    try {
      if (_isFollowing) {
        await _connectionService.unfollowUser(currentUser.id, _displayUser!.id);
      } else {
        await _connectionService.followUser(currentUser.id, _displayUser!.id);
      }
      setState(() => _isFollowing = !_isFollowing);
      // Reload profile to get new counts
      final updatedUser = await _connectionService.getUserProfile(_displayUser!.id);
      if (mounted) setState(() => _displayUser = updatedUser);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isOwnProfile = widget.targetUserId == null || widget.targetUserId == auth.user?.id;

    if (auth.user == null || (auth.user!.isGuest && isOwnProfile)) {
      return _GuestProfileView();
    }

    if (_isLoading) {
      return const Scaffold(backgroundColor: Color(0xFF030303), body: Center(child: CircularProgressIndicator(color: AColors.primary)));
    }

    if (_displayUser == null) {
      return Scaffold(backgroundColor: const Color(0xFF030303), appBar: AppBar(backgroundColor: Colors.transparent), body: const Center(child: Text('User not found', style: TextStyle(color: Colors.white))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF030303),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, isOwnProfile),
          SliverToBoxAdapter(child: _buildHeader(context, isOwnProfile)),
          SliverToBoxAdapter(child: _buildStatsSection()),
          if (_playlists.isNotEmpty) ...[
            _sectionTitle('Playlists'),
            _buildPlaylistsGrid(),
          ],
          if (isOwnProfile) SliverToBoxAdapter(child: _buildOwnProfileActions(context, ref)),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isOwn) => SliverAppBar(
    backgroundColor: Colors.transparent,
    expandedHeight: 0,
    floating: true,
    leading: widget.targetUserId != null 
      ? IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20))
      : null,
    actions: [
      if (isOwn)
        IconButton(onPressed: () => _showSettings(context, ref), icon: const Icon(Icons.settings_suggest_rounded, color: Colors.white38)),
    ],
  );

  Widget _buildHeader(BuildContext context, bool isOwn) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
    child: Column(
      children: [
        Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_displayUser!.username, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -1)),
                  const SizedBox(height: 8),
                  Text(_displayUser!.role.toUpperCase(), style: GoogleFonts.outfit(color: AColors.primaryLight, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildCounterRow(),
        const SizedBox(height: 32),
        if (!isOwn) 
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? Colors.white.withOpacity(0.1) : Colors.white,
                foregroundColor: _isFollowing ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_isFollowing ? 'Following' : 'Follow', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          )
        else
          Row(
            children: [
              Expanded(child: _CompactButton(label: 'Edit Profile', onTap: () => _showEditProfile(context, ref, _displayUser))),
              const SizedBox(width: 16),
              _IconAction(icon: Icons.logout_rounded, onTap: () => _confirmSignOut(context, ref), color: AColors.error.withOpacity(0.15), iconColor: AColors.error),
            ],
          ),
      ],
    ),
  ).animate().fadeIn().slideY(begin: 0.1, end: 0);

  Widget _buildAvatar() => Hero(
    tag: 'avatar_${_displayUser!.id}',
    child: Container(
      width: 90, height: 90,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white10, width: 2)),
      child: CircleAvatar(
        radius: 45,
        backgroundColor: Colors.white10,
        backgroundImage: (_displayUser!.avatarUrl != null && _displayUser!.avatarUrl!.isNotEmpty) 
          ? CachedNetworkImageProvider(_displayUser!.avatarUrl!) : null,
        child: (_displayUser!.avatarUrl == null || _displayUser!.avatarUrl!.isEmpty) 
          ? const Icon(Icons.person_rounded, size: 45, color: Colors.white10) : null,
      ),
    ),
  );

  Widget _buildCounterRow() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      _counterItem('Followers', _displayUser!.followerCount, onTap: () => _showConnectionList('Followers')),
      _counterItem('Following', _displayUser!.followingCount, onTap: () => _showConnectionList('Following')),
      _counterItem('Playlists', _playlists.length),
    ],
  );

  Widget _counterItem(String label, int count, {VoidCallback? onTap}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Text(count.toString(), style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );

  Widget _buildStatsSection() {
    if (_stats == null) return const SizedBox();
    
    final totalSeconds = _stats!['total_seconds'] as int? ?? 0;
    final hours = (totalSeconds / 3600).toStringAsFixed(1);
    final topSongs = _stats!['top_songs'] as List? ?? [];
    final topArtists = _stats!['top_artists'] as List? ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MUSIC STATS', style: GoogleFonts.outfit(fontSize: 10, color: AColors.primaryLight, fontWeight: FontWeight.w900, letterSpacing: 3)),
          const SizedBox(height: 24),
          Row(
            children: [
              _statCard('Total Music', _stats!['total_songs'].toString(), Icons.music_note_rounded),
              const SizedBox(width: 16),
              _statCard('Listening Hours', hours, Icons.timer_rounded),
            ],
          ),
          const SizedBox(height: 32),
          if (topSongs.isNotEmpty) ...[
            Text('TOP 5 SONGS', style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...topSongs.map((s) => _topSongItem(s)).toList(),
          ],
          const SizedBox(height: 32),
          if (topArtists.isNotEmpty) ...[
             Text('FREQUENT ARTISTS', style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.bold)),
             const SizedBox(height: 16),
             Wrap(
               spacing: 12, runSpacing: 12,
               children: topArtists.map((a) => _artistTag(a['artist'])).toList(),
             ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _statCard(String label, String value, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AColors.primary, size: 24),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );

  Widget _topSongItem(Map<String, dynamic> song) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: song['cover_url'] ?? '', width: 44, height: 44, fit: BoxFit.cover)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(song['title'], style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(song['artist'], style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
        Text('${song['play_count']} PLAYS', style: GoogleFonts.outfit(color: AColors.primaryLight, fontSize: 10, fontWeight: FontWeight.w900)),
      ],
    ),
  );

  Widget _artistTag(String name) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(100)),
    child: Text(name, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
  );

  Widget _sectionTitle(String t) => SliverToBoxAdapter(
    child: Padding(padding: const EdgeInsets.fromLTRB(28, 0, 28, 20), child: Text(t, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white))),
  );

  Widget _buildPlaylistsGrid() => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    sliver: SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.8),
      delegate: SliverChildBuilderDelegate((ctx, i) {
        final p = _playlists[i];
        return Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), child: (p['cover_url'] != null) ? CachedNetworkImage(imageUrl: p['cover_url'], fit: BoxFit.cover, width: double.infinity) : Container(color: Colors.white10, child: const Icon(Icons.playlist_play_rounded, size: 40, color: Colors.white24)))),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(p['name'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );
      }, childCount: _playlists.length),
    ),
  );

  Widget _buildOwnProfileActions(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
    child: Column(
      children: [
        const Divider(color: Colors.white10),
        const SizedBox(height: 40),
        Text('Share Your Vibe', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 16),
        Text('Allow others to see your playlists and discovery activity.', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white24, height: 1.6)),
        const SizedBox(height: 48),
        SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: () => _showSettings(context, ref), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: Text('Manage App Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)))),
      ],
    ),
  );

  // Existing methods (Edit, SignOut, etc.) preserved and adapted
  void _showConnectionList(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConnectionListSheet(
        userId: _displayUser!.id,
        type: type,
        onUpdate: () async {
          // Update profile count after unfollow
          final updatedUser = await _connectionService.getUserProfile(_displayUser!.id);
          if (mounted) setState(() => _displayUser = updatedUser);
        },
      ),
    );
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(context: context, isScrollControlled: true, useRootNavigator: true, backgroundColor: Colors.transparent, builder: (_) => const _SettingsSheet());
  }

  void _showEditProfile(BuildContext context, WidgetRef ref, UserModel? user) {
    showModalBottomSheet(context: context, isScrollControlled: true, useRootNavigator: true, backgroundColor: Colors.transparent, builder: (_) => _EditProfileSheet(user: user));
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: AColors.surface, borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.white10)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout_rounded, color: AColors.error, size: 36),
              const SizedBox(height: 24),
              Text('Sign Out?', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 36),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white60)))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: () async {
                    // Close the dialog first
                    Navigator.of(context, rootNavigator: true).pop();
                    // Perform logout
                    await ref.read(authProvider.notifier).logout();
                    // Navigate to LoginScreen, removing all routes
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  }, style: ElevatedButton.styleFrom(backgroundColor: AColors.error), child: Text('Sign Out', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Supporting Widgets (Edit Sheet, Settings Sheet, Guest View) ──
// These were copied from original or slightly adjusted for consistency

class _EditProfileSheet extends ConsumerStatefulWidget {
  final dynamic user;
  const _EditProfileSheet({required this.user});
  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late TextEditingController _nameCtrl;
  String? _avatarUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?.username);
    _avatarUrl = widget.user?.avatarUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(28, 28, 28, MediaQuery.of(context).viewInsets.bottom + 42),
      decoration: const BoxDecoration(color: AColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ATextField(label: 'Username', controller: _nameCtrl, hint: 'New username'),
          const SizedBox(height: 24),
          InkWell(
            onTap: _isUploading ? null : _pickImage,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [const Icon(Icons.photo_camera, color: AColors.primary), const SizedBox(width: 16), Text(_isUploading ? 'Uploading...' : 'Change Photo', style: TextStyle(color: Colors.white70))]),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: () async {
            await ref.read(authProvider.notifier).updateProfile(username: _nameCtrl.text.trim(), avatarUrl: _avatarUrl);
            if (mounted) Navigator.pop(context);
          }, child: const Text('Save Changes'))),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (file == null) return;
    setState(() => _isUploading = true);
    try {
      final cloudinary = CloudinaryPublic('dkkyvggnz', 'alfal_app');
      final res = await cloudinary.uploadFile(CloudinaryFile.fromFile(file.path, folder: 'avatars'));
      setState(() { _avatarUrl = res.secureUrl; _isUploading = false; });
    } catch (_) { setState(() => _isUploading = false); }
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(color: AColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Settings', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 24),
          ListTile(leading: const Icon(Icons.info_outline, color: Colors.white), title: const Text('Version', style: TextStyle(color: Colors.white)), subtitle: const Text('1.0.0+Stats', style: TextStyle(color: Colors.white38))),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _CompactButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CompactButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white.withOpacity(0.07), border: Border.all(color: Colors.white.withOpacity(0.1))),
        child: Text(label, textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? iconColor;
  const _IconAction({required this.icon, required this.onTap, this.color, this.iconColor});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(shape: BoxShape.circle, color: color ?? Colors.white.withOpacity(0.07)), child: Icon(icon, color: iconColor ?? Colors.white, size: 23)));
  }
}

class _ConnectionListSheet extends ConsumerStatefulWidget {
  final String userId;
  final String type; // 'Followers' or 'Following'
  final VoidCallback onUpdate;
  const _ConnectionListSheet({required this.userId, required this.type, required this.onUpdate});

  @override
  ConsumerState<_ConnectionListSheet> createState() => _ConnectionListSheetState();
}

class _ConnectionListSheetState extends ConsumerState<_ConnectionListSheet> {
  final _service = ConnectionService();
  bool _isLoading = true;
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final res = widget.type == 'Followers' 
          ? await _service.getFollowers(widget.userId) 
          : await _service.getFollowing(widget.userId);
      if (mounted) setState(() { _users = res; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(color: AColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.type.toUpperCase(), style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AColors.primary)))
          else if (_users.isEmpty)
             Expanded(child: Center(child: Text('No users found', style: GoogleFonts.outfit(color: Colors.white24))))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (ctx, i) => _buildUserTile(_users[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserTile(UserModel user) {
    final currentUserId = ref.read(authProvider).user?.id;
    final isMe = user.id == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) 
                ? CachedNetworkImageProvider(user.avatarUrl!) : null,
            child: (user.avatarUrl == null || user.avatarUrl!.isEmpty) ? const Icon(Icons.person, color: Colors.white24) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(targetUserId: user.id)));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.username, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(user.role.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                ],
              ),
            ),
          ),
          if (!isMe && currentUserId != null)
            _FollowActionButton(
              targetUserId: user.id,
              onStatusChange: widget.onUpdate,
            ),
        ],
      ),
    );
  }
}

class _FollowActionButton extends ConsumerStatefulWidget {
  final String targetUserId;
  final VoidCallback onStatusChange;
  const _FollowActionButton({required this.targetUserId, required this.onStatusChange});

  @override
  ConsumerState<_FollowActionButton> createState() => _FollowActionButtonState();
}

class _FollowActionButtonState extends ConsumerState<_FollowActionButton> {
  final _service = ConnectionService();
  bool _isFollowing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final me = ref.read(authProvider).user?.id;
    if (me == null) return;
    final res = await _service.isFollowing(me, widget.targetUserId);
    if (mounted) setState(() { _isFollowing = res; _isLoading = false; });
  }

  Future<void> _toggleAction() async {
    final me = ref.read(authProvider).user?.id;
    if (me == null) return;
    setState(() => _isLoading = true);
    try {
      if (_isFollowing) {
        await _service.unfollowUser(me, widget.targetUserId);
      } else {
        await _service.followUser(me, widget.targetUserId);
      }
      if (mounted) {
        setState(() { _isFollowing = !_isFollowing; _isLoading = false; });
        widget.onStatusChange();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24));
    
    return TextButton(
      onPressed: _toggleAction,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        backgroundColor: _isFollowing ? Colors.white.withOpacity(0.06) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        _isFollowing ? 'Unfollow' : 'Follow', 
        style: GoogleFonts.outfit(color: _isFollowing ? Colors.white70 : Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

class _GuestProfileView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Please sign in to view profile', style: TextStyle(color: Colors.white38)));
  }
}
