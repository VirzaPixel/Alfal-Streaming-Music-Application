import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../models/song_model.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';

class SongTile extends ConsumerWidget {
  final SongModel song;
  final List<SongModel> queue;
  final VoidCallback? onMoreTap;
  final String? sourceName;

  const SongTile({
    super.key,
    required this.song,
    required this.queue,
    this.onMoreTap,
    this.sourceName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final isActive = player.currentSong?.id == song.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            ref
                .read(playerProvider.notifier)
                .playSong(song, queue: queue, sourceName: sourceName);
          },
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: 400.ms,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isActive
                  ? AColors.primary.withValues(alpha: 0.08)
                  : AColors.glassSurface,
              border: Border.all(
                color: isActive
                    ? AColors.primary.withValues(alpha: 0.4)
                    : AColors.glassBorder,
                width: 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                          color: AColors.primary.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8))
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // Album art with Hero
                Hero(
                  tag: 'song_art_${song.id}',
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: song.coverUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const _Placeholder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: GoogleFonts.outfit(
                          color: isActive ? Colors.white : AColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artist,
                        style: GoogleFonts.outfit(
                          color: isActive
                              ? AColors.primaryLight.withValues(alpha: 0.8)
                              : AColors.textSec,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Active Indicator or Duration
                if (isActive)
                  _AnimatedEqualizer(isPlaying: player.isPlaying)
                else
                  Text(
                    song.durationLabel,
                    style: GoogleFonts.outfit(
                      color: AColors.textHint,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                // Like & Options
                if (ref.watch(authProvider).user?.isGuest == false) ...[
                  Consumer(builder: (context, ref, _) {
                    final liked = ref.watch(isLikedProvider(song.id));
                    return IconButton(
                      icon: Icon(
                        liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: liked ? Colors.redAccent : AColors.textHint,
                      ),
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        if (liked) {
                          await ref
                              .read(playlistServiceProvider)
                              .unlikeSong(song.id);
                        } else {
                          await ref
                              .read(playlistServiceProvider)
                              .likeSong(song.id);
                        }
                        ref.invalidate(likedSongsProvider);
                        ref.invalidate(profileStatsProvider);
                      },
                      iconSize: 20,
                    );
                  }),
                ],

                if (onMoreTap != null) ...[
                  IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onMoreTap!();
                    },
                    icon: const Icon(Icons.more_vert_rounded),
                    color: AColors.textHint,
                    iconSize: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AColors.surfaceAlt,
      child: const Center(
        child:
            Icon(Icons.music_note_rounded, color: AColors.textHint, size: 20),
      ),
    );
  }
}

class _AnimatedEqualizer extends StatelessWidget {
  final bool isPlaying;
  const _AnimatedEqualizer({required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 24,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          return Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              gradient: AColors.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          )
              .animate(
                  onPlay: (c) => isPlaying ? c.repeat(reverse: true) : c.stop())
              .scaleY(
                  begin: 0.2,
                  end: 1.0,
                  duration: (400 + (i * 200)).ms,
                  curve: Curves.easeInOut);
        }),
      ),
    );
  }
}
