import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../models/song_model.dart';
import '../../providers/player_provider.dart';
import '../../widgets/song_options_sheet.dart';
import '../../widgets/song_tile.dart';

class ArtistDetailScreen extends ConsumerWidget {
  final String artistName;
  final List<SongModel> songs;

  const ArtistDetailScreen({
    super.key,
    required this.artistName,
    required this.songs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final isArtistPlaying = player.sourceName == 'Artist: $artistName';

    return Scaffold(
      backgroundColor: AColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            stretch: true,
            backgroundColor: AColors.bg,
            elevation: 0,
            leading: IconButton(
              icon:
                  const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                artistName,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  color: Colors.white,
                  shadows: [
                    const Shadow(color: Colors.black54, blurRadius: 10),
                  ],
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 64, bottom: 16),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AColors.primary.withValues(alpha: 0.8),
                          AColors.surfaceAlt,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      Icons.person_rounded,
                      size: 200,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (songs.isNotEmpty) {
                        HapticFeedback.heavyImpact();
                        if (isArtistPlaying && player.hasSong) {
                          ref.read(playerProvider.notifier).togglePlayPause();
                        } else {
                          ref.read(playerProvider.notifier).playSong(
                                songs.first,
                                queue: songs,
                                sourceName: 'Artist: $artistName',
                              );
                        }
                      }
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AColors.premiumGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AColors.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Icon(
                        isArtistPlaying && player.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PLAY ALL',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${songs.length} Tracks',
                        style: GoogleFonts.outfit(
                          color: AColors.textSec,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return SongTile(
                    song: songs[index],
                    queue: songs,
                    sourceName: 'Artist: $artistName',
                    onMoreTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => SongOptionsSheet(song: songs[index]),
                      );
                    },
                  )
                      .animate()
                      .fadeIn(delay: (index * 50).ms)
                      .slideY(begin: 0.1, end: 0);
                },
                childCount: songs.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

