import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/cloudinary_service.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/a_text_field.dart';
import '../../widgets/glass_container.dart';
import '../../models/user_model.dart';
import '../../services/connection_service.dart';
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
  final _playlistService = PlaylistService();

  UserModel? _displayUser;
  bool _isFollowing = false;
  bool _isLoading = true;
  List<dynamic> _playlists = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Ensure we have a target ID. If not targeting someone, use current user.
    final currentUser = ref.read(authProvider).user;
    final targetId = widget.targetUserId ?? currentUser?.id;

    if (targetId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Parallel loading for better performance
      final results = await Future.wait([
        _connectionService.getUserProfile(targetId),
        _playlistService.getUserPlaylists(targetId),
        if (widget.targetUserId != null && currentUser != null)
          _connectionService.isFollowing(currentUser.id, targetId)
        else
          Future.value(false),
      ]);

      if (mounted) {
        setState(() {
          _displayUser = results[0] as UserModel?;
          _playlists = results[1] as List<dynamic>;
          _isFollowing = results[2] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _displayUser = null; 
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null || _displayUser == null) return;

    final isFollowingBefore = _isFollowing;
    
    // 1. Optimistic UI update for the local state (button and counts)
    setState(() {
      _isFollowing = !isFollowingBefore;
      if (_displayUser != null) {
        _displayUser = _displayUser!.copyWith(
          followerCount: _displayUser!.followerCount + (isFollowingBefore ? -1 : 1),
        );
      }
    });

    // 2. Optimistic update for the global auth state (our following count)
    ref.read(authProvider.notifier).updateFollowCounts(
      followingDelta: isFollowingBefore ? -1 : 1,
    );

    try {
      if (isFollowingBefore) {
        await _connectionService.unfollowUser(currentUser.id, _displayUser!.id);
      } else {
        await _connectionService.followUser(currentUser.id, _displayUser!.id);
      }
      
      // Background reload to ensure sync with server
      final updatedUser = await _connectionService.getUserProfile(_displayUser!.id);
      if (mounted) setState(() => _displayUser = updatedUser);
      
      // Also refresh our own profile in background to be sure global state is accurate
      ref.read(authProvider.notifier).refreshProfile();
      
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isFollowing = isFollowingBefore;
          if (_displayUser != null) {
            _displayUser = _displayUser!.copyWith(
              followerCount: _displayUser!.followerCount + (isFollowingBefore ? 1 : -1),
            );
          }
        });
        
        ref.read(authProvider.notifier).updateFollowCounts(
          followingDelta: isFollowingBefore ? 1 : -1,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update follow status. Check your connection.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isOwnProfile = widget.targetUserId == null || widget.targetUserId == auth.user?.id;

    // Direct reactive sync: If it's our own profile, always use the user from authProvider
    final currentUser = isOwnProfile ? auth.user : _displayUser;

    if (auth.user == null && isOwnProfile) {
      return _GuestProfileView();
    }

    if (_isLoading && currentUser == null) {
      return const Scaffold(backgroundColor: Color(0xFF030303), body: Center(child: CircularProgressIndicator(color: AColors.primary)));
    }

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF030303), 
        appBar: AppBar(backgroundColor: Colors.transparent), 
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_rounded, color: Colors.white24, size: 64),
              const SizedBox(height: 16),
              const Text('User not found', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: _loadData, 
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, isOwnProfile),
          SliverToBoxAdapter(child: _buildHeader(context, isOwnProfile, currentUser!)),
          if (_playlists.isNotEmpty) ...[
            _sectionTitle('Playlists', showSeeAll: _playlists.length > 4),
            _buildPlaylistsGrid(limit: 4),
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
    actions: const [],
  );

  Widget _buildHeader(BuildContext context, bool isOwn, UserModel user) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
    child: Column(
      children: [
        Row(
          children: [
            _buildAvatar(user),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.username, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -1)),
                  const SizedBox(height: 8),
                  Text(user.role.toUpperCase(), style: GoogleFonts.outfit(color: AColors.primaryLight, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildCounterRow(user),
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
              Expanded(child: _CompactButton(label: 'Edit Profile', onTap: () => _showEditProfile(context, ref, user))),
              const SizedBox(width: 16),
              _IconAction(icon: Icons.logout_rounded, onTap: () => _confirmSignOut(context, ref), color: AColors.error.withOpacity(0.15), iconColor: AColors.error),
            ],
          ),
      ],
    ),
  ).animate().fadeIn().slideY(begin: 0.1, end: 0);

  Widget _buildAvatar(UserModel user) => Hero(
    tag: 'avatar_${user.id}',
    child: Container(
      width: 90, height: 90,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white10, width: 2)),
      child: CircleAvatar(
        radius: 45,
        backgroundColor: Colors.white10,
        backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) 
          ? CachedNetworkImageProvider(user.avatarUrl!) : null,
        child: (user.avatarUrl == null || user.avatarUrl!.isEmpty) 
          ? const Icon(Icons.person_rounded, size: 45, color: Colors.white10) : null,
      ),
    ),
  );

  Widget _buildCounterRow(UserModel user) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      _counterItem('Followers', user.followerCount, onTap: () => _showConnectionList('Followers')),
      _counterItem('Following', user.followingCount, onTap: () => _showConnectionList('Following')),
      _counterItem('Playlists', user.playlistCount),
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



  Widget _sectionTitle(String t, {bool showSeeAll = false}) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 16, 20), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(t, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          if (showSeeAll)
            TextButton(
              onPressed: () => _showAllPlaylists(),
              child: Text('See All', style: GoogleFonts.outfit(color: AColors.primary, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    ),
  );

  Widget _buildPlaylistsGrid({int? limit}) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    sliver: SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.8),
      delegate: SliverChildBuilderDelegate((ctx, i) {
        final p = _playlists[i];
        final coverUrl = p['cover_url']?.toString() ?? '';
        final hasCover = coverUrl.isNotEmpty;
        return AGlass(
          opacity: 0.03,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), 
                  child: hasCover 
                    ? CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.cover, width: double.infinity) 
                    : Container(width: double.infinity, color: Colors.white.withOpacity(0.05), child: const Icon(Icons.music_note_rounded, size: 48, color: Colors.white24))
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(p['name']?.toString() ?? 'Playlist', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );
      }, childCount: limit != null ? (_playlists.length > limit ? limit : _playlists.length) : _playlists.length),
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
  void _showAllPlaylists() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(color: AColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ALL PLAYLISTS', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white38)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _playlists.length,
                itemBuilder: (ctx, i) {
                  final p = _playlists[i];
                  final coverUrl = p['cover_url']?.toString() ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      tileColor: Colors.white.withOpacity(0.03),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: coverUrl.isNotEmpty
                          ? CachedNetworkImage(imageUrl: coverUrl, width: 50, height: 50, fit: BoxFit.cover)
                          : Container(width: 50, height: 50, color: Colors.white12, child: const Icon(Icons.music_note_rounded)),
                      ),
                      title: Text(p['name']?.toString() ?? 'Playlist', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text('${p['track_count'] ?? 0} songs', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white24),
                      onTap: () {
                         // Navigation to internal playlist detail should go here if needed
                         Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
  File? _localImage;
  bool _isSaving = false;

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
          // Instant Preview Circle
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: AColors.primary.withOpacity(0.2), width: 2)
                  ),
                  child: ClipOval(
                    child: _localImage != null 
                        ? (kIsWeb 
                            ? Image.network(_localImage!.path, fit: BoxFit.cover) 
                            : Image.file(_localImage!, fit: BoxFit.cover))
                        : (_avatarUrl != null && _avatarUrl!.isNotEmpty 
                            ? CachedNetworkImage(imageUrl: _avatarUrl!, fit: BoxFit.cover) 
                            : const Icon(Icons.person_rounded, size: 50, color: Colors.white24)),
                  ),
                ),
                if (_isSaving)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            const SizedBox(height: 8),
                            Text(
                              'Saving...', 
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (!_isSaving)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ATextField(label: 'Username', controller: _nameCtrl, hint: 'New username'),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
            onPressed: _isSaving ? null : _handleSave, 
            child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : const Text('Save Changes')
          )),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (file == null) return;
    
    setState(() {
      _localImage = File(file.path);
    });
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    
    try {
      String? finalAvatarUrl = _avatarUrl;
      String? oldAvatarUrl = widget.user.avatarUrl; // Simpan URL lama
      
      // 1. Upload to Cloudinary ONLY when final SAVE is clicked
      if (_localImage != null) {
        final cloudinary = CloudinaryPublic(
          dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'dkkyvggnz',
          dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'alfal_app',
        );
        final res = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _localImage!.path, 
            resourceType: CloudinaryResourceType.Auto,
            folder: 'alfal_avatar',
          ),
        );
        finalAvatarUrl = res.secureUrl;
      }
      
      // 2. Save everything to Supabase
      await ref.read(authProvider.notifier).updateProfile(
        username: _nameCtrl.text.trim(), 
        avatarUrl: finalAvatarUrl
      );

      // 3. Cleanup: Hapus foto lama jika ganti foto baru
      if (_localImage != null && oldAvatarUrl != null) {
        CloudinaryService.deleteImage(oldAvatarUrl);
      }
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) setState(() => _isSaving = false);
    }
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
    
    final isFollowingBefore = _isFollowing;

    // Optimistic UI Update
    setState(() {
      _isFollowing = !isFollowingBefore;
    });
    
    // Update global following count
    ref.read(authProvider.notifier).updateFollowCounts(
      followingDelta: isFollowingBefore ? -1 : 1,
    );

    try {
      if (isFollowingBefore) {
        await _service.unfollowUser(me, widget.targetUserId);
      } else {
        await _service.followUser(me, widget.targetUserId);
      }
      
      if (mounted) {
        widget.onStatusChange();
      }
      
      // Refresh global profile in background
      ref.read(authProvider.notifier).refreshProfile();
      
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isFollowing = isFollowingBefore;
        });
        
        ref.read(authProvider.notifier).updateFollowCounts(
          followingDelta: isFollowingBefore ? 1 : -1,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update follow status.')),
        );
      }
    } finally {
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
