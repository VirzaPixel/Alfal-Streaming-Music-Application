import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../models/song_model.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/mini_player.dart';
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
                  // ── Premium Gradient Header ──
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: true,
                    stretch: true,
                    backgroundColor: AColors.bg,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white),
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
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    AColors.bg,
                                    AColors.bg.withValues(alpha: 0)
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: const Icon(Icons.favorite_rounded,
                                      color: Colors.white, size: 48),
                                ).animate().scale(curve: Curves.easeOutBack),
                                const SizedBox(height: 16),
                                Text('Liked Songs',
                                    style: GoogleFonts.outfit(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -1)),
                                Text(
                                    '${songs.length} tracks in your collection',
                                    style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Main Shuffle Action ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (songs.isNotEmpty) {
                                  HapticFeedback.heavyImpact();
                                  final isThisPlaying =
                                      player.sourceName == 'Liked Songs';

                                  if (isThisPlaying && player.hasSong) {
                                    ref
                                        .read(playerProvider.notifier)
                                        .togglePlayPause();
                                  } else {
                                    ref.read(playerProvider.notifier).playSong(
                                          songs.first,
                                          queue: songs,
                                          sourceName: 'Liked Songs',
                                        );
                                  }
                                }
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  color: player.sourceName == 'Liked Songs'
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : null,
                                  gradient: player.sourceName == 'Liked Songs'
                                      ? null
                                      : AColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(20),
                                  border: player.sourceName == 'Liked Songs'
                                      ? Border.all(
                                          color: Colors.white.withValues(alpha: 0.2))
                                      : null,
                                  boxShadow: player.sourceName == 'Liked Songs'
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: AColors.primary
                                                .withValues(alpha: 0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          )
                                        ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      player.sourceName == 'Liked Songs' &&
                                              player.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      player.sourceName == 'Liked Songs'
                                          ? (player.isPlaying
                                              ? 'PAUSE'
                                              : 'RESUME')
                                          : 'PLAY ALL',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Shuffle button
                          GestureDetector(
                            onTap: () {
                              if (songs.isNotEmpty) {
                                HapticFeedback.heavyImpact();
                                final mutable = List<SongModel>.from(songs)
                                  ..shuffle();
                                ref.read(playerProvider.notifier).playSong(
                                      mutable.first,
                                      queue: mutable,
                                      sourceName: 'Liked Songs',
                                    );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: const Icon(Icons.shuffle_rounded,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Songs List ──
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
                    sliver: songs.isEmpty
                        ? SliverToBoxAdapter(child: _EmptyLikedState())
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => SongTile(
                                song: songs[i],
                                queue: songs,
                                sourceName: 'Liked Songs',
                                onMoreTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    useRootNavigator: true,
                                    backgroundColor: Colors.transparent,
                                    isScrollControlled: true,
                                    builder: (_) =>
                                        SongOptionsSheet(song: songs[i]),
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

