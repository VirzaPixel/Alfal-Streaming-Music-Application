import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/a_text_field.dart';
import '../../models/user_model.dart';
import '../../services/connection_service.dart';
import '../../services/playlist_service.dart';
import '../../widgets/top_notification.dart';
import '../auth/login_screen.dart';
import '../playlist/playlist_detail_screen.dart';

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
    final currentUser = ref.read(authProvider).user;
    final targetId = widget.targetUserId ?? currentUser?.id;

    if (targetId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
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
    
    setState(() {
      _isFollowing = !isFollowingBefore;
      if (_displayUser != null) {
        _displayUser = _displayUser!.copyWith(
          followerCount: _displayUser!.followerCount + (isFollowingBefore ? -1 : 1),
        );
      }
    });

    ref.read(authProvider.notifier).updateFollowCounts(
      followingDelta: isFollowingBefore ? -1 : 1,
    );

    try {
      if (isFollowingBefore) {
        await _connectionService.unfollowUser(currentUser.id, _displayUser!.id);
      } else {
        await _connectionService.followUser(currentUser.id, _displayUser!.id);
      }
      
      final updatedUser = await _connectionService.getUserProfile(_displayUser!.id);
      if (mounted) setState(() => _displayUser = updatedUser);
      ref.read(authProvider.notifier).refreshProfile();
      
    } catch (e) {
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
          const SnackBar(content: Text('Failed to update follow status.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isOwnProfile = widget.targetUserId == null || widget.targetUserId == auth.user?.id;
    final currentUser = isOwnProfile ? auth.user : _displayUser;
    
    // Auto-update playlists if it's the user's own profile
    final displayPlaylists = isOwnProfile 
        ? (ref.watch(playlistsProvider).value ?? [])
        : _playlists;

    if (auth.user == null && isOwnProfile) return _GuestProfileView();

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
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: widget.targetUserId != null 
          ? IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20))
          : null,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeroHeader(context, isOwnProfile, currentUser),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            sliver: SliverToBoxAdapter(child: _buildStatsSection(currentUser, displayPlaylists)),
          ),
          if (isOwnProfile) SliverToBoxAdapter(child: _buildActionButtons(context, ref, currentUser)),
          if (displayPlaylists.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Playlists', 
                onSeeAll: displayPlaylists.length > 4 ? () => _showAllPlaylists(displayPlaylists) : null
              ).animate().fadeIn(delay: 400.ms),
            ),
            _buildPlaylistsGrid(displayPlaylists, limit: 4),
          ],
          
          // ── Request Song Section (New) ──
          if (isOwnProfile)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                child: _RequestSongButton(),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 240)),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, bool isOwn, UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 0),
      child: Column(
        children: [
          _buildAvatarWithGlow(user),
          const SizedBox(height: 24),
          Text(
            user.username, 
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -1)
          ),
          if (user.role.toLowerCase() != 'user') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AColors.primary.withOpacity(0.2)),
              ),
              child: Text(
                user.role.toUpperCase(), 
                style: GoogleFonts.outfit(color: AColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)
              ),
            ),
          ],
          const SizedBox(height: 32),
          if (!isOwn) 
            _FollowButton(isFollowing: _isFollowing, onTap: _toggleFollow),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).moveY(begin: 30, end: 0);
  }

  Widget _buildAvatarWithGlow(UserModel user) {
    return Hero(
      tag: 'avatar_${user.id}',
      child: Container(
        width: 120, height: 120,
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [AColors.primary, AColors.accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Container(
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
          child: ClipOval(
            child: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) 
              ? CachedNetworkImage(imageUrl: user.avatarUrl!, fit: BoxFit.cover) 
              : const Icon(Icons.person_rounded, size: 60, color: Colors.white10),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(UserModel user, List<dynamic> currentPlaylists) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(child: _StatCard(label: 'Followers', count: user.followerCount, onTap: () => _showConnectionList('Followers'))),
          _vDivider(),
          Expanded(child: _StatCard(label: 'Following', count: user.followingCount, onTap: () => _showConnectionList('Following'))),
          _vDivider(),
          Expanded(child: _StatCard(label: 'Playlists', count: currentPlaylists.length)),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _vDivider() => Container(width: 1, height: 30, color: Colors.white.withOpacity(0.05));

  Widget _buildPlaylistsGrid(List<dynamic> currentPlaylists, {int? limit}) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.8),
        delegate: SliverChildBuilderDelegate((ctx, i) {
          final p = currentPlaylists[i];
          return _PremiumPlaylistCard(playlist: p, index: i);
        }, childCount: limit != null ? (currentPlaylists.length > limit ? limit : currentPlaylists.length) : currentPlaylists.length),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, UserModel user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: GestureDetector(
              onTap: () => _showEditProfile(context, ref, user),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.edit_note_rounded, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text('Modify Profile', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _confirmSignOut(context, ref),
            child: Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: AColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AColors.error.withOpacity(0.2)),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.logout_rounded, color: AColors.error, size: 20),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  void _showAllPlaylists(List<dynamic> currentPlaylists) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(color: AColors.surface, borderRadius: BorderRadius.circular(36), border: Border.all(color: Colors.white.withOpacity(0.12))),
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
                  physics: const BouncingScrollPhysics(),
                  itemCount: currentPlaylists.length,
                  itemBuilder: (ctx, i) {
                    final p = currentPlaylists[i];
                    final String coverUrl = (p is Map ? p['cover_url']?.toString() : p.coverUrl) ?? '';
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
                        title: Text((p is Map ? p['name']?.toString() : p.name) ?? 'Playlist', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text('${(p is Map ? (p['playlist_songs'] as List?)?.length : p.songs.length) ?? 0} songs', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white24),
                        onTap: () {
                          Navigator.pop(context);
                          final int playlistId = p is Map ? (p['id'] as int) : p.id;
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (_) => PlaylistDetailScreen(playlistId: playlistId),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      transitionBuilder: (_, animation, __, child) {
        return ScaleTransition(
          scale: animation.drive(Tween(begin: 0.9, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic))),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
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
          final updatedUser = await _connectionService.getUserProfile(_displayUser!.id);
          if (mounted) setState(() => _displayUser = updatedUser);
        },
      ),
    );
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
                    Navigator.of(context, rootNavigator: true).pop();
                    await ref.read(authProvider.notifier).logout();
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

// ═══════════════════════════════════════════
//  SUPPORTING UI COMPONENTS
// ═══════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text('See All', style: GoogleFonts.outfit(color: AColors.primary, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback? onTap;

  const _StatCard({required this.label, required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(count.toString(), style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
            Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _PremiumPlaylistCard extends StatelessWidget {
  final dynamic playlist;
  final int index;
  const _PremiumPlaylistCard({required this.playlist, required this.index});

  @override
  Widget build(BuildContext context) {
    final String coverUrl = (playlist is Map ? playlist['cover_url']?.toString() : playlist.coverUrl) ?? '';
    final int trackCount = (playlist is Map ? (playlist['playlist_songs'] as List?)?.length : playlist.songs.length) ?? 0;
    final String name = (playlist is Map ? playlist['name']?.toString() : playlist.name) ?? 'Playlist';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), 
              child: coverUrl.isNotEmpty 
                ? CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.cover, width: double.infinity) 
                : Container(width: double.infinity, color: Colors.white.withOpacity(0.05), child: const Icon(Icons.music_note_rounded, size: 40, color: Colors.white10)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('$trackCount tracks', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).scale(begin: const Offset(0.95, 0.95));
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onTap;
  const _FollowButton({required this.isFollowing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing ? Colors.white.withOpacity(0.1) : Colors.white,
          foregroundColor: isFollowing ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: Text(isFollowing ? 'Following' : 'Follow', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)),
      ),
    );
  }
}

// ── Shared Support Classes ──

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
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AColors.primary.withOpacity(0.3), width: 2)),
                  child: ClipOval(
                    child: _localImage != null 
                        ? (kIsWeb ? Image.network(_localImage!.path, fit: BoxFit.cover) : Image.file(_localImage!, fit: BoxFit.cover))
                        : (_avatarUrl != null && _avatarUrl!.isNotEmpty 
                            ? CachedNetworkImage(imageUrl: _avatarUrl!, fit: BoxFit.cover) 
                            : const Icon(Icons.person_rounded, size: 50, color: Colors.white24)),
                  ),
                ),
                if (!_isSaving)
                  Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AColors.primary, shape: BoxShape.circle), child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16))),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ATextField(label: 'Username', controller: _nameCtrl, hint: 'How should we call you?'),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _isSaving ? null : _handleSave, child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Text('Confirm Changes'))),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (file == null) return;
    setState(() => _localImage = File(file.path));
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      String? finalAvatarUrl = _avatarUrl;
      if (_localImage != null) {
        final cloudinary = CloudinaryPublic(dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'dkkyvggnz', dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'alfal_app');
        final res = await cloudinary.uploadFile(CloudinaryFile.fromFile(_localImage!.path, resourceType: CloudinaryResourceType.Auto, folder: 'alfal_avatar'));
        finalAvatarUrl = res.secureUrl;
      }
      await ref.read(authProvider.notifier).updateProfile(username: _nameCtrl.text.trim(), avatarUrl: finalAvatarUrl);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _ConnectionListSheet extends ConsumerStatefulWidget {
  final String userId;
  final String type;
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
    try {
      final res = widget.type == 'Followers' ? await _service.getFollowers(widget.userId) : await _service.getFollowing(widget.userId);
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
          if (_isLoading) const Expanded(child: Center(child: CircularProgressIndicator(color: AColors.primary)))
          else if (_users.isEmpty) Expanded(child: Center(child: Text('No users found', style: GoogleFonts.outfit(color: Colors.white24))))
          else Expanded(child: ListView.builder(itemCount: _users.length, itemBuilder: (ctx, i) => _buildUserTile(_users[i]))),
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
          CircleAvatar(radius: 24, backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) ? CachedNetworkImageProvider(user.avatarUrl!) : null, child: (user.avatarUrl == null || user.avatarUrl!.isEmpty) ? const Icon(Icons.person, color: Colors.white24) : null),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(targetUserId: user.id)));
              },
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.username, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(user.role.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
              ]),
            ),
          ),
          if (!isMe && currentUserId != null) _FollowActionButton(targetUserId: user.id, onStatusChange: widget.onUpdate),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24));
    return TextButton(
      onPressed: () async {
        final me = ref.read(authProvider).user?.id;
        if (me == null) return;
        if (_isFollowing) await _service.unfollowUser(me, widget.targetUserId);
        else await _service.followUser(me, widget.targetUserId);
        widget.onStatusChange();
        _checkStatus();
      },
      style: TextButton.styleFrom(backgroundColor: _isFollowing ? Colors.white.withOpacity(0.06) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: Text(_isFollowing ? 'Unfollow' : 'Follow', style: GoogleFonts.outfit(color: _isFollowing ? Colors.white70 : Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _RequestSongButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () {
          HapticFeedback.heavyImpact();
          TopNotification.show(context, 'Song request is an upcoming feature! Stay tuned.', color: AColors.primary);
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_time_extension_rounded, color: AColors.primaryLight, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request a Song to atmin virza',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'What do u want i would add it broo',
                      style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.add_circle_outline_rounded, color: Colors.white24, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestProfileView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: Color(0xFF030303), body: Center(child: Text('Please sign in to view profile', style: TextStyle(color: Colors.white38))));
  }
}
