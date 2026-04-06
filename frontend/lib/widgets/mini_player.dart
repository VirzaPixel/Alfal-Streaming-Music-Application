import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../providers/player_provider.dart';
import '../screens/player/now_playing_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    if (!player.hasSong) return const SizedBox.shrink();

    final song = player.currentSong!;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          opaque: true,
          transitionDuration: const Duration(milliseconds: 550),
          reverseTransitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, a, __) => const NowPlayingScreen(),
          transitionsBuilder: (_, a, sa, child) {
            return FadeTransition(
              opacity: a,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                  CurvedAnimation(parent: a, curve: Curves.easeOutQuart),
                ),
                child: child,
              ),
            );
          },
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        height: 76,
        decoration: BoxDecoration(
          color: AColors.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Stack(
              children: [
                // Glowing Progress Background
                _MiniProgressGlow(player: player),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      _AnimatedAlbumArt(
                          songId: song.id,
                          coverUrl: song.coverUrl,
                          isPlaying: player.isPlaying),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Hero(
                              tag: 'song_title_${song.id}',
                              child: Text(
                                song.title,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Hero(
                              tag: 'song_artist_${song.id}',
                              child: Text(
                                song.artist,
                                style: GoogleFonts.outfit(
                                  color: AColors.textSec,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _Controls(player: player, ref: ref),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().slideY(
          begin: 1.0, end: 0, duration: 600.ms, curve: Curves.easeOutQuart),
    );
  }
}

class _AnimatedAlbumArt extends StatelessWidget {
  final int songId;
  final String coverUrl;
  final bool isPlaying;
  const _AnimatedAlbumArt(
      {required this.songId, required this.coverUrl, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Hero(
          tag: 'song_art_$songId',
          child: CachedNetworkImage(
            imageUrl: coverUrl,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
                color: AColors.surfaceAlt,
                child: const Icon(Icons.music_note, color: AColors.textHint)),
          ),
        ),
      ),
    )
        .animate(
            target: isPlaying ? 1 : 0, onPlay: (c) => c.repeat(reverse: true))
        .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 1200.ms);
  }
}

class _MiniProgressGlow extends StatelessWidget {
  final PlayerState player;
  const _MiniProgressGlow({required this.player});

  @override
  Widget build(BuildContext context) {
    final progress = player.duration.inMilliseconds > 0
        ? (player.position.inMilliseconds / player.duration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 3,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05)),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress,
          child: Container(
            decoration: BoxDecoration(
              gradient: AColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                    color: AColors.primary.withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final PlayerState player;
  final WidgetRef ref;
  const _Controls({required this.player, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => ref.read(playerProvider.notifier).previous(),
          icon: const Icon(Icons.skip_previous_rounded),
          color: Colors.white70,
          iconSize: 28,
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => ref.read(playerProvider.notifier).togglePlayPause(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 2),
              ],
            ),
            child: Icon(
              player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.black,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => ref.read(playerProvider.notifier).next(),
          icon: const Icon(Icons.skip_next_rounded),
          color: Colors.white70,
          iconSize: 28,
        ),
      ],
    );
  }
}
