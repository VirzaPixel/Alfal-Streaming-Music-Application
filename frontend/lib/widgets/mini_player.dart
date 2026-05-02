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
    // Optimization: Only watch what's necessary to avoid rebuilds on every second position change
    final hasSong = ref.watch(playerProvider.select((p) => p.hasSong));
    if (!hasSong) return const SizedBox.shrink();

    final song = ref.watch(playerProvider.select((p) => p.currentSong!));
    final isPlaying = ref.watch(playerProvider.select((p) => p.isPlaying));

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black.withOpacity(0.5),
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => const NowPlayingScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return SlideTransition(
              position: animation.drive(Tween(begin: const Offset(0, 1), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))),
              child: child,
            );
          },
        ),
      ),
      child: RepaintBoundary(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0F).withOpacity(0.65),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.2),
                blurRadius: 25,
                spreadRadius: -5,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Stack(
                children: [
                  // Glowing Progress Background (Watched separately to minimize parent rebuild)
                  const _MiniProgressGlow(),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        _AnimatedAlbumArt(
                            songId: song.id,
                            coverUrl: song.coverUrl,
                            isPlaying: isPlaying),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                song.title,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song.artist,
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const _MiniPlayButton(),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }
}

class _MiniProgressGlow extends ConsumerWidget {
  const _MiniProgressGlow();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playerProvider.select((p) => p.position));
    final duration = ref.watch(playerProvider.select((p) => p.duration));
    final double progress = duration.inMilliseconds > 0 ? position.inMilliseconds / duration.inMilliseconds : 0.0;

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00E5FF).withOpacity(0.0),
                      const Color(0xFF00E5FF).withOpacity(0.12),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniPlayButton extends ConsumerWidget {
  const _MiniPlayButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(playerProvider.select((p) => p.isPlaying));
    return IconButton(
      onPressed: () => ref.read(playerProvider.notifier).togglePlayPause(),
      icon: Icon(
        isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
        color: Colors.white,
        size: 38,
      ),
    );
  }
}

class _AnimatedAlbumArt extends StatelessWidget {
  final int songId;
  final String coverUrl;
  final bool isPlaying;

  const _AnimatedAlbumArt({
    required this.songId,
    required this.coverUrl,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'song_art_$songId',
      child: RepaintBoundary(
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: coverUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: AColors.surfaceAlt),
              errorWidget: (context, url, error) => const Icon(Icons.music_note_rounded),
            ),
          ),
        ).animate(
          target: isPlaying ? 1 : 0,
          onPlay: (controller) => controller.repeat(),
        ).shimmer(
          duration: 2000.ms,
          color: Colors.white.withOpacity(0.1),
        ),
      ),
    );
  }
}
