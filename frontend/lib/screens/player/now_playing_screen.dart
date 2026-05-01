import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/player_provider.dart' hide RepeatMode;
import '../../providers/player_provider.dart' as pp show RepeatMode;
import '../../providers/playlist_provider.dart';
import '../../widgets/song_options_sheet.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  double _volume = 0.8;

  @override
  void initState() {
    super.initState();
  }



  String _fmtDur(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final song = player.currentSong;



    // If song is null (playlist finished), pop the screen back to previous page
    if (song == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      return const Scaffold(backgroundColor: Colors.transparent);
    }

    final total = player.duration.inMilliseconds;
    final pos = player.position.inMilliseconds;
    final sliderVal = total > 0 ? (pos / total).clamp(0.0, 1.0) : 0.0;
    
    final liked = ref.watch(isLikedProvider(song.id));

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! > 10) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AColors.bg,
        body: Stack(
        children: [
          // Fast and sleek background gradient instead of heavy dynamic blur mesh
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AColors.primary.withOpacity(0.2),
                    Colors.black,
                    AColors.bg,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0), // Increased top padding to move header down
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.expand_more_rounded,
                            size: 36, color: Colors.white),
                      ),
                      Column(
                        children: [
                          Text(
                              player.sourceName != null
                                  ? 'PLAYING FROM'
                                  : 'NOW PLAYING',
                              style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white54,
                                  letterSpacing: 2.5)),
                          Text(player.sourceName ?? 'Music Library',
                              style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            useRootNavigator: true,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => SongOptionsSheet(song: song),
                          );
                        },
                        icon: const Icon(Icons.more_horiz_rounded, size: 32, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Column(
                    key: const ValueKey('art'),
                    children: [
                      const Spacer(),
                      _ModernArt(
                        songId: song.id,
                        coverUrl: song.coverUrl,
                        isPlaying: player.isPlaying,
                      ),
                      const Spacer(),
                      _InfoBlock(song: song),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Controls and Progress
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(50)),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      // Progress
                      Row(
                        children: [
                          Text(_fmtDur(player.position),
                              style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12),
                                activeTrackColor: AColors.primary,
                                inactiveTrackColor: Colors.white10,
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                value: sliderVal,
                                onChanged: (v) {
                                  if (total > 0) {
                                    notifier.seekTo(Duration(
                                        milliseconds: (v * total).round()));
                                  }
                                },
                              ),
                            ),
                          ),
                          Text(_fmtDur(player.duration),
                              style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Main Playback controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: liked ? Colors.redAccent : Colors.white54,
                              size: 28,
                            ),
                            onPressed: () async {
                              HapticFeedback.mediumImpact();
                              if (liked) {
                                await ref.read(playlistServiceProvider).unlikeSong(song.id);
                              } else {
                                await ref.read(playlistServiceProvider).likeSong(song.id);
                              }
                              ref.invalidate(likedSongsProvider);
                              ref.invalidate(profileStatsProvider);
                            },
                          ),
                          IconButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              notifier.previous();
                            },
                            icon: const Icon(Icons.skip_previous_rounded,
                                size: 48, color: Colors.white),
                          ),
                          _BigPlayBtn(
                              isPlaying: player.isPlaying,
                              onTap: () {
                                HapticFeedback.heavyImpact();
                                notifier.togglePlayPause();
                              }),
                          IconButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              notifier.next();
                            },
                            icon: const Icon(Icons.skip_next_rounded,
                                size: 48, color: Colors.white),
                          ),
                          _SmallBtn(
                              icon: player.repeatMode == pp.RepeatMode.one
                                  ? Icons.repeat_one_rounded
                                  : Icons.repeat_rounded,
                              active: player.repeatMode != pp.RepeatMode.off,
                              onTap: notifier.toggleRepeat),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Volume
                      Row(
                        children: [
                          const Icon(Icons.volume_down_rounded,
                              color: Colors.white38, size: 20),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 4)),
                              child: Slider(
                                  value: _volume,
                                  activeColor: Colors.white30,
                                  inactiveColor: Colors.white10,
                                  onChanged: (v) {
                                    setState(() => _volume = v);
                                    notifier.setVolume(v);
                                  }),
                            ),
                          ),
                          const Icon(Icons.volume_up_rounded,
                              color: Colors.white38, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}

class _ModernArt extends StatelessWidget {
  final int songId;
  final String coverUrl;
  final bool isPlaying;
  const _ModernArt({
    required this.songId,
    required this.coverUrl,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Hero(
        tag: 'song_art_$songId',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: CachedNetworkImage(
            imageUrl: coverUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: Colors.white10,
              child: const Icon(Icons.music_note_rounded,
                  color: Colors.white24, size: 64),
            ),
            errorWidget: (_, __, ___) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.music_note_rounded,
                  color: Colors.white.withOpacity(0.15),
                  size: 140,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBlock extends ConsumerWidget {
  final dynamic song;
  const _InfoBlock({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(isLikedProvider(song.id));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  type: MaterialType.transparency,
                  child: Text(
                    song.title,
                    style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                Material(
                  type: MaterialType.transparency,
                  child: Text(
                    song.artist.toUpperCase(),
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white54,
                        letterSpacing: 2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BigPlayBtn extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  const _BigPlayBtn({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        height: 84,
        decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.white24, blurRadius: 30, spreadRadius: 5)
            ]),
        child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.black, size: 48),
      ),
    )
        .animate(target: isPlaying ? 1 : 0)
        .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05));
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _SmallBtn(
      {required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon,
          color: active ? AColors.primary : Colors.white38, size: 28),
    );
  }
}
