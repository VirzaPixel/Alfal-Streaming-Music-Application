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

class PlaylistScreen extends ConsumerWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final playlistsAsync = ref.watch(playlistsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TopNavbar(),
            Expanded(
              child: user == null || user.isGuest 
                  ? _GuestLibraryView() 
                  : RefreshIndicator(
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
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        // ── Header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 24, 24),
            child: Row(
              children: [
                Text(
                  'Music Library',
                  style: GoogleFonts.outfit(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.2,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0),
                const Spacer(),
                _LibraryActionButton(
                  icon: Icons.add_rounded,
                  label: 'Playlist',
                  onTap: () => _showCreateDialog(context, ref),
                ).animate().fadeIn(delay: 100.ms),
              ],
            ),
          ),
        ),

        // ── Liked Songs Tile ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _LikedSongsTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LikedSongsScreen())),
            ).animate().fadeIn(delay: 200.ms),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 36)),

        // ── Playlists Section Title ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: Text(
              'Your Playlists',
              style: GoogleFonts.outfit(
                fontSize: 18, 
                fontWeight: FontWeight.w800, 
                color: Colors.white.withValues(alpha: 0.35),
                letterSpacing: -0.5,
              ),
            ),
          ).animate().fadeIn(delay: 250.ms),
        ),

        // ── Playlist List ──
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
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 180),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _PlaylistListItem(
                    playlist: playlists[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlistId: playlists[i].id)),
                    ),
                    onDelete: () => _confirmDelete(context, ref, playlists[i]),
                  ).animate().fadeIn(delay: (300 + i * 50).ms).slideY(begin: 0.05, end: 0),
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
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => const _CreatePlaylistDialog(),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic playlist) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => _DeleteConfirmDialog(
        playlistId: playlist.id,
        playlistName: playlist.name,
      ),
    );
  }
}

// ── Separated Dialogs for State Management ────────────────────

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
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
             BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 40, spreadRadius: 10)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Playlist',
                style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 24),
            ATextField(
              controller: _ctrl,
              hint: 'Write your playlist name...',
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
      await ref.read(playlistServiceProvider).createPlaylist(_ctrl.text.trim());
      ref.invalidate(playlistsProvider);
      // Wait for the re-fetch to complete before closing to ensure UI updates
      await ref.read(playlistsProvider.future);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playlist created! ✨')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AColors.error));
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
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AColors.error.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline_rounded, color: AColors.error, size: 36),
            ),
            const SizedBox(height: 24),
            Text('Delete Playlist?', 
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 10),
            Text('You will permanently delete "${widget.playlistName}" from your collection.', 
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
      await ref.read(playlistServiceProvider).deletePlaylist(widget.playlistId);
      ref.invalidate(playlistsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playlist deleted.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AColors.error));
      }
    }
  }
}

// ── Stateless Widgets ──────────────────────────────────────────

class _LibraryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LibraryActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 21),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: -0.2)),
          ],
        ),
      ),
    );
  }
}

class _LikedSongsTile extends StatelessWidget {
  final VoidCallback onTap;
  const _LikedSongsTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.03)
              ]),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: AColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: AColors.primary.withValues(alpha: 0.35),
                      blurRadius: 25,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Favorite Songs', 
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 3),
                  Text('A collection of songs you have liked', 
                    style: GoogleFonts.outfit(color: Colors.white30, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.12), size: 16),
          ],
        ),
      ),
    );
  }
}

class _PlaylistListItem extends StatelessWidget {
  final dynamic playlist;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PlaylistListItem({
    required this.playlist, 
    required this.onTap, 
    required this.onDelete
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          onLongPress: onDelete,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'playlist_cover_${playlist.id}',
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withValues(alpha: 0.06),
                      image: playlist.coverUrl != null
                          ? DecorationImage(
                              image: NetworkImage(playlist.coverUrl),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: playlist.coverUrl == null
                        ? Icon(Icons.playlist_play_rounded,
                            color: Colors.white.withValues(alpha: 0.2), size: 30)
                        : null,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${playlist.songs?.length ?? 0} tracks',
                        style: GoogleFonts.outfit(
                            color: Colors.white30,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showOptionsMenu(context),
                  icon: Icon(Icons.more_vert_rounded,
                      color: Colors.white.withValues(alpha: 0.1), size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: AColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AColors.error),
              title: Text('Delete Playlist',
                  style: GoogleFonts.outfit(
                      color: AColors.error, fontWeight: FontWeight.w600)),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: AColors.error.withValues(alpha: 0.05),
            ),
          ],
        ),
      ),
    );
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
              color: Colors.white.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_mosaic_rounded,
                size: 64, color: Colors.white.withValues(alpha: 0.06)),
          ),
          const SizedBox(height: 32),
          Text('Your playlist collection is empty', 
            style: GoogleFonts.outfit(color: Colors.white24, fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 10),
          Text('Create a new playlist to save your favorite songs!', 
            style: GoogleFonts.outfit(color: Colors.white12, fontSize: 14)),
        ],
      ),
    );
  }
}

class _GuestLibraryView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04), 
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                  boxShadow: [
                    BoxShadow(color: Colors.black38, blurRadius: 50, offset: const Offset(0, 15))
                  ],
                ),
                child: Icon(Icons.library_music_rounded, size: 78, color: Colors.white.withValues(alpha: 0.1)),
              ),
              const SizedBox(height: 54),
              Text('Your Music Library', 
                style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
              const SizedBox(height: 18),
              Text(
                'Sign in or sign up now to start creating personal playlists and liking your favorite songs.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white30, height: 1.6, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }
}
