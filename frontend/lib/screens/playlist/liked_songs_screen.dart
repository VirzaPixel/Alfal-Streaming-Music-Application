import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../models/song_model.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/song_options_sheet.dart';
import '../../widgets/song_tile.dart';

class LikedSongsScreen extends ConsumerWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedAsync = ref.watch(likedSongsProvider);
    final player = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: AColors.bg,
      body: Stack(
        children: [
          likedAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AColors.primary),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.cloud_off_rounded,
                      color: AColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text('Failed to load liked songs',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(e.toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: AColors.textSec)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(likedSongsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (songs) {
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Premium Dynamic Header ──
                  SliverAppBar(
                    expandedHeight: 320,
                    pinned: true,
                    stretch: true,
                    backgroundColor: AColors.bg,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Dynamic Mesh Background
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF4F46E5), Color(0xFF9333EA), Color(0xFFDB2777)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          // Subtle Noise/Texture Overlay
                          Opacity(
                            opacity: 0.1,
                            child: Container(color: Colors.black.withOpacity(0.2)),
                          ),
                          // Bottom Fade to BG
                          Positioned(
                            bottom: -1, left: 0, right: 0,
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [AColors.bg, AColors.bg.withOpacity(0)],
                                ),
                              ),
                            ),
                          ),
                          // Content Info
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 40),
                                // Pulsing Heart Icon
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.redAccent.withOpacity(0.3),
                                        blurRadius: 40,
                                        spreadRadius: 10,
                                      )
                                    ],
                                  ),
                                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 56),
                                ).animate(onPlay: (c) => c.repeat(reverse: true))
                                 .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds, curve: Curves.easeInOut),
                                
                                const SizedBox(height: 24),
                                Text('Liked Songs', style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Text('${songs.length} Tracks', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 800.ms),
                    ),
                  ),

                  // ── Premium Action Bar ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildPlayAllButton(context, ref, songs, player),
                          ),
                          const SizedBox(width: 16),
                          _buildShuffleButton(ref, songs),
                        ],
                      ),
                    ),
                  ),

                  // ── Songs List ──
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 150),
                    sliver: songs.isEmpty
                        ? SliverToBoxAdapter(child: _EmptyLikedState())
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => SongTile(
                                song: songs[i],
                                queue: songs,
                                sourceName: 'Liked Songs',
                                onMoreTap: () => _showSongOptions(context, songs[i]),
                              ).animate().fadeIn(delay: (i * 30).ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                              childCount: songs.length,
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayAllButton(BuildContext context, WidgetRef ref, List<SongModel> songs, PlayerState player) {
    final isThisPlaying = player.sourceName == 'Liked Songs';
    
    return GestureDetector(
      onTap: () {
        if (songs.isEmpty) return;
        HapticFeedback.heavyImpact();
        if (isThisPlaying && player.hasSong) {
          ref.read(playerProvider.notifier).togglePlayPause();
        } else {
          ref.read(playerProvider.notifier).playSong(
            songs.first,
            queue: songs,
            sourceName: 'Liked Songs',
          );
        }
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isThisPlaying ? Colors.white.withOpacity(0.1) : null,
          gradient: isThisPlaying ? null : AColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: isThisPlaying ? [] : [
            BoxShadow(
              color: AColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isThisPlaying && player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              isThisPlaying ? (player.isPlaying ? 'PAUSE' : 'RESUME') : 'PLAY ALL',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShuffleButton(WidgetRef ref, List<SongModel> songs) {
    final player = ref.watch(playerProvider);
    return GestureDetector(
      onTap: () {
        if (songs.isEmpty) return;
        final isThisPlaying = player.sourceName == 'Liked Songs';

        if (isThisPlaying && player.hasSong) {
          HapticFeedback.selectionClick();
          ref.read(playerProvider.notifier).toggleShuffle();
        } else {
          HapticFeedback.heavyImpact();
          final mutable = List<SongModel>.from(songs)..shuffle();
          ref.read(playerProvider.notifier).setShuffle(true);
          ref.read(playerProvider.notifier).playSong(
            mutable.first,
            queue: mutable,
            sourceName: 'Liked Songs',
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: player.shuffle 
              ? AColors.primary.withOpacity(0.2) 
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: player.shuffle 
                  ? AColors.primary.withOpacity(0.5) 
                  : Colors.white.withOpacity(0.1)),
        ),
        child: Icon(Icons.shuffle_rounded, 
            color: player.shuffle ? AColors.primary : Colors.white, 
            size: 24),
      ),
    );
  }

  void _showSongOptions(BuildContext context, SongModel song) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SongOptionsSheet(song: song),
    );
  }
}

class _EmptyLikedState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            const Icon(Icons.favorite_border_rounded,
                color: Colors.white10, size: 80),
            const SizedBox(height: 24),
            Text('No Liked Songs',
                style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text('Heart your favorite tracks to see them here.',
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.outfit(fontSize: 14, color: AColors.textSec)),
          ],
        ),
      ),
    );
  }
}

