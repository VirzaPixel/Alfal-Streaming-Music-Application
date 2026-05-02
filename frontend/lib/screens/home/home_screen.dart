import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';

import '../playlist/liked_songs_screen.dart';
import '../playlist/playlist_detail_screen.dart';
import '../../widgets/top_navbar.dart';
import '../../widgets/glass_container.dart';
import '../../models/user_model.dart';
import '../../widgets/song_options_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider.select((s) => s.user));
    final playlistsAsync = ref.watch(playlistsProvider);
    final currentSong = ref.watch(playerProvider.select((s) => s.currentSong));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TopNavbar(),
            Expanded(
              child: _buildUserDashboard(context, ref, user, playlistsAsync, currentSong),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDashboard(
    BuildContext context,
    WidgetRef ref,
    UserModel? user,
    AsyncValue<List<dynamic>> playlistsAsync,
    dynamic currentSong,
  ) {
    final suggestedAsync = ref.watch(suggestedSongsProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Personalized Greeting ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 24, 24),
            child: Row(
              children: [
                Hero(
                  tag: 'home_avatar',
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5), width: 2),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.3), blurRadius: 20),
                      ],
                    ),
                    child: ClipOval(
                      child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: user.avatarUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: const Color(0xFF00E5FF).withOpacity(0.1),
                              child: const Icon(Icons.person_rounded, color: Color(0xFF00E5FF)),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Listen your way to happiness.',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withOpacity(0.95),
                          letterSpacing: -0.8,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Quick Access Grid ──
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.8,
            ),
            delegate: SliverChildListDelegate([
              _QuickAccessTile(
                label: 'Liked Songs',
                icon: Icons.favorite_rounded,
                color: Colors.redAccent,
                onTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    opaque: false,
                    barrierColor: Colors.black.withOpacity(0.3),
                    pageBuilder: (_, __, ___) => const LikedSongsScreen(),
                    transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
                  ),
                ),
              ),
              // Get first 3 playlists
              ...playlistsAsync.maybeWhen(
                data: (list) => list.take(3).map((p) => _QuickAccessTile(
                      label: p.name,
                      image: p.coverUrl,
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          opaque: false,
                          barrierColor: Colors.black.withOpacity(0.3),
                          pageBuilder: (_, __, ___) => PlaylistDetailScreen(playlistId: p.id),
                          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
                        ),
                      ),
                    )),
                orElse: () => [],
              )
            ]),
          ),
        ),

        // ── Suggested For You ──
        SliverToBoxAdapter(
          child: _HomeSection(
            title: 'Random Songs Everyminutes',
            onSeeAll: null,
            child: suggestedAsync.when(
              loading: () => const _HorizontalLoading(),
              error: (_, __) => const SizedBox.shrink(),
              data: (songs) => SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: songs.length > 10 ? 10 : songs.length,
                  itemBuilder: (_, i) => _SuggestedSongCard(song: songs[i]),
                ),
              ),
            ),
          ),
        ),

        // ── Your Playlists ──
        SliverToBoxAdapter(
          child: _HomeSection(
            title: 'Your Playlists',
            onSeeAll: null,
            child: playlistsAsync.when(
              data: (playlists) {
                if (playlists.isEmpty) return _EmptyPlaylists();
                final displayPlaylists = playlists.take(5).toList();
                return SizedBox(
                  height: 230,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: displayPlaylists.length + 1,
                    itemBuilder: (context, i) {
                      if (i == displayPlaylists.length) {
                        return const _ExplorePlaylistCard();
                      }
                      return _PlaylistCard(playlist: displayPlaylists[i]);
                    },
                  ),
                );
              },
              loading: () => const _HorizontalLoading(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 240)),
      ],
    );
  }
}

class _HomeSection extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onSeeAll;
  const _HomeSection({required this.title, required this.child, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: Text('All',
                      style: GoogleFonts.outfit(
                          color: Colors.white24,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? image;
  final Color? color;
  final VoidCallback onTap;

  const _QuickAccessTile({
    required this.label,
    this.icon,
    this.image,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          if (color != null)
            BoxShadow(
              color: color!.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color?.withOpacity(0.1) ?? Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: image!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.white.withOpacity(0.05),
                            highlightColor: Colors.white.withOpacity(0.1),
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            icon ?? Icons.music_note_rounded,
                            color: color ?? Colors.white24,
                            size: 20,
                          ),
                        ),
                      )
                    : Icon(icon ?? Icons.music_note_rounded,
                        color: color ?? Colors.white24, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }
}

class _SuggestedSongCard extends ConsumerWidget {
  final dynamic song;
  const _SuggestedSongCard({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(playerProvider.notifier).playSong(song, sourceName: 'Suggested For You');
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CachedNetworkImage(
                      imageUrl: song.coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.white.withOpacity(0.05),
                        highlightColor: Colors.white.withOpacity(0.1),
                        child: Container(
                          color: Colors.white,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.03),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.music_note_rounded,
                            color: Colors.white.withOpacity(0.15),
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0, right: 0,
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      showModalBottomSheet(
                        context: context,
                        useRootNavigator: true,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => SongOptionsSheet(song: song),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalLoading extends StatelessWidget {
  const _HorizontalLoading();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: 5,
        itemBuilder: (_, i) => Container(
          width: 140,
          margin: const EdgeInsets.only(right: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.white.withOpacity(0.05),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Shimmer.fromColors(
                baseColor: Colors.white.withOpacity(0.05),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Container(
                  height: 14,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Shimmer.fromColors(
                baseColor: Colors.white.withOpacity(0.05),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Container(
                  height: 11,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final dynamic playlist;
  const _PlaylistCard({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaylistDetailScreen(playlistId: playlist.id),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'home_playlist_cover_${playlist.id}',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: playlist.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: playlist.coverUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.white.withOpacity(0.05),
                              highlightColor: Colors.white.withOpacity(0.1),
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.1),
                                    Colors.white.withOpacity(0.03),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.playlist_play_rounded,
                                  color: Colors.white.withOpacity(0.15),
                                  size: 48,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.1),
                                    Colors.white.withOpacity(0.03),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.playlist_play_rounded,
                                  color: Colors.white.withOpacity(0.15),
                                  size: 48,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                playlist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                '${playlist.songs?.length ?? 0} songs',
                style: GoogleFonts.outfit(
                    color: Colors.white24,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }
  }

  class _ExplorePlaylistCard extends StatelessWidget {
    const _ExplorePlaylistCard();

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Explore Playlists coming soon!')),
          );
        },
        child: Container(
          width: 160,
          margin: const EdgeInsets.only(right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withOpacity(0.1),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withOpacity(0.05),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.explore_rounded,
                          color: Color(0xFF00E5FF),
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Explore More',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: const Color(0xFF00E5FF),
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Discover new sounds',
                style: GoogleFonts.outfit(
                    color: Colors.white24,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }
  }
  
  class _EmptyPlaylists extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return AGlass(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(32),
        borderRadius: BorderRadius.circular(32),
        opacity: 0.05,
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                child: Icon(Icons.auto_awesome_mosaic_rounded, color: Colors.white.withOpacity(0.3), size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                'No playlists yet',
                style: GoogleFonts.outfit(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }
  }
