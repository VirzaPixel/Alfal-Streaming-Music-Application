import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../models/song_model.dart';
import '../providers/player_provider.dart';
import 'song_options_sheet.dart';

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
    // Optimization: Only rebuild if THIS song's active state changes
    final isActive = ref.watch(playerProvider.select((p) => p.currentSong?.id == song.id));
    final isPlaying = ref.watch(playerProvider.select((p) => p.isPlaying));
    
    return RepaintBoundary(
      child: Container(
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
                    ? AColors.primary.withOpacity(0.08)
                    : AColors.glassSurface,
                border: Border.all(
                  color: isActive
                      ? AColors.primary.withOpacity(0.4)
                      : AColors.glassBorder,
                  width: 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                            color: AColors.primary.withOpacity(0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8))
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
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
                        memCacheWidth: 150,
                        memCacheHeight: 150,
                        placeholder: (context, url) => Container(color: AColors.surfaceAlt),
                        errorWidget: (_, __, ___) => const _Placeholder(),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: isActive
                                ? AColors.primaryLight.withOpacity(0.8)
                                : Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    _AnimatedEqualizer(isPlaying: isPlaying)
                  else
                    Text(
                      song.durationLabel,
                      style: GoogleFonts.outfit(
                        color: Colors.white24,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  
                  const SizedBox(width: 8),
                  
                  // More Button
                  _MoreButton(song: song),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final SongModel song;
  const _MoreButton({required this.song});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useRootNavigator: true,
            backgroundColor: Colors.transparent,
            builder: (_) => SongOptionsSheet(song: song),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.more_vert_rounded, color: Colors.white38, size: 20),
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
      color: Colors.white.withOpacity(0.05),
      child: const Icon(Icons.music_note_rounded, color: Colors.white24),
    );
  }
}

class _AnimatedEqualizer extends StatelessWidget {
  final bool isPlaying;
  const _AnimatedEqualizer({required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: 3,
          height: 12,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: AColors.primaryLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scaleY(
           begin: 0.3,
           end: 1.0,
           duration: Duration(milliseconds: 400 + (index * 150)),
           curve: Curves.easeInOut,
         );
      }),
    );
  }
}
