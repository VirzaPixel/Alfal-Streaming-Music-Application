import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../models/song_model.dart';
import '../providers/auth_provider.dart';
import '../providers/playlist_provider.dart';

class SongOptionsSheet extends ConsumerWidget {
  final SongModel song;
  final int? currentPlaylistId;

  const SongOptionsSheet({
    super.key,
    required this.song,
    this.currentPlaylistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isGuest = user?.isGuest ?? true;

    return Container(
      decoration: BoxDecoration(
        color: AColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, -10),
          )
        ],
      ),
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Song Info Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: song.coverUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AColors.surfaceAlt,
                      child: const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AColors.primary)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AColors.surfaceAlt,
                      child: const Icon(Icons.music_note_rounded,
                          color: AColors.textHint, size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        style: GoogleFonts.outfit(
                            color: AColors.textSec,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Options List
          if (!isGuest) ...[
            Consumer(builder: (context, ref, _) {
              final liked = ref.watch(isLikedProvider(song.id));
              return _OptionItem(
                icon: liked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: liked ? 'Unlike Song' : 'Like Song',
                iconColor: liked ? Colors.redAccent : null,
                onTap: () async {
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                  try {
                    if (liked) {
                      await ref.read(playlistServiceProvider).unlikeSong(song.id);
                    } else {
                      await ref.read(playlistServiceProvider).likeSong(song.id);
                    }
                    ref.invalidate(likedSongsProvider);
                    ref.invalidate(profileStatsProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                      );
                    }
                  }
                },
              );
            }),
            if (currentPlaylistId == null)
              _OptionItem(
                icon: Icons.playlist_add_rounded,
                label: 'Add to Playlist',
                onTap: () {
                  Navigator.pop(context);
                  _showPlaylistPicker(context, ref);
                },
              )
            else
              _OptionItem(
                icon: Icons.playlist_remove_rounded,
                label: 'Remove from this Playlist',
                isError: true,
                onTap: () async {
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                  await ref
                      .read(playlistServiceProvider)
                      .removeSong(currentPlaylistId!, song.id);
                  ref.invalidate(playlistDetailProvider(currentPlaylistId!));
                  ref.invalidate(profileStatsProvider);
                },
              ),
          ],

          _OptionItem(
            icon: Icons.person_outline_rounded,
            label: 'Go to Artist Profile',
            onTap: () => Navigator.pop(context),
          ),

          _OptionItem(
            icon: Icons.share_rounded,
            label: 'Share Song',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showPlaylistPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PlaylistPickerSheet(song: song),
    );
  }
}

class _OptionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isError;
  final Color? iconColor;

  const _OptionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isError = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? (isError ? AColors.error : Colors.white);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color.withValues(alpha: 0.7), size: 22),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                      color: color, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaylistPickerSheet extends ConsumerWidget {
  final SongModel song;
  const _PlaylistPickerSheet({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add to Playlist',
                  style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 24),
          playlistsAsync.when(
            loading: () => const Center(
                child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: AColors.primary),
            )),
            error: (e, _) => Text(e.toString(),
                style: const TextStyle(color: AColors.error)),
            data: (playlists) => playlists.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                        child: Text('No playlists found',
                            style: GoogleFonts.outfit(color: AColors.textSec))),
                  )
                : ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (_, i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () async {
                              Navigator.pop(context);
                              HapticFeedback.mediumImpact();
                              try {
                                await ref
                                    .read(playlistServiceProvider)
                                    .addSong(playlists[i].id, song.id);
                                ref.invalidate(playlistsProvider);
                                ref.invalidate(profileStatsProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Added to ${playlists[i].name}')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              }
                            },
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            tileColor: Colors.white.withValues(alpha: 0.04),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.playlist_play_rounded,
                                  color: AColors.primary, size: 24),
                            ),
                            title: Text(playlists[i].name,
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                playlists[i].description ?? 'Private Playlist',
                                style: GoogleFonts.outfit(
                                    color: AColors.textSec, fontSize: 12)),
                            trailing: const Icon(Icons.add_rounded,
                                color: Colors.white38),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
