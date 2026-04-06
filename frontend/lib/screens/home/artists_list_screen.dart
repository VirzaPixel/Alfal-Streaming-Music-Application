import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/player_provider.dart';
import 'artist_detail_screen.dart';

class ArtistsListScreen extends ConsumerStatefulWidget {
  const ArtistsListScreen({super.key});

  @override
  ConsumerState<ArtistsListScreen> createState() => _ArtistsListScreenState();
}

class _ArtistsListScreenState extends ConsumerState<ArtistsListScreen> {
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
    final artistsAsync = ref.watch(artistsProvider);

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
                      'Artists',
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
                artistsAsync.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AColors.primary)),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    child: Center(child: Text(e.toString(), style: const TextStyle(color: Colors.white54))),
                  ),
                  data: (artistMap) {
                    final artists = artistMap.keys.toList()..sort();
                    final pages = <List<String>>[];
                    for (var i = 0; i < artists.length; i += 10) {
                      pages.add(artists.sublist(i, i + 10 > artists.length ? artists.length : i + 10));
                    }

                    if (pages.isEmpty) {
                      return const SliverFillRemaining(child: Center(child: Text("No artists available")));
                    }

                    return SliverFillRemaining(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemCount: pages.length,
                        itemBuilder: (context, pageIndex) {
                          final currentArtists = pages[pageIndex];
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                            physics: const BouncingScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 24,
                              crossAxisSpacing: 20,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: currentArtists.length,
                            itemBuilder: (context, index) {
                              final name = currentArtists[index];
                              return _ArtistGridItem(
                                name: name,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ArtistDetailScreen(
                                      artistName: name,
                                      songs: artistMap[name]!,
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: (index * 50).ms).scale(begin: const Offset(0.9, 0.9));
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
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 90), // Optimized for Miniplayer (around 80px)
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
            child: artistsAsync.maybeWhen(
              data: (artistMap) {
                final totalPages = (artistMap.keys.length / 10).ceil();
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

  const _PageButton(
      {required this.icon, required this.isActive, required this.onTap});

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
          boxShadow: isActive
              ? [BoxShadow(color: AColors.primary.withValues(alpha: 0.2), blurRadius: 15)]
              : [],
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white12,
          size: 32,
        ),
      ),
    );
  }
}

class _ArtistGridItem extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _ArtistGridItem({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AColors.surfaceAlt,
                    AColors.primary.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child:
                    Icon(Icons.person_rounded, color: Colors.white24, size: 50),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

