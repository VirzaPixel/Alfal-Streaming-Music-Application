import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../models/song_model.dart';
import '../../providers/player_provider.dart';
import '../../widgets/song_options_sheet.dart';
import '../../widgets/song_tile.dart';

class AllSongsScreen extends ConsumerStatefulWidget {
  const AllSongsScreen({super.key});

  @override
  ConsumerState<AllSongsScreen> createState() => _AllSongsScreenState();
}

class _AllSongsScreenState extends ConsumerState<AllSongsScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songsProvider);

    return Scaffold(
      backgroundColor: AColors.bg,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  pinned: true,
                  backgroundColor: AColors.bg,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'All Songs A-Z',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                    centerTitle: false,
                    titlePadding: const EdgeInsets.only(left: 64, bottom: 16),
                  ),
                ),
                songsAsync.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AColors.primary)),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    child: Center(child: Text(e.toString(), style: const TextStyle(color: Colors.white54))),
                  ),
                  data: (songs) {
                    final sortedSongs = List<SongModel>.from(songs);
                    sortedSongs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

                    final pages = <List<SongModel>>[];
                    for (var i = 0; i < sortedSongs.length; i += 20) {
                      pages.add(sortedSongs.sublist(i, i + 20 > sortedSongs.length ? sortedSongs.length : i + 20));
                    }

                    if (pages.isEmpty) {
                      return const SliverFillRemaining(child: Center(child: Text("No songs available")));
                    }

                    return SliverFillRemaining(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemCount: pages.length,
                        itemBuilder: (context, pageIndex) {
                          final currentSongs = pages[pageIndex];
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                            physics: const BouncingScrollPhysics(),
                            itemCount: currentSongs.length,
                            itemBuilder: (context, index) {
                              return SongTile(
                                song: currentSongs[index],
                                queue: sortedSongs,
                                sourceName: 'All Songs',
                                onMoreTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    isScrollControlled: true,
                                    builder: (_) => SongOptionsSheet(song: currentSongs[index]),
                                  );
                                },
                              ).animate().fadeIn(delay: (index * 30).ms).slideX(begin: 0.1, end: 0);
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Dedicated Footer for Pagination
          Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 90), // Optimized for Miniplayer
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 1.0],
                colors: [
                  Colors.transparent,
                  AColors.bg.withValues(alpha: 0.8),
                  AColors.bg,
                ],
              ),
            ),
            child: songsAsync.maybeWhen(
              data: (songs) {
                final totalPages = (songs.length / 20).ceil();
                if (totalPages <= 1) return const SizedBox.shrink();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PageButton(
                          icon: Icons.chevron_left_rounded,
                          isActive: _currentPage > 0,
                          onTap: () => _pageController.previousPage(
                            duration: 700.ms,
                            curve: Curves.easeOutQuart,
                          ),
                        ),
                        const SizedBox(width: 32),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_currentPage + 1}',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'OF $totalPages',
                              style: GoogleFonts.outfit(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 32),
                        _PageButton(
                          icon: Icons.chevron_right_rounded,
                          isActive: _currentPage < totalPages - 1,
                          onTap: () => _pageController.nextPage(
                            duration: 700.ms,
                            curve: Curves.easeOutQuart,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 800.ms),
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _PageButton({required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: AnimatedContainer(
        duration: 300.ms,
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? AColors.surfaceAlt : AColors.surfaceAlt.withValues(alpha: 0.3),
          border: Border.all(
            color: isActive ? AColors.primary.withValues(alpha: 0.5) : Colors.white10,
            width: 1.5,
          ),
          boxShadow: isActive ? [BoxShadow(color: AColors.primary.withValues(alpha: 0.2), blurRadius: 15)] : [],
        ),
        child: Icon(icon, color: isActive ? Colors.white : Colors.white12, size: 32),
      ),
    );
  }
}

