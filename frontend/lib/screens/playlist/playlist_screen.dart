import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/a_text_field.dart';
import 'liked_songs_screen.dart';
import 'playlist_detail_screen.dart';
import '../../widgets/top_navbar.dart';
import '../../widgets/glass_container.dart';

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
        // ── Modern Header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${ref.watch(authProvider).user?.username ?? 'Your'} Library',
                      style: GoogleFonts.outfit(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.2,
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0),
                    const Spacer(),
                    _CircularPlusButton(
                      onTap: () => _showCreateDialog(context, ref),
                    ).animate().fadeIn(delay: 100.ms).scale(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore your collection and favorites',
                  style: GoogleFonts.outfit(
                    color: Colors.white24,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),
        ),

        // ── Featured Tiles ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _FeaturedLibraryTile(
                    title: 'Liked Songs',
                    subtitle: 'Your absolute favorites',
                    icon: Icons.favorite_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFC026D3)],
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LikedSongsScreen())),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _FeaturedLibraryTile(
                    title: 'New Mixes',
                    subtitle: 'Updated daily for you',
                    icon: Icons.auto_awesome_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    onTap: () {}, // Future feature
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 48)),

        // ── Grid representation for Playlists (Better than plain list) ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ALL PLAYLISTS',
                  style: GoogleFonts.outfit(
                    fontSize: 11, 
                    fontWeight: FontWeight.w900, 
                    color: AColors.primaryLight,
                    letterSpacing: 3,
                  ),
                ),
                Icon(Icons.sort_rounded, color: Colors.white24, size: 18),
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
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 180),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _PlaylistGridItem(
                    playlist: playlists[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlistId: playlists[i].id)),
                    ),
                    onDelete: () => _confirmDelete(context, ref, playlists[i]),
                  ),
                  childCount: playlists.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (_) => const _CreatePlaylistDialog(),
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (gradient as LinearGradient).colors.first.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
            Text(subtitle, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: Colors.white.withOpacity(0.05),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag: 'playlist_cover_${playlist.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: playlist.coverUrl != null
                            ? Image.network(playlist.coverUrl, fit: BoxFit.cover)
                            : Container(
                                color: Colors.white.withOpacity(0.02),
                                child: Icon(Icons.playlist_play_rounded, color: Colors.white10, size: 48),
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12, right: 12,
                    child: AGlass(
                      opacity: 0.2,
                      blur: 10,
                      padding: const EdgeInsets.all(6),
                      borderRadius: BorderRadius.circular(10),
                      child: Icon(Icons.more_horiz_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                ),
                Text(
                  '${playlist.songs?.length ?? 0} tracks',
                  style: GoogleFonts.outfit(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularPlusButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircularPlusButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
      ),
    );
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
    setState(() => _isLoading = true);
    try {
      // Optimistic update for the global auth state (our playlist count)
      ref.read(authProvider.notifier).updateFollowCounts(playlistDelta: 1);

      await ref.read(playlistServiceProvider).createPlaylist(_ctrl.text.trim());
      ref.invalidate(playlistsProvider);
      
      if (mounted) {
        Navigator.pop(context);
      }
      
      // Sync background
      ref.read(authProvider.notifier).refreshProfile();
    } catch (e) {
      // Revert optimistic update on error
      ref.read(authProvider.notifier).updateFollowCounts(playlistDelta: -1);
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create playlist.')),
        );
      }
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
