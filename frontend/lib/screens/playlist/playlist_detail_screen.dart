import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/theme.dart';
import '../../models/playlist_model.dart';
import '../../models/song_model.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/song_options_sheet.dart';
import '../../widgets/song_tile.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final int playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(playlistDetailProvider(playlistId));
    final player = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: AColors.bg,
      body: Stack(
        children: [
          playlistAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AColors.primary),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(e.toString(),
                      style: GoogleFonts.outfit(color: AColors.textSec)),
                ],
              ),
            ),
            data: (playlist) {
              final songs = playlist.songs;
              final palette = [
                const Color(0xFF6366F1),
                const Color(0xFF8B5CF6)
              ];

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Dynamic Header ──
                  SliverAppBar(
                    expandedHeight: 400,
                    pinned: true,
                    stretch: true,
                    backgroundColor: AColors.bg,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [
                        StretchMode.zoomBackground,
                        StretchMode.blurBackground
                      ],
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Image or Gradient Background
                          if (playlist.coverUrl != null &&
                              playlist.coverUrl!.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: playlist.coverUrl!,
                              fit: BoxFit.cover,
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: palette,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),

                          // Dark overlay for readability
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.2),
                                  AColors.bg.withValues(alpha: 0.95),
                                ],
                              ),
                            ),
                          ),

                          // Content
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 80),
                                // Playlist Artwork Card
                                Hero(
                                  tag: 'playlist_${playlist.id}',
                                  child: Container(
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          blurRadius: 40,
                                          offset: const Offset(0, 20),
                                        )
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(28),
                                      child: playlist.coverUrl != null && playlist.coverUrl!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: playlist.coverUrl!,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: Colors.white.withValues(alpha: 0.1),
                                            child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 64),
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  playlist.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                                if (playlist.description != null && playlist.description!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12, left: 24, right: 24),
                                    child: Text(
                                      playlist.description!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white38,
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ).animate().fadeIn(delay: 300.ms),
                                const SizedBox(height: 12),
                                Text(
                                  '${songs.length} ${songs.length == 1 ? 'TRACK' : 'TRACKS'}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AColors.primary.withValues(alpha: 0.8),
                                    letterSpacing: 2,
                                  ),
                                ).animate().fadeIn(delay: 400.ms),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Action Bar (Glass effect) ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (songs.isNotEmpty) {
                                  HapticFeedback.heavyImpact();
                                  final isThisPlaylistPlaying =
                                      player.sourceName == playlist.name;

                                  if (isThisPlaylistPlaying && player.hasSong) {
                                    ref
                                        .read(playerProvider.notifier)
                                        .togglePlayPause();
                                  } else {
                                    ref.read(playerProvider.notifier).playSong(
                                          songs.first,
                                          queue: songs,
                                          sourceName: playlist.name,
                                        );
                                  }
                                }
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: player.sourceName == playlist.name
                                      ? AColors.primary.withValues(alpha: 0.15)
                                      : AColors.primary,
                                  borderRadius: BorderRadius.circular(16),
                                  border: player.sourceName == playlist.name
                                      ? Border.all(
                                          color:
                                              AColors.primary.withValues(alpha: 0.3))
                                      : null,
                                  boxShadow: player.sourceName == playlist.name
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: AColors.primary
                                                .withValues(alpha: 0.35),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      player.sourceName == playlist.name &&
                                              player.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: player.sourceName == playlist.name
                                          ? AColors.primary
                                          : Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      player.sourceName == playlist.name
                                          ? (player.isPlaying
                                              ? 'PAUSE'
                                              : 'RESUME')
                                          : 'PLAY',
                                      style: GoogleFonts.outfit(
                                        color:
                                            player.sourceName == playlist.name
                                                ? AColors.primary
                                                : Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Original Shuffle Button (slightly smaller or different)
                          GestureDetector(
                            onTap: () {
                              if (songs.isNotEmpty) {
                                HapticFeedback.heavyImpact();
                                final shuffledQueue =
                                    List<SongModel>.from(songs);
                                shuffledQueue.shuffle();
                                ref.read(playerProvider.notifier).playSong(
                                      shuffledQueue.first,
                                      queue: shuffledQueue,
                                      sourceName: playlist.name,
                                    );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: const Icon(Icons.shuffle_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Edit/More Info
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _showEditDialog(context, ref, playlist);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: const Icon(Icons.mode_edit_outline_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Delete Button
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _confirmDelete(context, ref, playlist);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: AColors.error.withValues(alpha: 0.2)),
                              ),
                              child: const Icon(Icons.delete_outline_rounded,
                                  color: AColors.error, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Songs List ──
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 150),
                    sliver: songs.isEmpty
                        ? SliverToBoxAdapter(
                            child: _EmptyPlaylistState(),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => SongTile(
                                song: songs[i],
                                queue: songs,
                                sourceName: playlist.name,
                                onMoreTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    useRootNavigator: true,
                                    backgroundColor: Colors.transparent,
                                    isScrollControlled: true,
                                    builder: (_) => SongOptionsSheet(
                                      song: songs[i],
                                      currentPlaylistId: playlistId,
                                    ),
                                  );
                                },
                              )
                                  .animate()
                                  .fadeIn(delay: (i * 40).ms)
                                  .slideX(begin: 0.1, end: 0),
                              childCount: songs.length,
                            ),
                          ),
                  ),
                ],
              );
            },
          ),

          // Mini Player overlay at the bottom
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, PlaylistModel playlist) {
    final nameCtrl = TextEditingController(text: playlist.name);
    final descCtrl = TextEditingController(text: playlist.description);
    final coverCtrl = TextEditingController(text: playlist.coverUrl ?? '');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Playlist',
                  style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 24),
              _buildField('Name', nameCtrl),
              const SizedBox(height: 16),
              _buildField('Description (Optional)', descCtrl, maxLines: 2),
              const SizedBox(height: 16),
              // Cover Picker
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Playlist Cover',
                      style: GoogleFonts.outfit(
                          color: AColors.textSec,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final file = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 75,
                      );
                      if (file == null) return;
                      try {
                        final cloudinary = CloudinaryPublic('dkkyvggnz', 'alfal_app');
                        final bytes = await file.readAsBytes();
                        
                        final response = await cloudinary.uploadFile(
                          CloudinaryFile.fromBytesData(
                            bytes,
                            identifier: 'covers/${DateTime.now().millisecondsSinceEpoch}',
                            resourceType: CloudinaryResourceType.Image,
                            folder: 'covers',
                          ),
                        );
                        
                        coverCtrl.text = response.secureUrl;
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('New cover uploaded successfully!')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Upload failed: $e')),
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.image_search_rounded,
                              color: AColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Text('Select from Gallery',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                          const Spacer(),
                          const Icon(Icons.chevron_right_rounded,
                              color: Colors.white24, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _DialogBtn(
                      label: 'Cancel',
                      onTap: () => Navigator.pop(ctx),
                      isSecondary: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogBtn(
                      label: 'Save Changes',
                      onTap: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        await ref.read(playlistServiceProvider).updatePlaylist(
                              playlist.id,
                              name: nameCtrl.text.trim(),
                              desc: descCtrl.text.trim(),
                              coverUrl: coverCtrl.text.trim().isEmpty
                                  ? null
                                  : coverCtrl.text.trim(),
                            );
                        ref.invalidate(playlistDetailProvider(playlist.id));
                        ref.invalidate(playlistsProvider);
                        if (context.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, PlaylistModel playlist) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: AColors.error, size: 36),
              ),
              const SizedBox(height: 24),
              Text('Delete Playlist?',
                  style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: AColors.textSec, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _DialogBtn(
                      label: 'Cancel',
                      onTap: () => Navigator.pop(ctx),
                      isSecondary: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogBtn(
                      label: 'Delete',
                      onTap: () async {
                        await ref
                            .read(playlistServiceProvider)
                            .deletePlaylist(playlist.id);
                        ref.invalidate(playlistsProvider);
                        if (context.mounted) {
                          Navigator.pop(ctx); // Close dialog
                          Navigator.pop(context); // Close detail screen
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                color: AColors.textSec,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintStyle: GoogleFonts.outfit(color: Colors.white24),
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSecondary;

  const _DialogBtn(
      {required this.label, required this.onTap, this.isSecondary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSecondary ? Colors.white.withValues(alpha: 0.06) : AColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSecondary
              ? []
              : [
                  BoxShadow(
                      color: AColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6))
                ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _EmptyPlaylistState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Icon(Icons.library_music_rounded,
              size: 56, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            'Playlist is empty',
            style: GoogleFonts.outfit(color: AColors.textSec, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Go find some music to add!',
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

