import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/a_text_field.dart';
import 'liked_songs_screen.dart';
import 'playlist_detail_screen.dart';
import '../../widgets/top_navbar.dart';

class PlaylistScreen extends ConsumerWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TopNavbar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(playlistsProvider);
                  await ref.read(playlistsProvider.future);
                },
                color: AColors.primary,
                backgroundColor: AColors.surface,
                child: _buildAuthenticatedLibrary(context, ref, playlistsAsync),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticatedLibrary(BuildContext context, WidgetRef ref, AsyncValue<List<dynamic>> playlistsAsync) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // ── Immersive Header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Your ',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                        color: Colors.white70,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                    Text(
                      'Library',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.0,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Featured Tiles ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _FeaturedLibraryTile(
              title: 'Liked Songs',
              subtitle: 'Your Ephemeral Songs',
              icon: Icons.favorite_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFC026D3)],
              ),
              onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const LikedSongsScreen()),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
        ),

        // ── Grid Header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'PLAYLISTS',
                  style: GoogleFonts.outfit(
                    fontSize: 13, 
                    fontWeight: FontWeight.w900, 
                    color: Colors.white54,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Icon(Icons.sort_rounded, color: Colors.white24, size: 20),
              ],
            ),
          ).animate().fadeIn(delay: 350.ms),
        ),

        playlistsAsync.when(
          loading: () => const SliverToBoxAdapter(child: Center(child: Padding(
            padding: EdgeInsets.only(top: 80),
            child: CircularProgressIndicator(color: AColors.primary),
          ))),
          error: (e, __) => SliverToBoxAdapter(child: Center(child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              children: [
                const Icon(Icons.cloud_off_rounded, color: Colors.white12, size: 48),
                const SizedBox(height: 16),
                Text('Failed to load. Pull to refresh.', 
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.white24, fontSize: 14)),
              ],
            ),
          ))),
          data: (playlists) {
            if (playlists.isEmpty) return SliverToBoxAdapter(child: _EmptyLibraryState());
            
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 240),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    if (i == 0) {
                      return _CreatePlaylistCard(
                        onTap: () => _showCreateDialog(context, ref),
                      );
                    }
                    final playlist = playlists[i - 1];
                    return _PlaylistGridItem(
                      playlist: playlist,
                      onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (_) => PlaylistDetailScreen(playlistId: playlist.id)),
                      ),
                      onDelete: () => _confirmDelete(context, ref, playlist),
                    );
                  },
                  childCount: playlists.length + 1,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const _CreatePlaylistDialog(),
      transitionBuilder: (_, animation, __, child) {
        return ScaleTransition(
          scale: animation.drive(Tween(begin: 0.9, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic))),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic playlist) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (_) => _DeleteConfirmDialog(
        playlistId: playlist.id,
        playlistName: playlist.name,
      ),
    );
  }
}

// ── Components ──────────────────────────────────────────────

class _FeaturedLibraryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _FeaturedLibraryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 115,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient).colors.first.withOpacity(0.15),
              blurRadius: 30,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32), // Fixed missing border radius!
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (gradient as LinearGradient).colors.first.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: GoogleFonts.outfit(color: const Color(0xFF00E5FF).withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaylistGridItem extends StatelessWidget {
  final dynamic playlist;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PlaylistGridItem({
    required this.playlist, 
    required this.onTap, 
    required this.onDelete
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(24), // Tighter radius
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24), // Tighter radius
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Hero(
                    tag: 'playlist_cover_${playlist.id}',
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        (playlist.coverUrl != null && playlist.coverUrl!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: playlist.coverUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.transparent, // Fully transparent placeholder so glass shines through
                                child: const Icon(Icons.music_note_rounded, color: Colors.white10, size: 48),
                              ),
                        // Inner elegant gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black.withOpacity(0.4)], // Softer shadow
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.transparent, // Transparent so the glass effect isn't muddy
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        playlist.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.music_note_rounded, color: Color(0xFF00E5FF), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${playlist.songs.length} tracks',
                            style: GoogleFonts.outfit(color: const Color(0xFF00E5FF).withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

class _CreatePlaylistCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CreatePlaylistCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF00E5FF).withOpacity(0.03),
          borderRadius: BorderRadius.circular(24), // Match the playlist cards
          border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.3), blurRadius: 15),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Color(0xFF00E5FF), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Create Playlist',
              style: GoogleFonts.outfit(
                color: const Color(0xFF00E5FF),
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }
}


// ── Separated Dialogs (Logic remains same, styling improved) ────────────────────

class _CreatePlaylistDialog extends ConsumerStatefulWidget {
  const _CreatePlaylistDialog();
  @override
  ConsumerState<_CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends ConsumerState<_CreatePlaylistDialog> {
  final _ctrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AColors.surface,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40, spreadRadius: 10)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Playlist',
                style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 24),
            ATextField(
              controller: _ctrl,
              hint: 'My awesome mix...',
              autofocus: true,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _create,
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text('Create Now', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    if (_ctrl.text.trim().isEmpty) return;
    
    final playlistName = _ctrl.text.trim();
    
    // Close the dialog FIRST so the exit animation is butter smooth
    Navigator.pop(context);
    
    // Wait for the dialog animation to finish before doing heavy state updates
    await Future.delayed(const Duration(milliseconds: 300));
    
    try {
      // Optimistic update for the global auth state (our playlist count)
      ref.read(authProvider.notifier).updateFollowCounts(playlistDelta: 1);

      await ref.read(playlistServiceProvider).createPlaylist(playlistName);
      ref.invalidate(playlistsProvider);
      
      // Sync background
      ref.read(authProvider.notifier).refreshProfile();
    } catch (e) {
      // Revert optimistic update on error
      ref.read(authProvider.notifier).updateFollowCounts(playlistDelta: -1);
      // Optional: show error toast here if we have a global scaffold messenger key
    }
  }
}

class _DeleteConfirmDialog extends ConsumerStatefulWidget {
  final int playlistId;
  final String playlistName;
  const _DeleteConfirmDialog({required this.playlistId, required this.playlistName});
  @override
  ConsumerState<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends ConsumerState<_DeleteConfirmDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AColors.surface,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AColors.error.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline_rounded, color: AColors.error, size: 36),
            ),
            const SizedBox(height: 24),
            Text('Delete Playlist?', 
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 10),
            Text('"${widget.playlistName}" will be gone forever.', 
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white30, fontSize: 15, height: 1.4)),
            const SizedBox(height: 36),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white30, fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _delete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AColors.error,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete() async {
    setState(() => _isLoading = true);
    try {
      // Optimistic update
      ref.read(authProvider.notifier).updateFollowCounts(playlistDelta: -1);

      await ref.read(playlistServiceProvider).deletePlaylist(widget.playlistId);
      ref.invalidate(playlistsProvider);
      
      if (mounted) {
        Navigator.pop(context);
      }
      
      // Sync background
      ref.read(authProvider.notifier).refreshProfile();
    } catch (e) {
      // Revert
      ref.read(authProvider.notifier).updateFollowCounts(playlistDelta: 1);
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete playlist.')),
        );
      }
    }
  }
}

class _EmptyLibraryState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_mosaic_rounded,
                size: 64, color: Colors.white.withOpacity(0.06)),
          ),
          const SizedBox(height: 32),
          Text('Your collection is empty', 
            style: GoogleFonts.outfit(color: Colors.white24, fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 10),
          Text('Try creating something new!', 
            style: GoogleFonts.outfit(color: Colors.white12, fontSize: 14)),
        ],
      ),
    );
  }
}
